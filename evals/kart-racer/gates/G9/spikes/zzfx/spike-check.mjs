import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { gzipSync } from 'node:zlib';
import net from 'node:net';
import { chromium } from '@playwright/test';
const run = (command,args) => {
  const r=spawnSync(command,args,{encoding:'utf8'});
  process.stdout.write(r.stdout || ''); process.stderr.write(r.stderr || '');
  assert.equal(r.status,0,`${command} failed`);
};
run('node',['--test','test/logic/sequencer.test.js']);
run('node',['node_modules/vite/bin/vite.js','build']);
const walk=d=>readdirSync(d,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(`${d}/${e.name}`):[`${d}/${e.name}`]);
const files=walk('dist').map(file=>({file,gzip:gzipSync(readFileSync(file),{level:9}).length}));
const total=files.reduce((a,b)=>a+b.gzip,0), delta=total-144068;
console.log(JSON.stringify({files,total,delta})); assert(delta<30000);
await new Promise((resolve,reject)=>{ const s=net.createServer(); s.once('error',reject); s.listen(5272,'127.0.0.1',()=>s.close(resolve)); });
const server=spawn(process.execPath,['node_modules/vite/bin/vite.js','preview','--host','127.0.0.1','--port','5272','--strictPort'],{stdio:['ignore','pipe','pipe']});
let browser;
try {
  await new Promise((resolve,reject)=>{server.stdout.on('data',d=>{process.stdout.write(d); if(String(d).includes('5272'))resolve();});server.stderr.on('data',d=>process.stderr.write(d));server.once('exit',c=>reject(Error(`server exit ${c}`)));});
  browser=await chromium.launch({headless:true,args:['--no-sandbox','--enable-unsafe-swiftshader']});
  const page=await browser.newPage(); const errors=[];
  page.on('pageerror',e=>errors.push(String(e)));
  page.on('console',m=>{if(m.type()==='error'||/autoplay|not allowed to start/i.test(m.text()))errors.push(m.text());});
  await page.addInitScript(()=>{
    window.__audioProbe={contexts:0,oscillators:0,buffers:0,starts:[],stops:[],closed:0};
    const Native=window.AudioContext;
    window.AudioContext=class extends Native {
      constructor(...args){super(...args); const p=window.__audioProbe; p.contexts++;
        for(const name of ['createOscillator','createBufferSource']){const original=this[name].bind(this);this[name]=(...a)=>{p[name==='createOscillator'?'oscillators':'buffers']++;const n=original(...a);for(const action of ['start','stop']){const f=n[action].bind(n);n[action]=(...a)=>{p[action==='start'?'starts':'stops'].push(a);return f(...a);};}return n;};}
        const close=this.close.bind(this);this.close=()=>{p.closed++;return close();};
      }
    };
  });
  await page.goto('http://127.0.0.1:5272/');
  assert.equal(await page.evaluate(()=>window.__audioProbe.contexts),0);
  await page.keyboard.press('KeyZ');
  await page.waitForFunction(()=>window.__spike?.done);
  const evidence=await page.evaluate(()=>({probe:window.__audioProbe,result:window.__spike}));
  assert.equal(evidence.probe.contexts,1);
  assert.equal(evidence.probe.oscillators,1);
  assert.equal(evidence.probe.buffers,2);
  assert.equal(evidence.probe.closed,1);
  assert.equal(evidence.result.keyCount,7);
  assert(evidence.probe.starts.some(a=>a[0]===evidence.result.at));
  assert.equal(evidence.probe.stops.length,5); // 2 scheduled ends + clear cancels all 3 sources.
  assert.deepEqual(errors,[]);
  console.log('CHROMIUM '+JSON.stringify(evidence));
  console.log('PASS sequencing + reachable ZzFX generator + gesture lifecycle + gzip delta <30000; no browser errors');
} finally {await browser?.close();server.kill('SIGTERM');await new Promise(r=>server.exitCode!==null?r():server.once('exit',r));}
