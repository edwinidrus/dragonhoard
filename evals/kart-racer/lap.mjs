// Auditor autopilot: drives the built game through real keyboard input and checks laps count
// and the kart stays on the road. Track maths comes from the game's own pure logic modules,
// imported in Node; the page itself is driven only by key presses.
//   node lap.mjs <served dir> <game repo> [laps=1] [timeoutS=150]
//   DRIFT=1 also drifts (Space) through corners and releases on the exit.
import { createRequire } from 'node:module';
import { spawn } from 'node:child_process';
import { pathToFileURL } from 'node:url';

const [dir, repo, wantLaps = '1', timeoutS = '150'] = process.argv.slice(2);
const { chromium } = createRequire(`${repo}/package.json`)('playwright');
const { createTrack, locate, pointAt } = await import(pathToFileURL(`${repo}/src/logic/track.js`));
const { TRACK } = await import(pathToFileURL(`${repo}/src/logic/trackData.js`));
const track = createTrack(TRACK);
const dirSign = process.env.REVERSE ? -1 : 1; // REVERSE=1 drives the wrong way round
let sTravel = 0, lastS = null;
const padRanges = (TRACK.pads ?? []).map((p) => [p.at * track.length, p.at * track.length + p.length]);
const onPad = (s) => padRanges.some(([a, b]) => [s, s + track.length].some((x) => x >= a - 2 && x <= b + 2));
let boostOnsets = [], drifts = 0, driftHeldMax = 0, wasBoosting = false;

const srv = spawn('python3', ['-m', 'http.server', '8793', '--bind', '127.0.0.1', '-d', dir], { stdio: 'ignore' });
await new Promise((r) => setTimeout(r, 800));
const browser = await chromium.launch();
const page = await browser.newPage();
const errors = [];
page.on('pageerror', (e) => errors.push(e.message));
await page.goto('http://127.0.0.1:8793/');
await page.waitForTimeout(1000);
await page.locator('canvas').click();

const held = new Set();
const hold = async (key, on) => {
  if (on && !held.has(key)) { await page.keyboard.down(key); held.add(key); }
  if (!on && held.has(key)) { await page.keyboard.up(key); held.delete(key); }
};
const read = () => page.evaluate(() => ({ ...window.__hoard.player, halfWidth: window.__hoard.track?.halfWidth }));

let prev = await read();
const start = Date.now();
let maxLateral = 0, samples = 0, lapTimes = [];
while ((Date.now() - start) / 1000 < Number(timeoutS)) {
  await page.waitForTimeout(40);
  const now = await read();
  samples++;
  maxLateral = Math.max(maxLateral, Math.abs(now.lateral));
  driftHeldMax = Math.max(driftHeldMax, now.driftCharge ?? 0);
  if (now.lap > prev.lap) lapTimes.push(((Date.now() - start) / 1000).toFixed(1));
  if (now.lap >= Number(wantLaps)) { prev = now; break; }
  // steer towards a point ahead on the centreline; heading estimated from motion
  const here = locate(track, { x: now.x, y: now.y });
  if (lastS !== null) { let d = here.s - lastS; if (d > track.length / 2) d -= track.length; if (d < -track.length / 2) d += track.length; sTravel += d; }
  lastS = here.s;
  if (dirSign < 0 && -sTravel > track.length * 1.05) break;
  const target = pointAt(track, (here.s + 9 * dirSign + track.length) % track.length, 0);
  const vx = now.x - prev.x, vy = now.y - prev.y;
  const moving = Math.hypot(vx, vy) > 0.05;
  const hx = moving ? vx : here.tangent.x, hy = moving ? vy : here.tangent.y;
  const tx = target.x - now.x, ty = target.y - now.y;
  const cross = hx * ty - hy * tx; // > 0: target is to the left (CCW)
  const angle = Math.atan2(cross, hx * tx + hy * ty);
  await hold('ArrowLeft', angle > 0.06);
  await hold('ArrowRight', angle < -0.06);
  if (now.boosting && !wasBoosting) boostOnsets.push({ s: +here.s.toFixed(1), pad: onPad(here.s) });
  wasBoosting = now.boosting;
  if (process.env.DRIFT) {
    if (!held.has(' ') && Math.abs(angle) > 0.15 && now.speed > 12) { await hold(' ', true); drifts++; }
    else if (held.has(' ') && ((now.driftCharge ?? 0) >= 1 && Math.abs(angle) < 0.1 || now.speed < 9)) await hold(' ', false);
  }
  await hold('ArrowUp', process.env.DRIFT ? true : now.speed < 13);
  prev = now;
}
for (const k of [...held]) await hold(k, false);
const karts = await page.evaluate(() => window.__hoard.karts?.map((k) => ({ lap: k.lap, speed: +(k.speed ?? 0).toFixed(2) })) ?? null);
if (process.env.SHOT) await page.screenshot({ path: process.env.SHOT });
await browser.close();
srv.kill();
console.log(JSON.stringify({ lapsCounted: prev.lap, wanted: Number(wantLaps), lapTimes, maxLateral: +maxLateral.toFixed(3),
  halfWidth: prev.halfWidth, sTravel: +sTravel.toFixed(1), boostOnsets, drifts, driftHeldMax, karts, onRoad: maxLateral <= (prev.halfWidth ?? Infinity), samples, pageErrors: errors }));
