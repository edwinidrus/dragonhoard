# G8 auditor checks on aef26d6 (before the review)

- `runs/g8-checks.sh` on aef26d6, 2026-10-25: `npm test` 293/293. `npm run smoke` **13 passed, 1 failed** in the gate run, which ran beside a play-build rebuild and a served play build; the filtered gate log does not name the failed test. A rerun right after: **14 passed**, frame test `310 frames / 10.02 s = 30.95 fps` (floor 300 frames), models `[9, 7, 8, 11]` parts. Smoke is counted flaky, not green; the frame test sits 3 % above its floor (T08 measured 322 / 319).
- REA (`gate.py --static --wait-ms 4500`, menu Enter + racer-menu Enter steps): page-errors, console-errors and missing-files PASS; 10 steps completed; 8 distinct frames; rea-static PASS.
- Races (`lap.mjs FULL=1`, 3 laps, the kit autopilot as each racer; every run finished, 0 page errors, on the road):

  | Track | Racer | Laps (s) | Total (s) | Max lateral (m) |
  |---|---|---|---:|---:|
  | Ember | Cinder | 45.9 / 47.7 / 47.8 | 141.4 | 2.50 |
  | Ember | Hyguana | 46.8 / 48.2 / 47.9 | 142.9 | 2.54 |
  | Ember | Pip | 45.5 / 47.4 / 47.5 | 140.4 | 2.50 |
  | Ember | Wren | 46.0 / 48.1 / 48.1 | 142.2 | 2.50 |
  | Lantern | Cinder | 81.1 / 81.8 / 82.1 | 245.0 | 3.82 |
  | Lantern | Hyguana | 77.9 / 82.3 / 82.3 | 242.5 | 4.22 |
  | Lantern | Pip | 78.2 / 81.3 / 81.6 | 241.1 | 3.74 |
  | Lantern | Wren | 79.3 / 82.3 / 82.4 | 244.0 | 5.30 |

  Total spread (autopilot, not the balance protocol): Ember 1.8 %, Lantern 1.6 %, both inside 4 %. The balance criterion itself is `test/logic/balance.test.js` (rival driver, skill 0.95), green in `npm test`.
- `fall-lantern.json`: rivals 3 laps with 0 falls each (201.4 / 195.5 / 178.4 s); a fast jump clears (0 falls); a slow jump falls at s 50 and is set back at s 38 after 1.5 s (speed 0, facing along the track); a bridge fall at s 570.6 is set back at s 547.9 after 1.5 s; laps unchanged in every fall; 0 non-finite steps. `fall-ember.json`: rivals 0 falls (120.7 / 114.4 / 105.0 s), pass.
- `collision.json` (Ember, forced lane, 120 s): 414 contact pair-steps (G7: 3412), min gap 1.391 m (G7: 1.367), 0 deep overlaps, 0 NaN, laps `[0, 2, 3, 3]` (same as G7). The drop in contact steps fits M8-T03's mass push (karts separate faster); not a failure, noted for the review.
- Ember item (`lap.mjs EMBER=1`, 4 trials): 2 pickups each; 2 of 4 fires slowed the target (17.25 → 10.61, 17.17 → 10.61); 2 missed (G7 after fixes: 0 of 4, G6: 1 of 4). Misses come from the autopilot's aim; the hit logic is unit-tested.
- Play build: `~/hoard-play` rebuilt at aef26d6 and served on port 8090 for the owner.
- The builder wrote the G8 status row and ticked the automated criteria in `GATE.md` during M8-T08 (gate status `PARTIAL`). The gate verdict stays with the auditor.

# After the review fixes (60c7c5b, `SUB=after-fixes bash runs/g8-checks.sh`, files in `after-fixes/`)

- `npm test` 309/309; `npm run smoke` **19 passed** in the gate run (no flake this time; nothing else ran beside it).
- Frame test rerun alone (`--grep "moving baseline"`): four models 37.69 fps, Cinder-only geometry 39.90 fps, ratio **0.945** (>= 0.90); about 377 frames in 10 s (>= 300). The builder's two runs: 425 / 428 frames, ratios 0.986 / 0.988.
- REA: page-errors, console-errors, missing-files PASS; 10 steps; 8 distinct frames; rea-static PASS. Its `IP_TERMS` hit is the three.js `anisotropy` property name (false positive, also in G7).
- Races (`lap.mjs FULL=1`, 3 laps, the kit autopilot as each racer; all finished, on the road):

  | Track | Cinder | Hyguana | Pip | Wren | Spread |
  |---|---:|---:|---:|---:|---:|
  | Ember total (s) | 140.3 | 140.9 | 139.7 | 141.6 | 1.4 % |
  | Lantern total (s) | 241.9 | 242.8 | 236.4 | 243.4 | 3.0 % |

  Max lateral 2.5–4.67 m against a half-width of 6 m.
- Falls: Lantern pass (rivals 0 falls; fast jump clears; slow jump falls at s 50 and is set back at s 38; bridge fall at s 570.6 set back at s 547.9; laps unchanged). Ember pass.
- Collision: 414 contact pair-steps, min gap 1.391 m, 0 deep overlaps, 0 NaN, laps `[0, 2, 3, 3]` (identical to before the fixes: the fixes touched no physics).
- Ember item: 1 of 4 fires slowed the target (17.19 → 10.61); 3 missed. Autopilot aim; no item code changed (G6 1/4, G7 0/4, before fixes 2/4).
- Auditor read the fix diff (`aef26d6..60c7c5b`, src): every triaged finding (1–11, 15–17) is addressed; 12–14 untouched as triaged.
- Spike worktrees a/b/c removed after saving their files to `spikes/`.
- Play build `~/hoard-play` rebuilt at 60c7c5b (port 8090).

**Verdict: G8 PASSED (owner-proxy).** Owner-unverified (rule 4): racer-menu feel, recognisability from the chase camera and the idle animations, weight feel in bumps, headed ~60 fps smoothness.
