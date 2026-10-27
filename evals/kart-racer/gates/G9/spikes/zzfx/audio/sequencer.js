const waves = ['sine','triangle','square','sawtooth','noise'];
const filters = ['lowpass','highpass','bandpass','lowshelf','highshelf','peaking','notch','allpass'];
const finite = (v, min=0, strict=false) => {
  if (!Number.isFinite(v) || (strict ? v<=min : v<min)) throw new RangeError('Invalid finite value');
};
export function validateTone(n, timed=true) {
  if (!n || !waves.includes(n.wave)) throw new TypeError('Invalid wave');
  finite(n.frequency,0,true); finite(n.gain);
  if (timed) finite(n.duration,0,true);
  if (n.endFrequency!==undefined) finite(n.endFrequency,0,true);
  for (const k of ['attack','release']) if(n[k]!==undefined) finite(n[k]);
  if(n.filter){if(!filters.includes(n.filter.type))throw new TypeError('Invalid filter');finite(n.filter.frequency,0,true);finite(n.filter.Q);}
  if(n.echo){finite(n.echo.delay,0,true);finite(n.echo.gain);if(n.echo.gain>=1)throw new RangeError('Unsafe echo gain');if(n.echo.delay>10)throw new RangeError('Echo delay exceeds 10s');}
}
export function createSequencer(pattern, {bpm,swing=0,start=0,lookAhead=.1}={}) {
  finite(bpm,0,true); finite(swing);if(swing>=.5)throw new RangeError('Invalid swing');
  finite(start);finite(lookAhead,0,true);finite(pattern.beats,0,true);
  if(!Array.isArray(pattern.notes))throw new TypeError('Invalid notes');
  let last=-1;
  for(const n of pattern.notes){validateTone(n);finite(n.beat);if(n.beat>=pattern.beats||n.beat<last)throw new RangeError('Invalid beat/order');last=n.beat;}
  return {pattern:structuredClone(pattern),bpm,swing,start,lookAhead,until:start};
}
export function schedule(state, now) {
  finite(now);
  const {pattern,bpm,swing,start,lookAhead}=state, spb=60/bpm, period=pattern.beats*spb;
  const low=Math.max(now,state.until), end=now+lookAhead, notes=[];
  // ponytail: O(pattern notes + emitted notes), independent of hidden-gap length.
  for(const note of pattern.notes){
    const offset=note.beat*spb+(note.beat%1===.5?swing*spb:0);
    for(let k=Math.max(0,Math.ceil((low-start-offset)/period));;k++){
      const at=start+k*period+offset;
      if(at>=end)break;
      if(at>=low){const {beat,duration,...tone}=note;notes.push({...structuredClone(tone),at,duration:duration*spb});}
    }
  }
  notes.sort((a,b)=>a.at-b.at);
  return {state:{...state,until:Math.max(state.until,end)},notes};
}
