# Spike M10-T03 option (a): instanced low-poly sphere cloud clusters — evidence report

Worktree (throwaway, never merged): `/home/edwinidrus/hobbys/dragonhoard_test-spike-m10-clouds-instanced`
Branch `spike/m10-clouds-instanced` at de6750a.

## Option
(a) Puffs as two `InstancedMesh` layers of faceted low-poly spheres (per-face normals, per-vertex
palette colours baked from `SUN_DIRECTION`), plus the shared cloud sea as ONE merged
`BufferGeometry` (3 tonal radial discs, 1 draw call) with per-vertex warm/cool mixing about
`SUN_DIRECTION`. Ember plans nothing (`cloudPlan` returns null).

## Commands and their decisive output
`node spike-check.mjs` -> exit 0, last line `PASS`.
```
draw calls per pose (cloud vs no-clouds):
  m10-start          100  bare  97  extra 3
  m10-jump-1          71  bare  68  extra 3
  m10-bridge          92  bare  89  extra 3
  m10-hairpin         47  bare  44  extra 3
  m10-jump-2          56  bare  53  extra 3
  m10-s-bend         105  bare 102  extra 3
  m10-landmark        43  bare  40  extra 3
  m10-sea             43  bare  40  extra 3
  m10-ember-start     68  bare  68  extra 0
chunks [{"path":"assets/index-DWbUf0yu.js","bytes":603992,"gzip":156252},{"path":"index.html","bytes":518,"gzip":369}]
gzip bytes: js 156252, index.html 369
errors 0 imageRequests 0 contexts all {"canvases":1,"live":1,"main":1}
```
(`extra` = the pose's draw calls with clouds minus the same pose in a `__spikeSea='noclouds'` lane
of the same real build: 3 = sea + both puff layers inside the frustum at every Lantern pose, 0 on
Ember. `gzip` is `cat <file> | gzip -9 | wc -c`.)

`npm test` -> `# pass 403  # fail 0` (unchanged).
`npm run smoke` -> `1 failed / 34 passed (2.1m)`. The one failure is the four-model frame floor:
```
✘ test/smoke/smoke.spec.js:706 › four-model Lantern race advances at least 300 frames in ten seconds
  Expected: >= 300   Received: 235
M8-T17 moving sample {"baseline":false,"frames":235,...,"fps":23.44677581889286,...}
M8-T17 moving sample {"baseline":true,"frames":232,...,"fps":23.143068052595787,...}
M8-T17 baseline comparison {"fourModelFps":23.44677581889286,"cinderOnlyFps":23.143068052595787,"ratio":1.0131230554914696}
```
`node spike-probe.mjs --sea=webgl` (twice, both orders):
```
{"sea":"webgl","fourModel":{"frames":229,"fps":22.86},"cinderOnly":{"frames":235,"fps":23.45},"ratio":0.9749,"framesFloor":false,"ratioOk":true}
{"sea":"webgl","fourModel":{"frames":235,"fps":23.41},"cinderOnly":{"frames":238,"fps":23.73},"ratio":0.9865,"framesFloor":false,"ratioOk":true}
```
`node spike-probe.mjs --sea=backdrop` (sea leaves WebGL, puffs stay; `spike-report.md` §variant):
```
{"sea":"backdrop","fourModel":{"frames":329,"fps":32.82},"cinderOnly":{"frames":334,"fps":33.36},"ratio":0.9839,"framesFloor":true,"ratioOk":true}
```
Extra diagnostic lane, `--sea=noclouds` (no clouds at all, same machine, both orders):
```
{"sea":"noclouds","fourModel":{"frames":340,"fps":33.89},"ratio":0.9580,"framesFloor":true}
{"sea":"noclouds","fourModel":{"frames":356,"fps":35.50},"ratio":0.9870,"framesFloor":true}
```
| four-model sample | frames | fps | ratio | 300 floor |
| --- | --- | --- | --- | --- |
| unchanged smoke, sea in WebGL | 235 | 23.45 | 1.013 | MISSES |
| probe --sea=webgl | 229 / 235 | 22.86 / 23.41 | 0.975 / 0.987 | MISSES |
| probe --sea=backdrop | 329 | 32.82 | 0.984 | meets |
| probe --sea=noclouds | 340 / 356 | 33.89 / 35.50 | 0.958 / 0.987 | meets |

Cross-check: the probe's webgl number (23.41 fps) is within 0.2% of the unchanged smoke's own
23.45 fps. The frame-rate loss is attributable to the merged sea surface, not to the puffs: this
headless build rasterises in software, and 3 sea layers over the whole lower frame cost ~34%
(23.4 vs 35.5 fps) while the two puff InstancedMeshes cost ~6% (backdrop 32.8 vs noclouds 35.5).

## Screenshots (viewed)
`evidence/m10-sea.png`: sea sheet below the horizon to the fogged sky rim, a large faceted puff with
a warm peach sunlit face and a lavender shadow face, a smaller puff, and a hanging island. Clear.
`evidence/m10-jump-1.png` (gap s 50-60): road, a warm lit puff below the road line, distant puffs,
and the pale sea filling below the track. Clear. On the sea sheet itself the warm/cool split is
weak: `#f6b38a` lit vs `#6b5a8e` shadow is only visible near the camera, the fog (`#d98a86`, near
150 / far 480) washes the far field to rose-lavender, which is the brief's own requirement.

## Fidelity notes
A race-clock-dependent note: the unchanged review spec reports m10-start 107 draw calls from the dev
server, this spike's production build 100 at the same pose (kart/drift phase differs); its own
assertions still pass.

## Left out on purpose
No fall-drop (optional), no cloud shadows on the track, no sea edge fade beyond fog, no per-restart
variation (one seeded plan), no changes to `test/**`, `src/logic/**`, `index.html`, `package.json`.
Two extra spike-only switches (`globalThis.__spikeSea`, `'noclouds'` lane) exist for measurement and
must be deleted with the spike; default behaviour is production.

## Evidence
- `/home/edwinidrus/hobbys/dragonhoard_test-spike-m10-clouds-instanced/evidence/{m10-start,m10-jump-1,m10-bridge,m10-hairpin,m10-jump-2,m10-s-bend,m10-landmark,m10-sea,m10-ember-start}.png`
- `/home/edwinidrus/hobbys/dragonhoard_test-spike-m10-clouds-instanced/evidence/result.json`
- `/home/edwinidrus/hobbys/dragonhoard_test-spike-m10-clouds-instanced/evidence/dist/` (built chunks)
- `/tmp/opencode/smoke.log` (unchanged smoke suite output)
- Files touched: `src/render/clouds.js` (new, 212 lines), `src/main.js` (+7), `src/render/sky.js` (+21),
  `spike-check.mjs` (230), `spike-probe.mjs` (114).

## Deviations from the brief
1. Screenshot timing bug found mid-spike (the first PNG set shot the chase camera, because the pose
   was cleared before `page.screenshot`); fixed and everything re-measured. The numbers quoted are
   from the fixed run.
2. The "low downward pose" is an outward look off the hairpin (`s 983, dy 12`, 400 m outward,
   rise -25) rather than straight down: a straight-down pose hid the sea behind the road.
3. `spike-check.mjs` proves cloud geometry is *in frame* by a draw-call delta against a no-clouds
   lane, not by decoding pixels; pixel presence is asserted only by my viewing the PNGs.
4. Extra lanes/conclusions beyond the brief: the `noclouds` probe lane and the reversal re-run.
5. No verdict/recommendation is given; the owner picks.
