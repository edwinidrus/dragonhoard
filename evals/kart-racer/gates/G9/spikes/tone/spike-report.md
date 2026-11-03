# Option (c): Tone.js 15.1.22 adapter — FAILS bundle criterion

Actual model: openai/gpt-6.1-sol (high). Worktree: `/tmp/opencode/dragonhoard-m9-tone`.
Parent-supplied verified pre-audio baseline: 144068 gzip bytes (JS 143697 + HTML 371),
41 runtime files SHA ea1bd00e9e1cdbdbc1b5aa06ed25fffccdca7604ebf703888a443f5f4e2613ea.
This spike did not reproduce or overwrite that baseline. Node v22.22.2; npm 10.9.7; Vite 8.3.4.

Install command: `npm install --save-exact tone@15.1.22 --ignore-scripts --no-audit --no-fund --cache .npm-cache`.
Raw output: `spike-install.log` (added 26 packages in 6s). Install/cache/node_modules were worktree-local;
temporary `.npm-cache` removed. No main-checkout or workflow files changed; no commit/merge.
Licences from installed package metadata: tone 15.1.22 MIT; standardized-audio-context 25.3.77 MIT;
tslib 2.8.1 0BSD. Tone licence: node_modules/tone/LICENSE.md, copyright 2014–2020 Yotam Mann.

Test-first command: `node spike-check.mjs` → exit 1, ERR_MODULE_NOT_FOUND for missing engine.js;
full raw output: `spike-red.log`. Final verification: `node spike-check.mjs` → exit 1;
full raw stdout/stderr: `spike-cost.log`. The script runs the actual application Vite build,
recursively sums **all** dist files with gzipSync level 9, then asserts strict delta <30000.
Raw measured output: `{"baseline":144068,"total":194983,"delta":50915}`;
JS dist/assets/index-DD9qGXlQ.js = 194612, HTML = 371 gzip bytes.
Decisive raw line: `AssertionError [ERR_ASSERTION]: BUDGET FAIL: delta 50915 >= 30000`.

Static deep imports avoid the known root-export module-scope getContext path; no unused library import.
Reachable KeyT handler calls sync createEngine, resume, now, schedule with oscillator/noise/filter/echo,
setContinuous twice on same id, setMuted, clear, dispose. Seven deep modules and Tone's transitive graph
remain reachable (856 modules transformed). No API conversion to asynchronous createEngine.
Stopped at measured cost disqualifier as authorized: no sequencer, Node contract fixtures, Chromium,
constructor/buffer instrumentation, playback/listening, autoplay, cancellation or lifecycle claims.
Adapter intentionally incomplete: no input validation or finished-note cleanup; browser correctness unknown.
This disproves this direct Tone-class adapter route, not every hypothetical hybrid/library fork.
Cost: 71 engine lines +18 entry-point lines, 19 check lines; dependency plus two transitive dependencies.
Delivery would require explicit package.json/package-lock.json scope amendment; spike install grants none.
