# G9 code review (Opus reviewer subagent, diff d58bc8a..d54f5ba, src + test)

The reviewer read M9 HEAD d54f5ba only (no commands run). Findings 1 and 2 depend on Chrome behaviour taken from the HTML and Web Audio specs. The auditor spot-checked the code paths: `audio.js:41-54` sets `resuming = true` and only clears it in the promise's `finally`, so a resume that never settles keeps it true; `engine.js:119` schedules only notes with `at >= context.currentTime`; `audio.js:7` `LOOK_AHEAD = 0.1`; `themes.test.js:193` is `A || !A`; `main.js:205,213` call `audio.update` in the loop with no guard.

Totals: 1 bug, 4 risks, 3 test gaps, 2 questions.

## Bug
1. src/audio/audio.js:69 (:42, :50) — Escape as the first key creates the AudioContext without a user activation (HTML spec: Escape does not activate). Chrome then logs "not allowed to start", and `resume()` never settles. `resuming` stays true, so audio stays silent for the session, and the visibility path (:84) hits the same latch. Fix: create or resume only on activating keys (or check `navigator.userActivation.isActive`); drop the latch and call the idempotent `resume()` on every trusted key while not ready; add a smoke test that presses Escape first.

## Risks
2. src/audio/engine.js:119 — notes with `at < currentTime` are dropped silently. `update` reads `now` once and then allocates nodes, so single notes at exactly `now` (blips, GO, bonk, whoosh, whistle, cowbell on beat 0) vanish at random. `sequencer.test.js:312` asserts the drop. Fix: start late notes at `max(at, currentTime)`; skip only notes whose end has passed.
3. src/main.js:213 (:205, :229; audio.js:102) — `audio.update` runs in the game loop with no try/catch. A throw skips `requestAnimationFrame` and freezes the race, so audio would own race flow (art. 8). Fix: guard `update` and stop audio after the first failure.
4. src/audio/audio.js:98 — `pagehide` disposes everything and ignores `event.persisted`; after the back/forward cache restores the page, audio and M stay dead until a reload. Fix: on a persisted pagehide, clear and reset only, or recreate on `pageshow`.
5. src/audio/audio.js:7 — the look-ahead is 0.1 s and the scheduler runs once per frame, so a frame over 100 ms (GC, a shader compile after `startRace`, low fps) skips notes mid-race while the tab is visible. Fix: a 0.2–0.3 s look-ahead, or skip only gaps over a threshold (about 1 s).

## Test gaps
6. test/logic/themes.test.js:193 — the assertion is a tautology (A or not A) and cannot fail. Fix: assert the real relation, or delete it.
7. test/logic/themes.test.js:177 (sfx.test.js:288, :316) — no test pins the final-lap cowbell to the crossing time: `state.time` stays 0, so a sequence anchored at any older bar passes. Fix: advance `state.time` to the crossing and assert `cowbells[0] === state.time` and BPM ×1.08 on the same update.
8. test/logic/themes.test.js:291 — "restart" only covers race → menu. Results → Enter restart has no controller test: one clear, theme replaced, a single "3" blip, no lap chime from the 3 → 0 reset. Fix: a controller test over finished → new countdown snapshots.

## Questions
9. src/audio/sfx.js:153 — `ground` excludes falling karts but not airborne ones. Drift is frozen in flight (race.js:84-86), so a drift held at take-off screeches through the jump.
10. src/audio/audio.js:112 — the final-lap tempo key change calls `engine.clear()`, which hard-cuts whoosh, bonk, whistle and the continuous engine/screech voices (they restart with a click). The score restarts at bar 0 at the crossing.

## Owner-proxy triage (rule 1: the judge's recommendation)

- **Fix:** 1, 2, 3, 4, 5, 6, 7, 8. Also 9 (no drift screech while airborne; the engine hum continues, since the engine still runs) and 10 (a theme change clears only the theme's voices; effects and continuous voices are untouched).
- **Keep as designed:** 10's phrase restart at bar 0 at the crossing. The approved T03 pack anchors the selected sequence at the transition time ("clear old queued/sounding material and anchor the selected sequence at the transition time"). Mute keeps clearing everything (art. 5).
