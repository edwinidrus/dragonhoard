export function number(value, min = 0, exclusive = false) {
  if (!Number.isFinite(value) || (exclusive ? value <= min : value < min)) throw new TypeError('Invalid finite number');
  return value;
}
export function validateTone(t) {
  if (!t || !['sine', 'triangle', 'square', 'sawtooth', 'noise'].includes(t.wave)) throw new TypeError('Invalid wave');
  number(t.frequency, 0, true); number(t.gain); number(t.duration, 0, true);
  if (t.endFrequency !== undefined) number(t.endFrequency, 0, true);
  for (const key of ['attack', 'release']) if (t[key] !== undefined) number(t[key]);
  if (t.filter) {
    if (!['lowpass', 'highpass', 'bandpass', 'notch', 'allpass', 'peaking', 'lowshelf', 'highshelf'].includes(t.filter.type)) throw new TypeError('Invalid filter');
    number(t.filter.frequency, 0, true); number(t.filter.Q);
  }
  if (t.echo) { number(t.echo.delay, 0, true); number(t.echo.gain); if (t.echo.gain >= 1 || t.echo.delay > 10) throw new TypeError('Unsafe echo'); }
}
export function createSequencer(pattern, { bpm, swing = 0, start = 0, lookAhead = .1 }) {
  number(bpm, 0, true); number(swing); number(start); number(lookAhead, 0, true);
  if (swing >= .5 || !pattern || !Array.isArray(pattern.notes)) throw new TypeError('Invalid pattern/swing');
  number(pattern.beats, 0, true);
  let previous = -1;
  for (const n of pattern.notes) {
    validateTone(n); number(n.beat);
    if (n.beat < previous || n.beat >= pattern.beats) throw new TypeError('Invalid beat/order');
    previous = n.beat;
  }
  return { pattern: structuredClone(pattern), bpm, swing, start, lookAhead, until: start };
}
export function schedule(state, now) {
  number(now);
  const { pattern, bpm, swing, start, lookAhead, until } = state;
  const low = Math.max(now, until), high = now + lookAhead, seconds = 60 / bpm;
  const loop = pattern.beats * seconds, notes = [];
  if (high > low) for (const n of pattern.notes) {
    const offset = start + (n.beat + (n.beat % 1 === .5 ? swing : 0)) * seconds;
    const first = Math.max(0, Math.ceil((low - offset) / loop));
    for (let cycle = first; ; cycle++) {
      const at = offset + cycle * loop;
      if (at >= high) break;
      if (at >= low) { const { beat, ...tone } = structuredClone(n); notes.push({ ...tone, at, duration: n.duration * seconds }); }
    }
  }
  notes.sort((a, b) => a.at - b.at);
  return { state: { ...state, until: Math.max(until, high) }, notes };
}
