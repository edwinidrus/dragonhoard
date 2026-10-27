// Auditor autopilot: drives the built game through real keyboard input and checks laps count
// and the kart stays on the road. Track maths comes from the game's own pure logic modules,
// imported in Node; the page itself is driven only by key presses.
//   node lap.mjs <served dir> <game repo> [laps=1] [timeoutS=150]
//   DRIFT=1 also drifts (Space) through corners and releases on the exit.
//   EMBER=1 (G6+): fires Shift when holding an item and a rival is 4-20 m ahead within 1.5 m laterally,
//   then records shots and the rivals' speed drop.
//   TRACE=1 records [t, s, lateral, speed, lap] about every 2 s in full.trace.
//   TRACK=<id> (G7+): picks the track on the menu by keys (ArrowRight, Enter); default the first.
//   RACER=<id> (G8+): picks the racer card the same way; default the first.
//   FULL=1 (race flow, G5+): checks nothing moves before GO, then after the last lap reads the
//   results screen and presses Enter to check the restart. SHOTDIR=<dir> saves hud.png/results.png.
import { createRequire } from 'node:module';
import { spawn } from 'node:child_process';
import { pathToFileURL } from 'node:url';

const [dir, repo, wantLaps = '1', timeoutS = '150'] = process.argv.slice(2);
const { chromium } = createRequire(`${repo}/package.json`)('playwright');
const { createTrack, locate, pointAt } = await import(pathToFileURL(`${repo}/src/logic/track.js`));
const data = await import(pathToFileURL(`${repo}/src/logic/trackData.js`));
const tracks = data.TRACKS ?? [data.TRACK]; // G7+: the menu lists TRACKS in this order
const trackIdx = Math.max(0, tracks.findIndex((t) => t.id === process.env.TRACK));
const TRACK = tracks[trackIdx];
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
await page.locator('canvas').click({ force: true }); // G7+: the menu overlay covers the canvas; the click only focuses the page
if (await page.evaluate(() => window.__hoard.screen === 'menu')) { // G7+: pick the track by keys
  for (let i = 0; i < trackIdx; i++) await page.keyboard.press('ArrowRight');
  await page.keyboard.press('Enter');
  await page.waitForTimeout(300);
}
if (await page.evaluate(() => window.__hoard.screen === 'racers')) { // G8+: RACER=<id> picks a card by keys; default the first
  const ids = await page.evaluate(() => window.__hoard.racers ?? []);
  for (let i = 0; i < Math.max(0, ids.indexOf(process.env.RACER)); i++) await page.keyboard.press('ArrowRight');
  await page.keyboard.press('Enter');
  await page.waitForTimeout(300);
}

const held = new Set();
const hold = async (key, on) => {
  if (on && !held.has(key)) { await page.keyboard.down(key); held.add(key); }
  if (!on && held.has(key)) { await page.keyboard.up(key); held.delete(key); }
};
const read = () => page.evaluate(() => ({ ...window.__hoard.player, halfWidth: window.__hoard.track?.halfWidth }));

