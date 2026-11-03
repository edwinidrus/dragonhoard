// Lantern Reach clouds (M10-T03 spike, option b): billboard planes carrying a soft blob CanvasTexture
// generated in code, plus a merged-geometry cloud sea. The plan is pure and deterministic (seeded
// LCG, same style as sky.js's star seed); no image file is added or fetched. Ember plans nothing.
import * as THREE from 'three';
import { pointAt } from '../logic/track.js';
import { heightAt } from './elevation.js';
import { SUN_DIRECTION, setBackdropSea } from './sky.js';

export const SEA_CENTER = [95, -24, -115]; // world; ~25 m below the lowest road point (road min 1.0 m)
export const SEA_TOP = SEA_CENTER[1];
const WARM = 0xf6b38a; // lit top / sun side (REFERENCE.md section 3)
const COOL = 0x6b5a8e; // shadow side / far clouds

// The two puff layers plus the sea plan, or null for any track that is not Lantern Reach.
export function cloudPlan(track) {
  if (track.id !== 'lantern') return null;
  const L = track.length;
  let seed = 0xc10d5eed;
  const random = () => ((seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0) + 0.5) / 4294967296;
  const puff = (s, lateral, y, scale) => {
    const a = pointAt(track, s, lateral);
    return {
      pos: [a.x, heightAt(track, s) + y, -a.y],
      scale,
      drift: 0.3 + random() * 0.9,
      phase: random() * Math.PI * 2,
    };
  };
  const layer = (count, latMin, latSpan, yMin, ySpan, sizeMin, sizeSpan) => {
    const out = [];
    for (let i = 0; i < count; i++) {
      const s = random() * L;
      const lateral = (random() < 0.5 ? -1 : 1) * (latMin + random() * latSpan);
      out.push(puff(s, lateral, yMin + random() * ySpan, sizeMin + random() * sizeSpan));
    }
    return out;
  };
  // Near layer: low, 40..140 m out, under both jump gaps so a jump reads "with clouds below".
  const near = layer(15, 40, 100, 0, 8, 9, 9);
  for (const s of [55, 375]) for (const side of [-1, 1]) near.push(puff(s + side * 4, side * 34, 1 + random() * 2, 10 + random() * 5));
  // Far layer: near the horizon, 260..420 m out, higher and larger.
  const far = layer(15, 260, 160, 20, 50, 16, 14);
  return { near, far };
}

// A soft blob drawn once: warm core, cool blur, transparent edge. Detached canvas: only the game's
// canvas is ever connected, which the pinned smoke test asserts.
function createBlobTexture() {
  const size = 64;
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = size;
  const ctx = canvas.getContext('2d');
  const g = ctx.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2);
  g.addColorStop(0, 'rgba(246,179,138,0.95)');
  g.addColorStop(0.45, 'rgba(246,179,138,0.7)');
  g.addColorStop(0.72, 'rgba(107,90,142,0.45)');
  g.addColorStop(1, 'rgba(107,90,142,0)');
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, size, size);
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace; // three@0.186.1: colour maps must declare sRGB
  return texture;
}

// 2-3 tonal layers concatenated into ONE BufferGeometry (one draw call). Vertices mix the palette by
// how far the vertex's horizontal direction from the centre faces SUN_DIRECTION: warm on the sun side.
export function seaGeometry(center = SEA_CENTER, sun = SUN_DIRECTION) {
  const [cx, top, cz] = center;
  const warm = new THREE.Color(WARM), cool = new THREE.Color(COOL), c = new THREE.Color();
  const layers = [
    { size: 620, seg: 24, y: top, tone: 0.82 },
    { size: 520, seg: 20, y: top + 1.6, tone: 0.95 },
    { size: 400, seg: 16, y: top + 3.2, tone: 1.06 },
  ];
  const positions = [], colors = [], indices = [];
  for (const { size, seg, y, tone } of layers) {
    const base = positions.length / 3, half = size / 2, step = size / seg;
    for (let iz = 0; iz <= seg; iz++) {
      for (let ix = 0; ix <= seg; ix++) {
        const x = cx - half + ix * step, z = cz - half + iz * step;
        const dx = x - cx, dz = z - cz;
        positions.push(x, y + 2.5 * Math.sin(dx * 0.012) * Math.cos(dz * 0.015), z);
        const len = Math.hypot(dx, dz) || 1;
        const facing = Math.max(0, (dx / len) * sun[0] + (dz / len) * sun[2]);
        c.copy(cool).lerp(warm, 0.15 + 0.85 * facing).multiplyScalar(tone);
        colors.push(c.r, c.g, c.b);
      }
    }
    for (let iz = 0; iz < seg; iz++) {
      for (let ix = 0; ix < seg; ix++) {
        const a = base + iz * (seg + 1) + ix, b = a + 1, d = a + seg + 1, e = d + 1;
        indices.push(a, d, b, b, d, e);
      }
    }
  }
  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
  geometry.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3));
  geometry.setIndex(indices);
  return geometry;
}

// Per-race cloud group. `update(seconds)` drifts the puffs and re-billboards them to this frame's camera.
export function createClouds(track, camera) {
  const group = new THREE.Group();
  group.name = 'clouds';
  const plan = cloudPlan(track);
  if (!plan) return { group, update() {} };

  const backdropSea = typeof location !== 'undefined' && new URLSearchParams(location.search).get('sea') === 'backdrop';
  if (backdropSea) setBackdropSea(true); // authorised alternative: paint the sea in T02's backdrop

  const texture = createBlobTexture();
  const material = new THREE.MeshBasicMaterial({
    map: texture, transparent: true, depthWrite: false, fog: true, side: THREE.DoubleSide,
  });
  // disposeTree disposes materials, not maps: give the generated texture the material's lifetime.
  const baseDispose = material.dispose.bind(material);
  material.dispose = () => { texture.dispose(); baseDispose(); };

  const dummy = new THREE.Object3D();
  const layers = [plan.near, plan.far].map((puffs) => {
    const mesh = new THREE.InstancedMesh(new THREE.PlaneGeometry(1, 1), material, puffs.length);
    mesh.name = 'cloud-puffs';
    mesh.frustumCulled = false; // billboards span the whole track; a plane's own bounds would cull them
    mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    mesh.renderOrder = 1; // transparent pass, after the opaque road and scenery
    group.add(mesh);
    return { mesh, puffs };
  });

  if (!backdropSea) {
    const sea = new THREE.Mesh(seaGeometry(), new THREE.MeshBasicMaterial({ vertexColors: true, fog: true, side: THREE.DoubleSide }));
    sea.name = 'cloud-sea';
    group.add(sea);
  }

  function update(seconds) {
    for (const { mesh, puffs } of layers) {
      for (let i = 0; i < puffs.length; i++) {
        const p = puffs[i];
        dummy.position.set(
          p.pos[0] + Math.sin(seconds * p.drift + p.phase) * 6,
          p.pos[1],
          p.pos[2] + Math.cos(seconds * p.drift * 0.7 + p.phase) * 4,
        );
        dummy.quaternion.copy(camera.quaternion); // billboard: the plane's normal follows the view
        dummy.scale.setScalar(p.scale);
        dummy.updateMatrix();
        mesh.setMatrixAt(i, dummy.matrix);
      }
      mesh.instanceMatrix.needsUpdate = true;
    }
  }
  update(0);
  return { group, update };
}
