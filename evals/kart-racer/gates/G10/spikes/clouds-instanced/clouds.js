// Spike M10-T03 option (a), throwaway evidence code: Lantern Reach's clouds as TWO InstancedMesh
// puff layers (one draw call each) plus ONE merged BufferGeometry cloud sea (one draw call). Pure
// `cloudPlan` in the scenery-plan style; nothing for Ember; no Math.random at render time.
//
// Spike-only switch: `globalThis.__spikeSea` is 'webgl' by default (production behaviour: the sea is
// the merged WebGL mesh), 'backdrop' (the sea leaves WebGL and sky.js paints below the horizon) or
// 'noclouds' (measurement only: no cloud group at all). Delete this switch with the spike.
import * as THREE from 'three';
import { pointAt } from '../logic/track.js';
import { heightAt } from './elevation.js';
import { SUN_DIRECTION } from './sky.js';

// palette (docs/m10/REFERENCE.md §3): lit top / warm side, and shadow side / far clouds
export const CLOUD_LIT = 0xf6b38a;
export const CLOUD_SHADOW = 0x6b5a8e;
export const SEA_TOP = -24; // ~25 m under the lowest road point (road visual height 1..6.5 m)
export const SEA_CENTRE = [95, -115]; // world x, z; road footprint is x -100..290, z -230..0
export const SEA_RADIUS = 330; // road corners are <= 226 m from the centre, plus the >= 100 m margin
export const PUFFS_PER_LAYER = 15;
const TAU = 2 * Math.PI;
const SEA_LAYERS = 3;

const smoothstep = (t) => {
  const x = Math.min(1, Math.max(0, t));
  return x * x * (3 - 2 * x);
};

// The same seeded LCG style as sky.js's star seed: fixed clouds every run.
function lcg(seed) {
  return () => ((seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0) + 0.5) / 4294967296;
}

// Horizontal sun bearing; world +x is the sun side, so the flat sun is (1, 0) up to rounding.
const SUN_FLAT = (() => {
  const length = Math.hypot(SUN_DIRECTION[0], SUN_DIRECTION[2]) || 1;
  return [SUN_DIRECTION[0] / length, SUN_DIRECTION[2] / length];
})();

// The two puff layers and the sea plan. Pure: same track, same clouds. Ember plans nothing.
export function cloudPlan(track) {
  if (track.id !== 'lantern') return null;
  const random = lcg(0x0c10d5);
  const range = (lo, hi) => lo + random() * (hi - lo);
  const at = (s, lateral) => {
    const p = pointAt(track, s, lateral);
    return [p.x, heightAt(track, s), -p.y]; // logic {x, y} -> world (x, height, -y)
  };
  // Outward horizontal unit vector at s, in world xz: the perpendicular that moves away from the
  // sea centre. The loop's outside lies that way on every piece, so a puff keeps clear of the road.
  const outward = (s) => {
    const a = pointAt(track, s, 0);
    const b = pointAt(track, s + 1, 0);
    const dx = b.x - a.x;
    const dz = -(b.y - a.y);
    const length = Math.hypot(dx, dz) || 1;
    const [nx, nz] = [dz / length, -dx / length];
    const away = (x, z) => Math.hypot(x - SEA_CENTRE[0], z - SEA_CENTRE[1]);
    return away(a.x + nx, -a.y + nz) >= away(a.x - nx, -a.y - nz) ? [nx, nz] : [-nx, -nz];
  };
  const puff = (position, scale, drift) => ({
    position,
    scale,
    spin: range(0, TAU),
    phase: range(0, TAU),
    drift,
  });

  const near = [];
  // Under both jump gaps (s 50-60, s 370-380): below the road, so a jump reads "clouds below".
  for (const s of [52, 57, 371, 376]) {
    const [x, y, z] = at(s, 0);
    near.push(puff([x, y - range(3.5, 7), z], range(6, 9), range(4, 7)));
  }
  // The rest alongside the road: 40..140 m out (kerbs are at 6 m), low, y 0..8.
  for (let i = near.length; i < PUFFS_PER_LAYER; i++) {
    const s = range(0, track.length);
    const [x, , z] = at(s, 0);
    const [nx, nz] = outward(s);
    const out = range(40, 140);
    near.push(puff([x + nx * out, range(0, 8), z + nz * out], range(10, 22), range(5, 9)));
  }

  // Far layer near the horizon: 260..420 m out, y 20..70.
  const far = [];
  for (let i = 0; i < PUFFS_PER_LAYER; i++) {
    const s = range(0, track.length);
    const [x, , z] = at(s, 0);
    const [nx, nz] = outward(s);
    const out = range(260, 420);
    far.push(puff([x + nx * out, range(20, 70), z + nz * out], range(18, 40), range(10, 18)));
  }

  return { near, far, sea: { centre: SEA_CENTRE, top: SEA_TOP, radius: SEA_RADIUS, layers: SEA_LAYERS } };
}