const full = {};
if (process.env.FULL) { // hold accelerate through the countdown: the kart must not move before GO
  await page.keyboard.down('ArrowUp');
  let maxBeforeGo = 0; const phases = new Set();
  for (let i = 0; i < 80; i++) {
    const s = await page.evaluate(() => ({ phase: window.__hoard.phase, speed: window.__hoard.player?.speed ?? 0 }));
    phases.add(s.phase);
    if (s.phase === 'countdown') maxBeforeGo = Math.max(maxBeforeGo, Math.abs(s.speed)); else break;
    await page.waitForTimeout(50);
  }
  const early = new Set(); // the player starts on the front of the grid: right after GO it must read 1st
  for (let i = 0; i < 30; i++) {
    const m = (await page.evaluate(() => document.body.innerText)).match(/\b([1-4])(st|nd|rd|th)\b/);
    if (m) early.add(m[0]);
    await page.waitForTimeout(50);
  }
  await page.keyboard.up('ArrowUp');
  Object.assign(full, { phasesAtStart: [...phases], maxSpeedBeforeGo: +maxBeforeGo.toFixed(3), positionsFirst1500ms: [...early] });
}
let prev = await read();
let hudShot = false;
const ember = { pickups: 0, fires: [], slowedRatios: [] };
let watch = null;
const start = Date.now();
let maxLateral = 0, samples = 0, lapTimes = [];
while ((Date.now() - start) / 1000 < Number(timeoutS)) {
  await page.waitForTimeout(40);
  const now = await read();
  samples++;
  maxLateral = Math.max(maxLateral, Math.abs(now.lateral));
  driftHeldMax = Math.max(driftHeldMax, now.driftCharge ?? 0);
  if (process.env.TRACE && samples % 50 === 0) (full.trace ??= []).push([+((Date.now() - start) / 1000).toFixed(0), +locate(track, now).s.toFixed(0), +now.lateral.toFixed(1), +now.speed.toFixed(1), now.lap]); // TRACE=1: [t, s, lateral, speed, lap] every ~2 s
  if (now.lap > prev.lap) lapTimes.push(((Date.now() - start) / 1000).toFixed(1));
  if (now.lap >= Number(wantLaps)) { prev = now; break; }
  if (process.env.SHOTDIR && !hudShot && (Date.now() - start) > 20000) { await page.screenshot({ path: `${process.env.SHOTDIR}/hud.png` }); hudShot = true; }
  // steer towards a point ahead on the centreline; heading estimated from motion
  const here = locate(track, { x: now.x, y: now.y });
  if (lastS !== null) { let d = here.s - lastS; if (d > track.length / 2) d -= track.length; if (d < -track.length / 2) d += track.length; sTravel += d; }
  lastS = here.s;
  if (dirSign < 0 && -sTravel > track.length * 1.05) break;
  const lane = process.env.EMBER && !ember.pickups && !now.item ? 2.5 : 0; // box 0 sits at lateral +2.5
  const target = pointAt(track, (here.s + 9 * dirSign + track.length) % track.length, lane);
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
  if (process.env.EMBER) {
    const s = await page.evaluate(() => ({ karts: window.__hoard.karts, shots: window.__hoard.emberShots }));
    if (now.item && !prev.item) ember.pickups++;
    // gap along the lap, wrapped to (-L/2, L/2]: lap counters lag at the start line, so don't use them
    const sOf = (k) => locate(track, { x: k.x, y: k.y }).s;
    const gap = (k) => { let d = sOf(k) - sOf(s.karts[0]); if (d > track.length / 2) d -= track.length; if (d <= -track.length / 2) d += track.length; return d; };
    const lat0 = locate(track, s.karts[0]).lateral;
    const target = s.karts.findIndex((k, i) => i > 0 && gap(k) > 4 && gap(k) < 20 && Math.abs(locate(track, k).lateral - lat0) < 1.5);
    if (process.env.EMBER_DEBUG && samples % 25 === 0) (ember.debug ??= []).push({ t: +((Date.now() - start) / 1000).toFixed(1), item: now.item, gaps: s.karts.map((k) => +gap(k).toFixed(1)), dlat: s.karts.map((k) => +(locate(track, k).lateral - lat0).toFixed(1)) });
    if (now.item && target > 0 && !watch) {
      await page.keyboard.press('Shift');
      watch = { target, at: Date.now(), speed0: s.karts[target].speed, min: Infinity, shotsSeen: 0 };
    }
    if (watch) {
      watch.min = Math.min(watch.min, s.karts[watch.target].speed);
      watch.shotsSeen = Math.max(watch.shotsSeen, s.shots ?? 0);
      if (Date.now() - watch.at > 1500) {
        ember.fires.push({ target: watch.target, speedBefore: +watch.speed0.toFixed(2), minAfter: +watch.min.toFixed(2), shotsSeen: watch.shotsSeen });
        watch = null;
      }
    }
  }
  // G7+: the 13 m/s cruise is below Lantern's jump speeds, so hold full throttle over the 40 m before a jump.
  const nearJump = (track.jumps ?? []).some((j) => (j.s[0] - here.s + track.length) % track.length < 40);
  await hold('ArrowUp', process.env.DRIFT || nearJump ? true : now.speed < 13);
  prev = now;
}
for (const k of [...held]) await hold(k, false);
if (process.env.FULL) {
  await page.waitForTimeout(1000);
  full.phaseAfterLastLap = await page.evaluate(() => window.__hoard.phase);
  full.raceTime = await page.evaluate(() => window.__hoard.raceTime);
  full.resultsText = (await page.evaluate(() => document.body.innerText)).replace(/\s+/g, ' ').slice(0, 400);
  if (process.env.SHOTDIR) await page.screenshot({ path: `${process.env.SHOTDIR}/results.png` });
  await page.keyboard.press('Enter');
  await page.waitForTimeout(600);
  full.afterEnter = await page.evaluate(() => ({ phase: window.__hoard.phase, lap: window.__hoard.player?.lap, raceTime: window.__hoard.raceTime }));
}
const karts = await page.evaluate(() => window.__hoard.karts?.map((k) => ({ lap: k.lap, speed: +(k.speed ?? 0).toFixed(2) })) ?? null);
if (process.env.SHOT) await page.screenshot({ path: process.env.SHOT });
await browser.close();
srv.kill();
console.log(JSON.stringify({ lapsCounted: prev.lap, wanted: Number(wantLaps), lapTimes, maxLateral: +maxLateral.toFixed(3),
  halfWidth: prev.halfWidth, sTravel: +sTravel.toFixed(1), boostOnsets, drifts, driftHeldMax, karts, full, ember, onRoad: maxLateral <= (prev.halfWidth ?? Infinity), samples, pageErrors: errors }));
