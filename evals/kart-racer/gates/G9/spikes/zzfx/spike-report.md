# Option (b): ZzFX 1.4.0 pure-generator hybrid

Verdict: WORKS for bounded spike criterion, not task delivery or musical approval.
Actual model: openai/gpt-6.1-sol (GPT-6.1 Sol).
Worktree: /tmp/opencode/dragonhoard-m9-zzfx; branch spike/m9-zzfx; no commit/merge.

## Provenance and dependency

Parent supplied verified pre-audio runtime fingerprint: 41 files,
ea1bd00e9e1cdbdbc1b5aa06ed25fffccdca7604ebf703888a443f5f4e2613ea.
Parent supplied pre-audio level-9 gzip total 144068 = 143697 JS + 371 HTML,
Node 22.22.2, npm 10.9.7, Vite 8.3.4. Not remeasured after adding audio.
Hook ran before reading pack; full exact pack read. TDD and verification skills loaded.

ZzFX 1.4.0 MIT, Frank Force copyright 2019. Source:
https://unpkg.com/zzfx@1.4.0/ZzFX.js (raw copy in spike-zzfx-upstream.log).
Vendored only pure buildSamples function and sampleRate, shortened formatting/comments,
retaining full MIT license. No npm dependency, manifest/lock changes, or installation.
node_modules is read-only-use symlink to existing project dependencies; nothing installed.

Library genuinely generates PCM for both reachable scheduled notes, all supported wave shapes,
and continuous noise. It does NOT supply scheduling, engine lifecycle, exact filter/Q/echo,
master mute, or reusable continuous oscillator. Those are custom native Web Audio;
pitch glide uses native playbackRate ramp. Pure sequencer also custom.
ZzFXM not used: whole-song arrays/untimed playback provide no benefit to this contract.
No songs, presets, game effects, recorded samples, or sample assets used.

## Commands and real outputs

`node spike-check.mjs > spike-red.log 2>&1` -> exit 1 before implementation:
`Error [ERR_MODULE_NOT_FOUND]: Cannot find module '.../src/audio/sequencer.js'`.

`node spike-check.mjs > spike-check.log 2>&1` -> exit 0:
```text
# tests 3
# pass 3
# fail 0
vite v8.3.4 building client environment for production...
✓ 47 modules transformed.
✓ built in 361ms
{"files":[{"file":"dist/assets/index-CQL1dEzz.js","gzip":145971},{"file":"dist/index.html","gzip":371}],"total":146342,"delta":2274}
CHROMIUM {"probe":{"contexts":1,"oscillators":1,"buffers":2,"starts":[[0.1],[100.1],[0.011609977324263039]],"stops":[[0.30000000000000004],[100.19999999999999],[0.011609977324263039],[0.011609977324263039],[0.011609977324263039]],"closed":1},"result":{"done":true,"at":0.1,"keyCount":7}}
PASS sequencing + reachable ZzFX generator + gesture lifecycle + gzip delta <30000; no browser errors
```
Vite's existing >500 kB chunk warning remains; full raw output in spike-check.log.

`npm test > spike-suite.log 2>&1` -> exit 0:
```text
# tests 312
# pass 312
# fail 0
# duration_ms 12533.44899
```

Additional `node --input-type=module` characterization (source read, context expression replaced
with null, then data-URL import and assert.deepEqual for shape indices 0/1/2/4/5):
```text
PASS upstream 1.4.0 sample equality: sine triangle saw noise square; upstream context expression replaced with null ONLY for Node characterization (not browser evidence)
PASS port 5272 free after own server cleanup
```
No Node fake adapter evidence claimed. Chromium evidence is actual production-build browser.
Port 5272 bind checked free before strict-port preview spawn; finally closes browser and
terminates/awaits only its own server. Post-run bind confirms cleanup.

## Coverage, cost, and limits

Pure assertions: explicit-time lower/upper edges, repeated/overlapping windows, polyphony/rests,
two wraps, swing, fresh 60/120/160 BPM, immutable input, invalid values, 1e9-second hidden gap.
Hidden gap computation arithmetic O(pattern notes + output), no sequencing sleeps/timers.
Browser constructor wrapped before scripts: zero contexts before Z; one after Z; source start
times exact; two setContinuous calls create only one oscillator; queued+sounding sources stopped;
all seven engine methods exercised, context closed, zero console errors/pageerrors/autoplay warnings.

Files: sequencer.js 38 lines; engine.js 68; zzfx-generator.js 50;
main.js +15 (282 total); sequencer.test.js 40; spike-check.mjs 52.
Custom runtime ~121 lines plus 50-line licensed generator; tests/check 92 lines.
No new npm dependencies. Runtime moving parts: PCM generator, native voice graphs, pure sequencer.
Real full-app gzip delta +2274 bytes; includes reachable scheduling and key exercise, not unused import.

Extra delivery scope required: src/audio/zzfx-generator.js and upstream license vendoring.
main.js key binding is spike-only; actual task explicitly forbids entry-point edits.
Owner amendment required before any vendor adoption; spike is NOT delivered M9-T01.

Risks: generator allocates O(sampleRate * note duration) PCM synchronously per scheduled note;
no cache. Native envelope adds ZzFX's fixed minimum 9-sample onset. Pitch-up glide loops a
finite PCM buffer, risking seam clicks; continuous updates abrupt, not smoothed. No listening
approval or offline spectrum/tail measurements. Browser proves lifecycle, not every filter mode
or perceptual quality. No full smoke suite run; criterion browser and full Node suite did run.
No main task/status/journal/digest changes and no task.done event.
