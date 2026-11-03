import { ZZFX } from './zzfx-generator.js';
import { validateTone } from './sequencer.js';
const shapes={sine:0,triangle:1,sawtooth:2,noise:4,square:5};
export function createEngine(){
  const c=new AudioContext(),master=c.createGain(),active=new Set(),continuous=new Map();
  master.connect(c.destination);let disposed=false;
  const live=()=>{if(disposed)throw new Error('Disposed engine');};
  const samples=(tone,duration)=>{
    // Library supplies actual scheduled waveform samples; no song or preset data.
    const data=ZZFX.buildSamples(1,0,tone.frequency,0,Math.max(0,duration-9/44100),0,shapes[tone.wave]);
    const b=c.createBuffer(1,Math.max(1,data.length),44100);b.getChannelData(0).set(data);return b;
  };
  const route=source=>{
    const amp=c.createGain(),filter=c.createBiquadFilter(),delay=c.createDelay(10),wet=c.createGain();
    source.connect(amp);amp.connect(filter);filter.connect(master);filter.connect(delay);delay.connect(wet);wet.connect(master);
    const v={source,amp,filter,delay,wet,nodes:[source,amp,filter,delay,wet],timer:null};active.add(v);return v;
  };
  const stop=v=>{
    if(!active.has(v))return;
    clearTimeout(v.timer);v.source.onended=null;
    try{v.source.stop(c.currentTime);}catch{}
    v.nodes.forEach(n=>n.disconnect());active.delete(v);
  };
  const options=(v,n,at)=>{
    v.filter.type=n.filter?.type??'allpass';
    v.filter.frequency.setValueAtTime(n.filter?.frequency??1000,at);
    v.filter.Q.setValueAtTime(n.filter?.Q??1,at);
    v.delay.delayTime.setValueAtTime(n.echo?.delay??.1,at);
    v.wet.gain.setValueAtTime(n.echo?.gain??0,at);
  };
  return {
    now:()=>c.currentTime,
    schedule(notes){live();for(const n of notes){validateTone(n);if(!Number.isFinite(n.at)||n.at<0)throw new RangeError('Invalid at');}
      for(const n of notes){
        if(n.at<c.currentTime)continue;
        const src=c.createBufferSource();src.buffer=samples(n,n.duration);src.loop=true;
        const v=route(src),end=n.at+n.duration;options(v,n,n.at);
        const attack=Math.min(n.attack??.005,n.duration/2),release=Math.min(n.release??.02,n.duration/2);
        v.amp.gain.setValueAtTime(0,n.at);v.amp.gain.linearRampToValueAtTime(n.gain,n.at+attack);
        v.amp.gain.setValueAtTime(n.gain,end-release);v.amp.gain.linearRampToValueAtTime(0,end);
        src.playbackRate.setValueAtTime(1,n.at);
        if(n.endFrequency!==undefined)src.playbackRate.linearRampToValueAtTime(n.endFrequency/n.frequency,end);
        src.onended=()=>{
          // Timer only releases native graph after tail; never sequences notes.
          v.timer=setTimeout(()=>{v.nodes.forEach(n=>n.disconnect());active.delete(v);},(n.echo?.delay??0)*1000);
        };
        src.start(n.at);src.stop(end);
      }
    },
    setContinuous(id,tone){live();if(typeof id!=='string'||!id)throw new TypeError('Invalid voice id');
      if(tone===null){const v=continuous.get(id);if(v)stop(v);continuous.delete(id);return;}
      validateTone(tone,false);let v=continuous.get(id);
      if(v && v.noise!==(tone.wave==='noise')){stop(v);continuous.delete(id);v=null;}
      if(!v){if(continuous.size>=32)throw new RangeError('32 voice limit');
        const src=tone.wave==='noise'?c.createBufferSource():c.createOscillator();
        if(tone.wave==='noise'){src.buffer=samples(tone,1);src.loop=true;}
        v=route(src);v.noise=tone.wave==='noise';v.baseFrequency=tone.frequency;continuous.set(id,v);src.start(c.currentTime);
      }
      if(!v.noise){v.source.type=tone.wave;v.source.frequency.setValueAtTime(tone.frequency,c.currentTime);}
      else v.source.playbackRate.setValueAtTime(tone.frequency/v.baseFrequency,c.currentTime);
      v.amp.gain.setValueAtTime(tone.gain,c.currentTime);options(v,tone,c.currentTime);
    },
    setMuted(muted){live();master.gain.setValueAtTime(muted?0:1,c.currentTime);},
    clear(){live();for(const v of [...active])stop(v);continuous.clear();},
    resume(){live();return c.resume();},
    dispose(){if(disposed)return Promise.resolve();for(const v of [...active])stop(v);continuous.clear();master.disconnect();disposed=true;return c.close();}
  };
}
