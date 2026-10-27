# M10-T03 spike, option (b): billboard planes + code-generated soft CanvasTexture

Throwaway spike, evidence only, never merged. Branch `spike/m10-clouds-billboard` at de6750a.

## Verdict: FAILS (on the success criterion's 300-frame floor)

The criterion's own command fails:

`node spike-check.mjs` -> `FAIL move sample >= 300 frames (242 in 10.0s)` ... `SPIKE-CHECK FAIL` (exit 1)

Every other clause holds (draw calls per pose > 0, gzip bytes, 0 console/page errors, 0 HTTP image
requests, exactly 1 live WebGL context, exactly 1 document canvas, 9 PNGs written). The frame-rate
half fails. Attribution below is decisive: the billboard puffs are nearly free; the **mandated
WebGL merged cloud sea** is what blows the budget.

## Commands and shortest decisive output

| Command | Decisive line | Exit |
|---|---|---|
| `node spike-check.mjs` | `build sample {"frames":242,"seconds":10.03}` -> `FAIL move sample >= 300 frames` | 1 |
| `npm test` | `# pass 403 / # fail 0` | 0 |
| `npm run smoke` | `1 failed / 34 passed`; the failure is M8-T17 (`frames:235`) | 1 |
| `node spike-probe.mjs --sea=webgl` | `fourModel fps 23.322, ratio 0.99794` | 1 |
| `node spike-probe.mjs --sea=backdrop` | `fourModel fps 34.011, ratio 1.00261` | 0 |
| master baseline (my edits stashed) | `M8-T17 moving sample {"frames":354}` -> test **passes** | 0 |

Only the M8-T17 test fails in `npm run smoke`; the other 34 (incl. both review.spec draw-call tests
and all audio/M9 tests) pass. `npm test` is unchanged green (403/403).

## Draw calls per pose (real production build, `window.__hoard.drawCalls`)

| pose | calls | | pose | calls |
|---|---|---|---|---|
| m10-start | 102 | | m10-s-bend | 107 |
| m10-jump-1 | 73 | | m10-landmark | 45 |
| m10-bridge | 94 | | m10-sea (low, downward) | 43 |
| m10-hairpin | 49 | | m10-ember-start | 68 |
| m10-jump-2 | 58 | | | |

Clouds add 3 draw calls (2 puff InstancedMesh layers + 1 sea).

## Emitted bytes (canonical `cat <file> | gzip -9 | wc -c`)

| file | bytes | gzip -9 bytes |
|---|---|---|
| assets/index-BDzkOhP1.js | 601324 | 155356 |
| index.html | 518 | 382 |

## Four-model sample: frames / fps / ratio

