import assert from 'node:assert/strict';
import { readFileSync, readdirSync, writeFileSync, mkdirSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { gzipSync } from 'node:zlib';
import net from 'node:net';
import { build, preview } from 'vite';
import { chromium } from '@playwright/test';
import { createSky } from './src/render/sky.js';

mkdirSync('evidence', { recursive: true });
const git = (file) => execFileSync('git', ['show', `23eeedc:${file}`], { encoding: 'utf8' });
for (const file of ['package.json', 'package-lock.json', 'src/main.js']) {
  assert.equal(readFileSync(file, 'utf8'), git(file), `${file} unchanged`);
}
assert(!readFileSync('src/render/sky.js', 'utf8').includes('toneMapping'));
const source = readFileSync('src/render/scene.js', 'utf8');
assert.equal(source.match(/toneMapping/g)?.length ?? 0, git('src/render/scene.js').match(/toneMapping/g)?.length ?? 0);
const files = (dir) => readdirSync(dir, { withFileTypes: true }).flatMap((e) =>
  e.isDirectory() ? files(`${dir}/${e.name}`) : [`${dir}/${e.name}`]);
function measure(dir, canonical = false) {
  const result = { js: 0, html: 0 };
  for (const file of files(dir)) {
    const kind = file.endsWith('.js') ? 'js' : file.endsWith('.html') ? 'html' : null;
    if (kind) result[kind] += (canonical
      ? execFileSync('gzip', ['-9', '-c'], { input: readFileSync(file) })
      : gzipSync(readFileSync(file), { level: 9 })).length;
  }
  return { ...result, total: result.js + result.html };
}
// Rebuild pinned clean scene without editing source; original baseline was also built before edits.
await build({ plugins: [{ name: 'clean-baseline', enforce: 'pre', load(id) {
  if (id.endsWith('/src/render/scene.js')) return git('src/render/scene.js');
} }], build: { outDir: 'dist-baseline' } });
const baseline = measure('dist-baseline');
const original = JSON.parse(readFileSync('evidence/baseline.json', 'utf8'));
assert.equal(baseline.total, original.total);
await build({ build: { outDir: 'dist' } });
const current = measure('dist');
const delta = Object.fromEntries(Object.keys(current).map((key) => [key, current[key] - baseline[key]]));
const canonicalBaseline = measure('dist-baseline', true);
const canonicalCurrent = measure('dist', true);
const canonicalDelta = Object.fromEntries(Object.keys(current).map((key) => [key, canonicalCurrent[key] - canonicalBaseline[key]]));
console.log('CANONICAL CLI gzip -9 stdin', JSON.stringify({ baseline: canonicalBaseline, current: canonicalCurrent, delta: canonicalDelta }));
const dome = createSky();
const geometry = { vertices: dome.geometry.attributes.position.count, triangles: dome.geometry.index.count / 3, radius: dome.geometry.parameters.radius };
assert.equal(geometry.radius, 450);
assert.equal(dome.material.depthWrite, false);
assert(dome.material.fragmentShader.includes('#include <colorspace_fragment>'));
await new Promise((resolve, reject) => {
  const probe = net.createServer();
  probe.once('error', reject);
  probe.listen(5181, '127.0.0.1', () => probe.close(resolve));
});
console.log('PORT 5181 free; strictPort=true');
let server, browser;
const errors = [], images = [], views = [];
try {
  server = await preview({ preview: { host: '127.0.0.1', port: 5181, strictPort: true } });
  browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
  page.on('console', (msg) => { if (msg.type() === 'error') errors.push(msg.text()); });
  page.on('pageerror', (err) => errors.push(err.message));
  page.on('request', (req) => {
    if (/^https?:/.test(req.url()) && (req.resourceType() === 'image' || /\.(png|jpe?g|webp|ktx2?|hdr)(\?|$)/i.test(req.url()))) images.push(req.url());
  });
  for (const track of ['Lantern Reach', 'Ember Circuit']) {
    await page.goto('http://127.0.0.1:5181/');
    await page.waitForFunction(() => window.__hoard?.screen === 'menu');
    const selected = page.locator('#menu-choices [data-selected="true"]');
    for (let i = 0; i < 8 && await selected.textContent() !== track; i++) await page.keyboard.press('ArrowRight');
    assert.equal(await selected.textContent(), track);
    await page.keyboard.press('Enter');
    await page.waitForFunction(() => window.__hoard?.screen === 'racers');
    await page.keyboard.press('Enter');
    await page.waitForFunction(() => window.__hoard?.screen === 'race');
    await page.waitForFunction(() => window.__hoard?.phase === 'racing');
    await page.waitForTimeout(1500); // let the existing GO! overlay expire, without changing UI
    const poses = track === 'Lantern Reach'
      ? [['lantern-sun', 1, 4.5], ['lantern-zenith', 1, 75], ['lantern-antisun', -1, 4.5], ['lantern-translated', 1, 4.5]]
      : [['ember-day', 1, 4.5]];
    poses.push(...(track === 'Lantern Reach'
      ? [['standard-lantern-sun', 1, 4.5, [100, 407.87, 0]], ['standard-lantern-antisun', -1, 4.5, [-100, 407.87, 0]], ['standard-lantern-zenith', 1, 90, [1, 500, 0]]]
      : [['standard-ember-day', 1, 4.5, [100, 407.87, 0]]]));
    for (const [name, sign, degrees, standardTarget] of poses) {
      const elevation = degrees * Math.PI / 180;
      const position = standardTarget ? [0, 400, 0] : name === 'lantern-translated' ? [900, 400, -800] : [0, 8, -100];
      const target = standardTarget ?? [position[0] + sign * 100 * Math.cos(elevation), position[1] + 100 * Math.sin(elevation), position[2]];
      const calls = await page.evaluate(async (view) => {
        window.__hoard.view = view;
        await new Promise((done) => requestAnimationFrame(() => requestAnimationFrame(() => requestAnimationFrame(done))));
        return window.__hoard.drawCalls;
      }, { position, target });
      assert(calls > 0 && calls <= 100, `${name} draw calls=${calls}`);
      if (standardTarget) assert.equal(calls, 1, `${name} isolates one dome draw`);
      const path = `evidence/${name}.png`;
      await page.screenshot({ path });
      const png = readFileSync(path);
      assert.equal(png.subarray(1, 4).toString(), 'PNG');
      assert(png.length > 2000);
      views.push({ name, calls, position, target, screenshot: path, bytes: png.length });
    }
  }
  assert.deepEqual(errors, []);
  assert.deepEqual(images, []);
  const result = { canonical: { baseline: canonicalBaseline, current: canonicalCurrent, delta: canonicalDelta }, noncanonicalNodeZlib: { baseline, current, delta }, geometry, views, errors, runtimeImageRequests: images.length };
  writeFileSync('evidence/result.json', JSON.stringify(result, null, 2));
  console.log(JSON.stringify(result));
  console.log('PASS both tracks; console/page errors=0; runtime image/texture requests=0; dependencies/main/toneMapping unchanged');
} finally {
  await browser?.close();
  await server?.close();
  dome.geometry.dispose(); dome.material.dispose();
}
