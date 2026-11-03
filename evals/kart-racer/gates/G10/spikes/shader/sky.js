import * as THREE from 'three';

// ponytail: one finite 450 m sphere, not an infinite background; stays inside camera.far=500.
export function createSky() {
  const color = (hex) => ({ value: new THREE.Color(hex) });
  const material = new THREE.ShaderMaterial({
    side: THREE.BackSide,
    depthWrite: false,
    uniforms: {
      dusk: { value: 0 },
      violet: color('#1b1240'), purple: color('#3a2463'), rose: color('#b45a8c'),
      orange: color('#f08a5d'), gold: color('#ffc36b'), sun: color('#fff1c1'),
      opposite: color('#606d89'), day: color('#8fc7e8'), dayHorizon: color('#cee5ef'),
    },
    vertexShader: `
      varying vec3 direction;
      void main() {
        direction = position;
        gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
      }
    `,
    fragmentShader: `
      uniform float dusk;
      uniform vec3 violet, purple, rose, orange, gold, sun, opposite, day, dayHorizon;
      varying vec3 direction;
      float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
      void main() {
        vec3 d = normalize(direction);
        float h = max(d.y, 0.0);
        vec3 c = mix(gold, orange, smoothstep(0.0, 0.12, h));
        c = mix(c, rose, smoothstep(0.12, 0.30, h));
        c = mix(c, purple, smoothstep(0.30, 0.65, h));
        c = mix(c, violet, smoothstep(0.65, 1.0, h));
        float anti = smoothstep(0.15, 0.85, -d.x / max(length(d.xz), 0.001));
        c = mix(c, opposite, anti * (1.0 - smoothstep(0.0, 0.23, h)));
        float belt = smoothstep(0.01, 0.07, h) * (1.0 - smoothstep(0.12, 0.24, h));
        c = mix(c, rose, anti * belt * 0.65);
        float sunDot = dot(d, vec3(0.9969173, 0.0784591, 0.0));
        c = mix(c, sun, smoothstep(0.99975, 0.99985, sunDot));
        // ponytail: fixed spherical hash cells; no animation/textures; tune density after owner review.
        vec2 grid = vec2(atan(d.z, d.x), asin(clamp(d.y, -1.0, 1.0))) * vec2(90.0, 110.0);
        vec2 cell = floor(grid);
        float star = step(0.994, hash(cell)) * (1.0 - smoothstep(0.025, 0.20, length(fract(grid) - 0.5)));
        c += sun * star * 0.22 * smoothstep(0.707107, 0.77, d.y);
        c = mix(mix(dayHorizon, day, smoothstep(0.0, 0.8, h)), c, dusk);
        gl_FragColor = vec4(c, 1.0);
        #include <colorspace_fragment>
      }
    `,
  });
  const sky = new THREE.Mesh(new THREE.SphereGeometry(450, 32, 16), material);
  sky.name = 'gradient-sky';
  sky.frustumCulled = false;
  sky.renderOrder = -1000;
  return sky;
}
