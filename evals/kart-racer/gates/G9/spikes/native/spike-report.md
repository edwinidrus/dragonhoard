# M9-T01 option (a): native hand-written Web Audio
Verdict: WORKS for the dispatched spike criterion, not delivery approval.
Model: openai/gpt-6.1-sol (GPT-6.1 Sol).
Worktree: /tmp/opencode/dragonhoard-m9-native; branch spike/m9-native; base 07272a3.
Dependencies added: none. Existing node_modules symlink targets parent's dependencies read-only; no install performed.

## Commands and real evidence
- First successful worktree command: `python3 .dragonhoard/scripts/dragonhoard.py hook`; output read before files/code. Initial external-directory denial resolved by moving session into this worktree.
- RED: `node --test test/logic/sequencer.test.js > spike-red.log 2>&1`; missing sequencer module, 0 pass / 1 fail (expected absent implementation).
- Final criterion: `set -o pipefail; node spike-check.mjs 2>&1 | tee spike-run.log`; exit 0.
- Final decisive output: `PASS native full criterion; total=145899 delta=1831 dependencies=none`.
- Raw outputs: spike-red.log, spike-tests.log, spike-build.log, spike-run.log, spike-server.log.
- Checker runs Node focused tests (5/5), actual Vite production build, recursive ALL-dist gzip level 9, and actual Playwright Chromium 156.0.8078.4 page.
- Runtime tools: Node 22.22.2, Vite 8.3.4; existing @playwright/test 1.64.1.
- Production files: dist/assets/index-Ba6lLTeS.js = 145529 gzip bytes; dist/index.html = 370; total 145899.
- Parent-verified pre-M9 baseline: 144068 (JS 143697 + HTML 371), 41-file SHA256 ea1bd00e9e1cdbdbc1b5aa06ed25fffccdca7604ebf703888a443f5f4e2613ea. Baseline provenance supplied in dispatch/parent journal; not remeasured using modified app.
- Growth 1831 bytes, strictly below 30000. Vite default printed gzip differs from required level-9 measurement; checker uses gzipSync level 9.
- Strict 127.0.0.1:5271 checked free via bind before starting own preview. Own server stopped/awaited in finally. No port 5173 smoke or foreign process touched.
- Browser output: `{"browser":"156.0.8078.4","beforeKey":0,"contexts":1,"exercise":{"done":true,"now":0},"errors":[]}`.

## Scope and checks
- Sequencer: immutable input/state; explicit 60/120/160 BPM; three cycles/two wraps; rests/polyphony; exact half-open edges; overlap/repeat deduplication; swing leaves quarter/bar grid unchanged; billion-second jump preserves phase and takes <100ms with only current-window events.
- Node adapter fixture explicitly FAKE CONTEXT: actual adapter routing, starts/stops, pitch, attack/release, filter/Q, dry+echo shared master mute, named oscillator reuse, generated noise playback-rate pitch, queued/current cancellation, resume/dispose. Import occurs without AudioContext defined.
- Real production app KeyN handler reaches sequencer and adapter, all five waves, now/schedule/resume, same-id continuous update twice, stop, mute/unmute, clear/dispose. Constructor wrapped before scripts: 0 contexts before key, 1 after; no captured console errors/pageerrors/autoplay warnings.
- Files: src/audio/sequencer.js 44 lines; src/audio/engine.js 57; src/main.js +23 (290 total); test/logic/sequencer.test.js 79; spike-check.mjs 35; this report and raw logs.

## Limits and risks
- Throwaway evidence only; no composed score, presets, music, delivered wiring, listening claim, owner musical approval, or full regression/smoke claim. Parent handles baseline regressions independently.
- Browser immediately cancels voices: proves API/gesture behavior, not perceived timbre, envelope quality or acoustic echo audibility. Routing assertions use labeled fake context.
- Native implementation owns node lifecycle; completion tail cleanup uses onended + echo-delay timeout. Clear/dispose cancellation proved; long-running natural completion stress not performed.
- Generated noise repeats a one-second buffer; echo is one feed-forward tap, not feedback. Extreme numerical ranges/dense user patterns and multi-browser coverage not explored.
- Existing Vite >500 kB chunk warning remains; no new dependencies/licence or manifest/lockfile edits. No commits/merges; main checkout untouched.
