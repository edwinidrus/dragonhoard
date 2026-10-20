// Independent check: distance each rival actually travels to its 3rd lap, and the implied mean speed.
const repo = process.argv[2];
const { createTrack } = await import(`${repo}/src/logic/track.js`);
const { TRACK } = await import(`${repo}/src/logic/trackData.js`);
const { createRace, stepRace } = await import(`${repo}/src/logic/race.js`);
const { NO_CONTROLS } = await import(`${repo}/src/logic/controls.js`);
const track = createTrack(TRACK);
let race = createRace(track);
const dist = [0, 0, 0, 0], prev = race.karts.map((e) => ({ ...e.kart.pos })), done = [null, null, null];
let maxSpeed = 0;
for (let step = 1; step <= 60 * 200 && done.some((d) => d === null); step++) {
  race = stepRace(race, NO_CONTROLS, 1 / 60);
  race.karts.forEach((e, i) => {
    dist[i] += Math.hypot(e.kart.pos.x - prev[i].x, e.kart.pos.y - prev[i].y); prev[i] = { ...e.kart.pos };
    if (i) maxSpeed = Math.max(maxSpeed, e.kart.speed);
    if (i && done[i - 1] === null && e.laps.laps >= 3) done[i - 1] = { t: +(step / 60).toFixed(1), metres: +dist[i].toFixed(0) };
  });
}
console.log(JSON.stringify({ lapLength: +track.length.toFixed(1), threeLaps: +(3 * track.length).toFixed(0), done, maxRivalSpeed: +maxSpeed.toFixed(2) }));
