# G9 auditor checks on d54f5ba (before the review fixes)

- `runs/g9-checks.sh` (detached, nothing else running): `npm test` **371/371**; `npm run smoke` **30 passed** (2.0 m).
- Budget (gzip level 9 over every emitted file, `budget.json`): JS 148,670 + HTML 368 = **149,038 bytes**, baseline 144,068, delta **4,970 < 30,000**, PASS.
- REA (`gate.py --static --wait-ms 4500`): page-errors, console-errors (so no autoplay warning) and missing-files PASS; 10 steps; 8 distinct frames; rea-static PASS.
- Races (`lap.mjs FULL=1`, 3 laps, the kit autopilot as each racer; all finished, on the road):

  | Track | Cinder | Hyguana | Pip | Wren | Spread |
  |---|---:|---:|---:|---:|---:|
  | Ember total (s) | 142.4 | 142.9 | 141.1 | 143.2 | 1.5 % |
  | Lantern total (s) | 245.1 | 244.5 | 237.3 | 245.3 | 3.4 % |

  Max lateral 2.5–5.23 m against a half-width of 6 m. Totals are 1–2 s slower than at G8 after the fixes (e.g. Cinder Ember 140.3 → 142.4) with identical physics; the autopilot runs in real time, so this is driver timing noise, not a balance change (the balance criterion is `balance.test.js`, green inside `npm test`).
- Falls: Lantern pass (rivals 0 falls, fast jump clears, slow jump and bridge set back, laps unchanged); Ember pass.
- Collision: 414 contact pair-steps, min gap 1.391 m, 0 deep overlaps, 0 NaN, laps `[0, 2, 3, 3]`: **identical to G8**, which is independent evidence that the M9-T04 telemetry changed no physics.
- Ember item: 4 of 4 fires slowed the target (17.2 → 10.6–10.8). The best of any gate; the autopilot's aim varies.
- Play build `~/hoard-play` rebuilt at d54f5ba (port 8090, now with sound).
- Opus review (`review.md`): 1 bug, 4 risks, 3 test gaps, 2 questions; triaged there.

# After the review fixes (0cd0b31, `SUB=after-fixes bash runs/g9-checks.sh`, files in `after-fixes/`)

- Fix tasks M9-T06..T11 all DONE, each verify PASS on the first attempt, audit PASS (IP hits only in the generated DIGEST, the F6 echo). The diff `cf5ebff..0cd0b31` touches only `src/audio/{audio,engine,sfx}.js` and four test files.
- All ten triaged findings checked in the diff:
  1. Escape and inactive keys never create or resume the engine, and the `resuming` latch is gone. A never-settling resume is retried on the next key (new controller test).
  2. A late note is clamped to `now`; only a note whose whole sound, including the echo tail, is past gets skipped.
  3. `update` is wrapped in a try/catch. One throw stops audio for good and never reaches the main loop (test: no engine call after the failure).
  4. A persisted `pagehide` keeps the engine and listeners, so the page stays restorable; a real unload still disposes.
  5. `LOOK_AHEAD` is 0.3 s. Stall tests: a step inside the window drops no note, and a long stall emits one current window and replays nothing.
  6. The tautology at `themes.test.js:193` is replaced by exact anchor assertions.
  7. The cowbell and the new tempo are pinned to the crossing update, and the crossing is shown to fall off the old bar grid.
  8. New controller test for results → Enter restart: base BPM, a single "3", no stale chime or jingle.
  9. No screech while `air` is set; the engine hum keeps playing.
  10. `engine.clear(group)` with `theme`/`fx` tags: a theme change clears only `theme`, and mute still clears everything (no scope). The bar-0 phrase restart is kept, as triaged.
- `npm test` **384/384**, `npm run smoke` **33 passed**.
- Budget: JS 148,803 + HTML 371 = **149,174 bytes**, delta **5,106 < 30,000**, PASS.
- REA: page-errors, console-errors and missing-files PASS; 10 steps; 8 distinct frames; rea-static PASS.
- Races (3 laps; all finished, on the road, 0 page errors):

  | Track | Cinder | Hyguana | Pip | Wren | Spread |
  |---|---:|---:|---:|---:|---:|
  | Ember total (s) | 141.4 | 142.7 | 141.0 | 142.6 | 1.2 % |
  | Lantern total (s) | 244.6 | 245.0 | 238.2 | 243.0 | 2.9 % |

  Max lateral 2.5–5.3 m against a half-width of 6 m.
- Falls (both tracks) and collision (414 pair-steps, min gap 1.391 m, 0 deep overlaps, 0 NaN): **byte-identical to the first G9 run**.
- Ember item: 1 of 4 fires slowed the target (17.35 → 10.61). Range across gates: G6 1/4, G7 0/4, G8 1–2/4, first G9 run 4/4. This is the autopilot's aim; no item code changed.
- Play build `~/hoard-play` rebuilt at 0cd0b31 (port 8090).

**Verdict: G9 PASSED (owner-proxy).** Owner-unverified (rule 4), all of them listening items: first-key unlock, how the menu, Ember, Lantern and results themes sound, the final-lap tempo and cowbell, the countdown/lap/finish stingers, the effects (engine hum, drift screech, boost, hit, fall), mute, and tab-switch recovery.