| run | four-model | cinder-only | ratio | floor |
|---|---|---|---|---|
| unchanged `npm run smoke` (puffs + WebGL sea) | 235 f, 23.388 fps | 235 f, 23.431 fps | 0.9982 | **FAIL** |
| master baseline, no clouds (stashed) | 354 f, 35.330 fps | 355 f, 35.401 fps | 0.9980 | pass |
| `spike-probe --sea=webgl` | 234 f, 23.322 fps | 234 f, 23.370 fps | 0.99794 | FAIL |
| `spike-probe --sea=backdrop` (puffs only in WebGL, sea painted into T02's backdrop) | 341 f, 34.011 fps | 340 f, 33.923 fps | 1.00261 | pass |

Cross-check: the unchanged smoke's own number (23.388 fps) matches `--sea=webgl` (23.322 fps) to
within 0.28%. The ratio is ~1.00 in every run (clouds cost the baseline and the four-model run the
same), so the failure is the absolute frame-rate floor, not the ratio.

## Visual check (I read the PNGs directly)

- **Cloud sea: appears.** `evidence/m10-sea.png` shows 2-3 tonal bands (a blue-purple band and lighter
  mauve bands) filling the lower two thirds; `evidence/m10-start.png` shows pale lavender sea wedges
  either side of the road. It reads as flat tonal bands, not billowy cloud tops.
- **Warm on the sun side: not confirmed.** In the sampled poses the sea bands read uniformly
  cool/mauve; no distinct sun-side warm lobe is visible (the sun is +x, and the sampled bearing does
  not put the warm half clearly in frame). The mix is `0.15 + 0.85 * max(0, dir.SUN_DIRECTION)`, so
  any away-from-sun bearing stays cool.
- **Puffs: visible, soft edges, but they read as rings/halos against the bright horizon.** The warm
  core (`#f6b38a`) is nearly the luminance of the dusk orange sky, so an opaque puff centre vanishes
  into the sky while its cool semi-transparent mid-band darkens it — a ring. Against the darker upper
  sky and against the sea the same puff reads as a proper filled soft cloud (`evidence/m10-start.png`
  upper right, `evidence/m10-sea.png` centre).

## Deviations from the brief

1. `src/render/scene.js` was **not** edited: it already returns `camera` (the brief's summary omitted
   it). I added `camera` to main.js's destructure instead, and manage the cloud group in main.js like
   scenery (brief item 3).
2. The generated `CanvasTexture` is released by overriding `material.dispose` (calls `texture.dispose`
   then the original), because `dispose.js`'s `disposeTree` disposes materials but not their maps and
   `dispose.js` was out of scope.
3. `spike-check.mjs` asserts the 300-frame floor on the built page itself, but the **ratio** cannot be
   measured on a bundled build (there is no `/src/logic/racers.js` module path for the baseline route
   interception), so the ratio is evidenced by `npm run smoke` and `spike-probe.mjs` on the dev server.
4. `spike-check.mjs`'s static server took port 5173 (it was free); the port is recorded in
   `evidence/result.json`.
5. Added one extra Lantern pose, `m10-sea`, as the brief's "low downward pose that shows the cloud
   sea"; the other 8 poses are copied verbatim from `review.spec.js`.
6. The backdrop-sea variant lives in `sky.js` behind a default-off flag (`setBackdropSea`), activated
   by `?sea=backdrop`, so every existing render stays byte-identical (unit tests unchanged).
7. `frustumCulled = false` on the puff InstancedMeshes — a 1x1 plane's own bounds would cull them.

## Deliberately left out

- The optional render-only fall drop (brief says not required).
- Per-instance puff colour/tint, any second blob texture, fog/opacity tuning.
- Backdrop-sea visual tuning (it was only needed to prove the frame-rate attribution).

## Risks / caveats

- All frame rates come from **headless chromium software rasterisation (SwiftShader)**, so absolute
  fps is environment-bound; the same caveat already applies to the unchanged smoke's 300-frame floor.
  The drop is large and reproducible (35.3 -> 23.3 fps, seen identically in the smoke suite and in
  `spike-probe --sea=webgl`), so it is a real measurable failure here, but a real GPU would very
  likely narrow the sea mesh's cost. The billboard-puff result (34.0 fps vs 35.3 master) is the part
  least sensitive to that caveat.
- A sibling spike measured option (a) with the same cloud sea; I did not read or touch it (forbidden),
  and I make no cross-option claim beyond what is measured here.

## Evidence (absolute paths)

- /home/edwinidrus/hobbys/dragonhoard_test-spike-m10-clouds-billboard/evidence/result.json
- /home/edwinidrus/hobbys/dragonhoard_test-spike-m10-clouds-billboard/evidence/m10-start.png
- .../evidence/m10-jump-1.png, m10-bridge.png, m10-hairpin.png, m10-jump-2.png, m10-s-bend.png,
  m10-landmark.png, m10-sea.png, m10-ember-start.png

## git status --short / git diff --stat (this worktree)

```
 M src/main.js
 M src/render/sky.js
?? evidence/  ?? node_modules  ?? spike-check.mjs  ?? spike-probe.mjs  ?? src/render/clouds.js
 src/main.js       | 10 +++++++++-
 src/render/sky.js | 21 +++++++++++++++++++++
 2 files changed, 30 insertions(+), 1 deletion(-)
```

(`node_modules` is the pre-existing symlink; nothing was committed.)