// One low-poly sphere, faceted by per-face normals and coloured per vertex from the palette: warm
// where the face's normal faces the sun, shadow tone on the far side. MeshBasicMaterial carries the
// colours directly (three 0.186 has no flatShading on MeshBasicMaterial) and stays unlit.
function puffGeometry() {
  const geometry = new THREE.IcosahedronGeometry(1, 1); // 80 faces, non-indexed
  geometry.computeVertexNormals();
  const normal = geometry.attributes.normal;
  const lit = new THREE.Color(CLOUD_LIT);
  const shadow = new THREE.Color(CLOUD_SHADOW);
  const colors = new Float32Array(normal.count * 3);
  for (let i = 0; i < normal.count; i++) {
    const facing = normal.getX(i) * SUN_DIRECTION[0] + normal.getY(i) * SUN_DIRECTION[1]
      + normal.getZ(i) * SUN_DIRECTION[2];
    const t = smoothstep((facing + 0.2) / 0.8);
    colors[i * 3] = shadow.r + (lit.r - shadow.r) * t;
    colors[i * 3 + 1] = shadow.g + (lit.g - shadow.g) * t;
    colors[i * 3 + 2] = shadow.b + (lit.b - shadow.b) * t;
  }
  geometry.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3));
  return geometry;
}

// The sea: SEA_LAYERS tonal disc layers merged into one BufferGeometry (one draw call). Vertices sit
// on a radial grid so the low-frequency undulation and the per-vertex colour both have interior
// resolution. Deeper layers are dimmer and slightly wider, so the rim reads as bands.
export function seaGeometry({ centre, top, radius, layers }) {
  const SEG = 64;
  const RINGS = 6;
  const positions = [];
  const colors = [];
  const indices = [];
  const lit = new THREE.Color(CLOUD_LIT);
  const shadow = new THREE.Color(CLOUD_SHADOW);
  const tone = new THREE.Color();
  const wave = (x, z) => Math.sin(x * 0.011) * 1.6 + Math.cos(z * 0.014) * 1.5; // a few metres
  for (let layer = 0; layer < layers; layer++) {
    const base = positions.length / 3;
    const y0 = top - layer * 1.6;
    const span = radius * (1 + layer * 0.045);
    const dim = (layer / (layers - 1)) * 0.45;
    for (let ring = 0; ring <= RINGS; ring++) {
      const r = span * (ring / RINGS);
      for (let i = 0; i < SEG; i++) {
        const angle = (i / SEG) * TAU;
        const x = centre[0] + Math.cos(angle) * r;
        const z = centre[1] + Math.sin(angle) * r;
        positions.push(x, y0 + wave(x, z), z);
        const flat = Math.hypot(x - centre[0], z - centre[1]) || 1;
        const facing = ((x - centre[0]) * SUN_FLAT[0] + (z - centre[1]) * SUN_FLAT[1]) / flat;
        tone.copy(shadow).lerp(lit, smoothstep((facing + 0.2) / 0.8)).lerp(shadow, dim);
        colors.push(tone.r, tone.g, tone.b);
      }
    }
    for (let ring = 0; ring < RINGS; ring++) {
      for (let i = 0; i < SEG; i++) {
        const a = base + ring * SEG + i;
        const b = base + ring * SEG + ((i + 1) % SEG);
        const c = a + SEG;
        const d = b + SEG;
        indices.push(a, b, c, b, d, c); // +y facing, so the top is visible from above
      }
    }
  }
  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
  geometry.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3));
  geometry.setIndex(indices);
  return geometry;
}

// The race's cloud group: two puff layers, and the sea unless the spike switch moved it to the
// backdrop. update(seconds) drifts each puff on a slow bounded sine, so the layer bounds stay put.
export function createClouds(track) {
  const mode = globalThis.__spikeSea ?? 'webgl';
  if (mode === 'noclouds') return null;
  const plan = cloudPlan(track);
  if (!plan) return null; // Ember stays bare
  const group = new THREE.Group();
  group.name = 'clouds';

  const geometry = puffGeometry();
  const material = new THREE.MeshBasicMaterial({ vertexColors: true, fog: true });
  const dummy = new THREE.Object3D();
  const layers = [['cloud-near', plan.near], ['cloud-far', plan.far]].map(([name, puffs]) => {
    const mesh = new THREE.InstancedMesh(geometry, material, puffs.length);
    mesh.name = name;
    group.add(mesh);
    return { mesh, puffs };
  });
  if (mode === 'webgl') {
    const sea = new THREE.Mesh(seaGeometry(plan.sea), new THREE.MeshBasicMaterial({ vertexColors: true, fog: true }));
    sea.name = 'cloud-sea';
    group.add(sea);
  }

  function update(seconds) {
    for (const { mesh, puffs } of layers) {
      for (let i = 0; i < puffs.length; i++) {
        const { position, scale, spin, phase, drift } = puffs[i];
        dummy.position.set(
          position[0] + Math.sin(seconds * 0.05 + phase) * drift,
          position[1],
          position[2],
        );
        dummy.rotation.set(0, spin, 0);
        dummy.scale.set(scale, scale * 0.72, scale); // squashed, so a puff reads as cloud not sphere
        dummy.updateMatrix();
        mesh.setMatrixAt(i, dummy.matrix);
      }
      mesh.instanceMatrix.needsUpdate = true;
      mesh.computeBoundingSphere(); // one sphere per layer: three culls the layer as a unit
    }
  }

  update(0);
  return { group, update };
}
