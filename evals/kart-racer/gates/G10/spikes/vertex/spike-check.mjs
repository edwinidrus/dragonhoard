import assert from 'node:assert/strict';
import { readFile, readdir, writeFile, mkdir } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { gzipSync } from 'node:zlib';
import net from 'node:net';
import { build, preview } from 'vite';
import { chromium } from '@playwright/test';
import { createSky } from './src/render/sky.js';
import * as THREE from 'three';

await mkdir('evidence', { recursive: true });
const originalBaseline = JSON.parse(await readFile('evidence/baseline.json', 'utf8'));
const cleanScene = execFileSync('git', ['show', 'HEAD:src/render/scene.js'], { encoding: 'utf8' });
async function measure(outDir, baseline = false) {
  await build({ plugins: baseline ? [{ name: 'clean-scene', enforce: 'pre',
    load(id) { if (id.endsWith('/src/render/scene.js')) return cleanScene; } }] : [],
  build: { outDir } });
  const bytes = { js: 0, html: 0 };
  const nodeBytes = { js: 0, html: 0 };
  for (const file of await readdir(outDir, { recursive: true })) {
    const type = file.endsWith('.js') ? 'js' : file.endsWith('.html') ? 'html' : null;
    if (type) {
      const input = await readFile(`${outDir}/${file}`);
      bytes[type] += execFileSync('gzip', ['-9', '-c'], { input }).length;
      nodeBytes[type] += gzipSync(input, { level: 9 }).length;
    }
  }
  return { ...bytes, total: bytes.js + bytes.html,
    noncanonicalNode: { ...nodeBytes, total: nodeBytes.js + nodeBytes.html } };
}
const baseline = await measure('evidence/baseline-dist', true);
assert.deepEqual(baseline.noncanonicalNode, originalBaseline, 'clean pre-edit Node baseline reproducible');
assert.equal(baseline.total, 148620, 'canonical CLI baseline');
const variant = await measure('dist');
const sceneText = await readFile('src/render/scene.js', 'utf8');
assert(!sceneText.includes('toneMapping'));
assert(sceneText.includes('scene.background = new THREE.Color(skyColor(track));'));
assert.equal(execFileSync('git', ['diff', 'HEAD', '--', 'package.json', 'package-lock.json', 'src/main.js'], { encoding: 'utf8' }), '');
const sky = createSky();
sky.setTrack({ id: 'lantern' });
const [dome, sun, stars] = sky.group.children;
assert(dome.material.isMeshBasicMaterial && dome.material.vertexColors);
assert.equal(dome.material.side, THREE.BackSide);
assert.equal(dome.material.depthWrite, false);
assert.equal(dome.geometry.parameters.radius, 450);
assert(dome.geometry.getAttribute('color').count > 0);
const sunAngle = Math.atan2(sun.position.y, sun.position.x) * 180 / Math.PI;
assert(sunAngle >= 3 && sunAngle <= 6);
const starPositions = stars.geometry.getAttribute('position');
for (let i = 0; i < starPositions.count; i++) assert(starPositions.getY(i) / 440 > Math.sin(Math.PI / 4));
const geometry = { vertices: dome.geometry.getAttribute('position').count,
  triangles: dome.geometry.index.count / 3, sunTriangles: sun.geometry.index.count / 3,
  stars: starPositions.count, segments: [128, 96] };

// Refuse occupied port, never reuse/kill foreign listeners. Vite strictPort closes race window.
await new Promise((resolve, reject) => {
  const probe = net.createServer(); probe.once('error', reject);
  probe.listen(5182, '127.0.0.1', () => probe.close(resolve));
});
const server = await preview({ preview: { host: '127.0.0.1', port: 5182, strictPort: true } });
let browser;
const errors = [], images = [], views = [];
try {
  browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
  page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  page.on('pageerror', err => errors.push(err.message));
  page.on('request', req => { if (req.resourceType() === 'image' || /\.(png|jpg|jpeg|webp|ktx|hdr)(\?|$)/i.test(req.url())) images.push(req.url()); });
  for (const [track, label] of [['lantern', 'Lantern Reach'], ['ember', 'Ember Circuit']]) {
    await page.goto('http://127.0.0.1:5182/');
    await page.waitForFunction(() => window.__hoard?.screen === 'menu');
    const selected = page.locator('#menu-choices [data-selected="true"]');
    for (let i = 0; i < 8 && await selected.textContent() !== label; i++) await page.keyboard.press('ArrowRight');
    assert.equal(await selected.textContent(), label);
    await page.keyboard.press('Enter');
    await page.waitForFunction(() => window.__hoard.screen === 'racers');
    await page.keyboard.press('Enter');
    await page.waitForFunction(() => window.__hoard.screen === 'race');
    await page.waitForFunction(() => window.__hoard.phase === 'racing');
    await page.waitForFunction(() => window.__hoard.raceTime > 5); // Let countdown/GO stop covering sun.
    const poses = track === 'lantern' ? [['sun-horizon', 1, 4.5], ['zenith-stars', 1, 72], ['anti-sun', -1, 6]] : [['day', 1, 4.5]];
    const originalPoses = poses.map(([name, dir, degrees]) => {
      // Both near-ground and y=400 camera poses verify render-time centring with real review hook.
      const y = name === 'zenith-stars' ? 400 : 8;
      const position = [0, y, 0];
      const target = [dir * 100 * Math.cos(degrees * Math.PI / 180), y + 100 * Math.sin(degrees * Math.PI / 180), 0];
      return { name, position, target, standardized: false };
    });
    const standardizedPoses = (track === 'lantern'
      ? [['sun-horizon', [100, 407.87, 0]], ['anti-sun', [-100, 407.87, 0]], ['zenith-stars', [1, 500, 0]]]
      : [['day', [100, 407.87, 0]]]).map(([name, target]) => ({
      name: `standard-${name}`, position: [0, 400, 0], target, standardized: true,
    }));
    for (const { name, position, target, standardized } of [...originalPoses, ...standardizedPoses]) {
      const calls = await page.evaluate(async ({ position, target }) => {
        window.__hoard.view = { position, target };
        await new Promise(done => requestAnimationFrame(() => requestAnimationFrame(() => requestAnimationFrame(done))));
        return window.__hoard.drawCalls;
      }, { position, target });
      assert(calls > 0 && calls <= 100, `draw calls ${calls}`);
      if (standardized) assert(calls <= 3, `dome-only calls ${calls}`);
      const file = `evidence/${track}-${name}.png`;
      await page.screenshot({ path: file });
      const png = await readFile(file);
      assert.equal(png.subarray(1, 4).toString(), 'PNG');
      views.push({ track, name, position, target, standardized, calls, file, pngBytes: png.length });
    }
  }
  assert.deepEqual(errors, []);
  assert.deepEqual(images, []);
  const result = { baseline, variant, delta: variant.total - baseline.total, geometry, views,
    consolePageErrors: errors.length, runtimeImageRequests: images.length };
  await writeFile('evidence/result.json', JSON.stringify(result, null, 2));
  console.log('PASS', JSON.stringify(result));
} finally {
  await browser?.close();
  await new Promise(resolve => server.httpServer.close(resolve));
}
