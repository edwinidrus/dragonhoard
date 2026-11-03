import { Context } from 'tone/build/esm/core/context/Context.js';
import { setContext } from 'tone/build/esm/core/Global.js';
import { Gain } from 'tone/build/esm/core/context/Gain.js';
import { Oscillator } from 'tone/build/esm/source/oscillator/Oscillator.js';
import { Noise } from 'tone/build/esm/source/Noise.js';
import { Filter } from 'tone/build/esm/component/filter/Filter.js';
import { FeedbackDelay } from 'tone/build/esm/effect/FeedbackDelay.js';

// ponytail: cost-first throwaway adapter; validation/lifecycle checks deferred
// until the minimal reachable deep-import build clears the bundle budget.
export function createEngine() {
  const context = new Context({ lookAhead: 0 });
  setContext(context);
  const master = new Gain({ context, gain: 1 }).connect(context.rawContext.destination);
  const active = new Set();
  const continuous = new Map();
  const now = () => context.immediate();
  function voice(tone, at) {
    const source = tone.wave === 'noise'
      ? new Noise({ context, type: 'white' })
      : new Oscillator({ context, type: tone.wave, frequency: tone.frequency });
    const envelope = new Gain({ context, gain: 0 });
    const nodes = [source, envelope];
    let output = source;
    if (tone.filter) {
      const filter = new Filter({ ...tone.filter, context });
      output.connect(filter);
      output = filter;
      nodes.push(filter);
    }
    output.connect(envelope);
    envelope.connect(master);
    if (tone.echo) {
      const echo = new FeedbackDelay({ context, delayTime: tone.echo.delay, feedback: tone.echo.gain, wet: 1 });
      envelope.connect(echo);
      echo.connect(master);
      nodes.push(echo);
    }
    envelope.gain.setValueAtTime(0, at);
    envelope.gain.linearRampToValueAtTime(tone.gain, at + (tone.attack ?? 0.005));
    if (tone.endFrequency && source.frequency) source.frequency.linearRampToValueAtTime(tone.endFrequency, at + tone.duration);
    source.start(at);
    const entry = { source, envelope, stop() { source.stop(now()); nodes.forEach(n => n.dispose()); active.delete(entry); } };
    active.add(entry);
    return entry;
  }
  return {
    now,
    schedule(notes) {
      for (const tone of notes) {
        const entry = voice(tone, tone.at);
        const end = tone.at + tone.duration;
        entry.envelope.gain.setValueAtTime(tone.gain, Math.max(tone.at, end - (tone.release ?? 0.01)));
        entry.envelope.gain.linearRampToValueAtTime(0, end);
        entry.source.stop(end);
      }
    },
    setContinuous(id, tone) {
      const old = continuous.get(id);
      if (!tone) { old?.stop(); continuous.delete(id); return; }
      if (old) {
        if (old.source.frequency) old.source.frequency.value = tone.frequency;
        old.envelope.gain.value = tone.gain;
      } else continuous.set(id, voice(tone, now()));
    },
    setMuted(muted) { master.gain.value = muted ? 0 : 1; },
    clear() { [...active].forEach(v => v.stop()); continuous.clear(); },
    resume() { return context.resume(); },
    dispose() { this.clear(); master.dispose(); context.dispose(); return context.close(); },
  };
}
