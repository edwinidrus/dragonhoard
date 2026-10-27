import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readdirSync, readFileSync } from 'node:fs';
import { gzipSync } from 'node:zlib';

// Fail fast on a decisive disqualifier; this is not a complete contract check.
const { createEngine } = await import('./src/audio/engine.js');
assert.equal(typeof createEngine, 'function');
const build = spawnSync(process.execPath, ['node_modules/vite/bin/vite.js', 'build'], { encoding: 'utf8' });
process.stdout.write(build.stdout);
process.stderr.write(build.stderr);
assert.equal(build.status, 0);
const walk = dir => readdirSync(dir, { withFileTypes: true }).flatMap(e =>
  e.isDirectory() ? walk(`${dir}/${e.name}`) : [`${dir}/${e.name}`]);
const files = walk('dist').sort().map(file => ({ file, gzipBytes: gzipSync(readFileSync(file), { level: 9 }).length }));
const total = files.reduce((n, f) => n + f.gzipBytes, 0);
console.log(JSON.stringify({ files, baseline: 144068, total, delta: total - 144068 }, null, 2));
assert.ok(total - 144068 < 30000, `BUDGET FAIL: delta ${total - 144068} >= 30000`);
assert.fail('INCONCLUSIVE: cost passed; sequencing and Chromium criteria remain unimplemented');
