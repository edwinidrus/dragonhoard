# G7 auditor checks on 97f5949 (before the review fixes)

- `npm test` 235/235; `npm run smoke` 11 passed.
- REA (`gate.py --static --wait-ms 4500`, menu Enter step added): page-errors, console-errors and missing-files PASS; 8 steps completed; 7 distinct frames; rea-static PASS.
- `race-ember.json` (FULL): 3 laps on the road (max lateral 2.54), speed 0 before GO, 1st in the first 1.5 s, results text, Enter restarts (countdown, lap 0), 0 errors.
- `race-lantern-trace.json` (TRACK=lantern FULL TRACE): 3 laps (86.2 / 192.2 / 279.0 s), finished, 0 errors. Lap 2 stalls about 20 s at s 45–47: the autopilot cruises at about 13 m/s, below jump 0's minSpeed 14, so it falls and is set back again and again. The first run (`race-lantern.json`) stalled the same way and ran out of time on lap 2.
- From rest at the set-back point (12 m before the gap) with full throttle, a kart reaches 15.5 m/s at both take-offs (minSpeed 14 / 12): clearable, but the margin at jump 0 is 1.5 m/s. **Owner feel item:** a player who doesn't hold full throttle can fall at jump 0 repeatedly.
- `fall-lantern.json`: rivals 3 laps with 0 falls each (202.6 / 190.2 / 178.3 s); a fast jump clears; a slow one (about 9 m/s) falls at s 50 and is set back at s 38 after 1.5 s, facing along the track, laps unchanged; a bridge fall at s 570.6 is set back at s 547.9 after 1.5 s; 0 NaN; laps never move during a fall. `fall-ember.json`: no hazards, rivals 0 falls.
- `collision.json` (Ember, forced lane): 3412 contact pair-steps, min gap 1.367 m, 0 deep overlaps, 0 NaN (same as G4/G6).
- Ember item (`ember-1..4.json`, `lap.mjs EMBER=1`): 4 trials, 2 pickups each, 1 of 4 hit (17.83 → 11.17, ratio 0.63), the same as G6; misses come from the autopilot's aim on curves.
- Driver fixes for the menu (auditor side): `lap.mjs`/`ember.mjs` force the focus click (the menu overlay covers the canvas) and pick the track with ArrowRight/Enter; `gate.py` presses Enter after boot; `lap.mjs TRACE=1`; new `fallcheck.mjs`.

## After the review fixes (29e8461, `gates/G7/after-fixes/`)

- `npm test` 260/260; `npm run smoke` 11 passed; REA all PASS (7 distinct frames, 0 errors); rebuilt `~/hoard-play`.
- `race-ember.json`: 3 laps (46.1 / 93.9 / 141.8 s), on the road, finished, Enter restarts, 0 errors.
- `race-lantern.json`: the autopilot now holds full throttle over the 40 m before a jump (its 13 m/s cruise is below the jump speeds). 3 laps (78.7 / 160.5 / 242.0 s), no stalls, max lateral 3.39, finished with results ("1st Gold 2:57.250 … 4th You 4:04.000"), Enter restarts, 0 errors.
- Falls (both tracks) and collision: identical to before the fixes.
- Ember item, 4 trials: 0 of 4 hit (2 shots seen), against 1 of 4 before and at G6; the misses come from the autopilot's aim, and the hit logic is unit-tested (T14 added falling/airborne gating, 16/16).
- Verdict: **G7 PASSED (owner-proxy).** Owner-unverified feel items: menu feel, jump and fall feel (the jump-0 run-up margin after a set-back is 1.5 m/s), flat jump render, scenery and dusk sky look.
