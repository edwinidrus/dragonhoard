import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { gzipSync } from 'node:zlib';
import net from 'node:net';
import { chromium } from '@playwright/test';
// Check fixed port before any server start; never reuse or kill foreign process.
await new Promise((resolve, reject) => { const s = net.createServer(); s.once('error', reject); s.listen(5271, '127.0.0.1', () => s.close(resolve)); });
for (const [name, args] of [['tests', ['--test', 'test/logic/sequencer.test.js']], ['build', ['node_modules/vite/bin/vite.js', 'build']]]) {
  const r = spawnSync(process.execPath, args, { encoding: 'utf8' });
  writeFileSync(`spike-${name}.log`, r.stdout + r.stderr); console.log(r.stdout, r.stderr); assert.equal(r.status, 0, name);
}
const walk = d => readdirSync(d, { withFileTypes: true }).flatMap(e => e.isDirectory() ? walk(`${d}/${e.name}`) : [`${d}/${e.name}`]);
const files = walk('dist').sort().map(file => ({ file, gzipBytes: gzipSync(readFileSync(file), { level: 9 }).length }));
const total = files.reduce((n, f) => n + f.gzipBytes, 0), delta = total - 144068;
console.log(JSON.stringify({ files, total, baseline: 144068, delta })); assert.ok(delta < 30000);
const server = spawn(process.execPath, ['node_modules/vite/bin/vite.js', 'preview', '--host', '127.0.0.1', '--port', '5271', '--strictPort'], { stdio: ['ignore', 'pipe', 'pipe'] });
let serverLog = ''; server.stdout.on('data', d => serverLog += d); server.stderr.on('data', d => serverLog += d);
let browser;
try {
  await new Promise((resolve, reject) => { server.once('exit', c => reject(new Error(`preview exit ${c}`))); server.stdout.on('data', () => { if (serverLog.includes('5271')) resolve(); }); setTimeout(() => reject(new Error('preview timeout')), 15000).unref(); });
  browser = await chromium.launch({ headless: true });
  const page = await browser.newPage(); const errors = [];
  page.on('pageerror', e => errors.push(String(e))); page.on('console', m => { if (m.type() === 'error' || /autoplay|AudioContext.*(not allowed|suspend)/i.test(m.text())) errors.push(m.text()); });
  await page.addInitScript(() => { window.__contexts = 0; const Original = window.AudioContext; window.AudioContext = class extends Original { constructor(...args) { super(...args); window.__contexts++; } }; });
  await page.goto('http://127.0.0.1:5271/'); await page.waitForFunction(() => window.__hoard?.frame > 2);
  assert.equal(await page.evaluate(() => window.__contexts), 0);
  await page.keyboard.press('n'); await page.waitForFunction(() => window.__nativeSpike);
  const result = await page.evaluate(() => ({ contexts: window.__contexts, exercise: window.__nativeSpike }));
  assert.equal(result.contexts, 1); assert.equal(result.exercise.done, true, JSON.stringify(result)); assert.deepEqual(errors, []);
  console.log(JSON.stringify({ browser: await browser.version(), beforeKey: 0, ...result, errors }));
  console.log(`PASS native full criterion; total=${total} delta=${delta} dependencies=none`);
} finally {
  await browser?.close(); const exit = new Promise(resolve => server.once('exit', resolve)); server.kill('SIGTERM'); await exit; writeFileSync('spike-server.log', serverLog);
}
