// Auditor check for kart-to-kart collision in the real race loop: put every rival in one lane so
// they must touch (and must pass the parked player), then look for contacts, deep overlaps, NaN and stalls.
//   node collcheck.mjs <game repo> [seconds=120]
const [repo, seconds = '120'] = process.argv.slice(2);
const { createTrack } = await import(`${repo}/src/logic/track.js`);
const { TRACK } = await import(`${repo}/src/logic/trackData.js`);
const { createRace, stepRace } = await import(`${repo}/src/logic/race.js`);
const { NO_CONTROLS } = await import(`${repo}/src/logic/controls.js`);
const track = createTrack(TRACK);
const CONTACT = 1.4;
const lane = Number(process.env.LANE ?? 2.5); // the parked player sits on lateral +2.5
let race = createRace(track, { laneOffsets: [lane, lane, lane], skills: [0.8, 0.9, 1] }); // faster karts start behind
let contacts = 0, minGap = Infinity, deep = 0, bad = 0;
for (let step = 1; step <= Number(seconds) * 60; step++) {
  race = stepRace(race, NO_CONTROLS, 1 / 60);
  const pos = race.karts.map((e) => e.kart.pos);
  if (pos.some((p) => !Number.isFinite(p.x) || !Number.isFinite(p.y))) bad++;
  for (let i = 0; i < pos.length; i++) for (let j = i + 1; j < pos.length; j++) {
    const gap = Math.hypot(pos[i].x - pos[j].x, pos[i].y - pos[j].y);
    if (step > 1) minGap = Math.min(minGap, gap);
    if (gap < CONTACT) contacts++;
    if (gap < 0.7) deep++; // karts more than half inside each other
  }
}
const laps = race.karts.map((e) => e.laps.laps);
console.log(JSON.stringify({ contactPairSteps: contacts, minGap: +minGap.toFixed(3), deepOverlapSteps: deep, nonFiniteSteps: bad, laps }));
