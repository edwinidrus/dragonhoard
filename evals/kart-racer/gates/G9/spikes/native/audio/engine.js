import { number, validateTone } from './sequencer.js';

export function createEngine() {
  const ctx = new AudioContext();
  const master = ctx.createGain(); master.connect(ctx.destination);
  const active = new Set(), voices = new Map();
  let disposed = false, noise;
  const live = () => { if (disposed) throw new Error('Engine disposed'); };
  function make(t, at, continuous = false) {
    const source = t.wave === 'noise' ? ctx.createBufferSource() : ctx.createOscillator();
    if (t.wave === 'noise') {
      if (!noise) { noise = ctx.createBuffer(1, ctx.sampleRate, ctx.sampleRate); const data = noise.getChannelData(0); for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1; }
      source.buffer = noise; source.loop = true;
    } else source.type = t.wave;
    const gain = ctx.createGain(), filter = ctx.createBiquadFilter(), delay = ctx.createDelay(10), wet = ctx.createGain();
    source.connect(gain); gain.connect(filter); filter.connect(master); filter.connect(delay); delay.connect(wet); wet.connect(master);
    const nodes = [source, gain, filter, delay, wet];
    let timer;
    const record = { source, wave: t.wave, update, stop, cleanup };
    function cleanup() { clearTimeout(timer); for (const n of nodes) n.disconnect(); active.delete(record); }
    function stop() { try { source.stop(ctx.currentTime); } catch {} cleanup(); }
    function update(t, at) {
      const pitch = t.wave === 'noise' ? source.playbackRate : source.frequency, scale = t.wave === 'noise' ? 440 : 1;
      if (t.wave !== 'noise') source.type = t.wave;
      pitch.cancelScheduledValues(at); pitch.setValueAtTime(t.frequency / scale, at); if (t.endFrequency !== undefined) pitch.linearRampToValueAtTime(t.endFrequency / scale, at + t.duration);
      filter.type = t.filter?.type ?? 'lowpass'; filter.frequency.setValueAtTime(t.filter?.frequency ?? ctx.sampleRate / 2, at); filter.Q.setValueAtTime(t.filter?.Q ?? 0, at);
      delay.delayTime.setValueAtTime(t.echo?.delay ?? .1, at); wet.gain.setValueAtTime(t.echo?.gain ?? 0, at);
      gain.gain.cancelScheduledValues(at);
      if (continuous) gain.gain.setValueAtTime(t.gain, at);
      else {
        const attack = Math.min(t.attack ?? .005, t.duration / 2), release = Math.min(t.release ?? .02, t.duration / 2);
        gain.gain.setValueAtTime(0, at); gain.gain.linearRampToValueAtTime(t.gain, at + attack);
        gain.gain.setValueAtTime(t.gain, at + t.duration - release); gain.gain.linearRampToValueAtTime(0, at + t.duration);
      }
    }
    update(t, at); active.add(record);
    source.onended = () => { timer = setTimeout(cleanup, 1000 * (t.echo?.delay ?? 0)); };
    source.start(at); if (!continuous) source.stop(at + t.duration);
    return record;
  }
  return {
    now: () => ctx.currentTime,
    schedule(notes) { live(); if (!Array.isArray(notes)) throw new TypeError('Invalid events'); for (const t of notes) { validateTone(t); number(t.at); } for (const t of notes) make(t, t.at); },
    setContinuous(id, tone) {
      live(); if (typeof id !== 'string' || !id) throw new TypeError('Invalid voice id');
      const old = voices.get(id);
      if (tone === null) { old?.stop(); voices.delete(id); return; }
      const t = { ...tone, duration: tone.duration ?? 1 }; validateTone(t);
      if (old && (old.wave === 'noise') === (t.wave === 'noise')) old.update(t, ctx.currentTime);
      else { old?.stop(); voices.set(id, make(t, ctx.currentTime, true)); }
    },
    setMuted(muted) { live(); if (typeof muted !== 'boolean') throw new TypeError('Invalid mute'); master.gain.setValueAtTime(muted ? 0 : 1, ctx.currentTime); },
    clear() { for (const r of [...active]) r.stop(); voices.clear(); },
    resume() { live(); return ctx.resume(); },
    dispose() { if (disposed) return Promise.resolve(); this.clear(); master.disconnect(); disposed = true; noise = null; return ctx.close(); },
  };
}
