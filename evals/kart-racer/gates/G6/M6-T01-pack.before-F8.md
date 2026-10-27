# M6-T01 — Slow path and Shift item input

| Field | Value |
|---|---|
| Status | TODO |
| Depends on | G5 |
| Milestone constitution | [../CONSTITUTION.md](../CONSTITUTION.md) (inherits [global](../../CONSTITUTION.md)) |
| Plan source | `implementation/M6-stretch-ember/PLAN.md` task M6-T01 and contract; `GAME_PLAN.md` §Player experience (stretch paragraph) |
| Journal | `tasks/M6-T01-slow-item-input.journal.md` (create on first attempt) |
| Shaped | 2026-10-21 at shape M6. The slow is an explicit `stepKart` multiplier (owner decision 3), not a negative boost. Shift is a level input with `item: boolean`; the press edge is latched later by the ember state (M6 art. 4), not here. `src/logic/rival.js` stays untouched: `item` is player-only (M6 art. 3). |

## 0. Context to load

Load these and nothing else:
- `implementation/CONSTITUTION.md`, `implementation/DIGEST.md`, `implementation/LESSONS.md`
- `implementation/M6-stretch-ember/CONSTITUTION.md`
- this pack
- `src/logic/kart.js`, `src/logic/controls.js` (edited here)
- `src/logic/boost.js`, `src/logic/drift.js` (read-only: how a timed effect reaches `stepKart`)
- `src/logic/rival.js` (read-only: its `Controls` literal has no `item`; leave it that way)
- `src/logic/race.js` (read-only here: its call sites pass a 3-argument `stepKart` today)
- `test/logic/kart.test.js`, `test/logic/controls.test.js` (edited here)
- `test/logic/boost.test.js` (read-only: house style for a `stepKart` option)

Excerpts from the plan the task depends on, copied here so the plan need not be opened:

> Stretch, only once everything above is done: one item, the "ember". Pick it up from an item
> box and press Shift to fire it forward. A rival it hits slows briefly. (plan §Player experience)

> 2. **The slow goes through physics.** A hit sets a timed effect that `stepKart` reads, the same
> way boost works; ember code never writes a kart's speed directly. (M6 CONSTITUTION)

> 3. **Player-only item path.** Only the player's entry picks up and fires. Rival `Controls` may
> omit `item`; nothing may read `controls.item` for a rival (M6 PLAN decision 4).
> (M6 CONSTITUTION)

Later consumer (not to build now): M6-T02 reads `TUNING.slowFactor` / `TUNING.slowSeconds` and
passes `slow` to `stepKart`; M6-T03 draws the item and shows it in the HUD.

## 1. Plan

- **Goal:** a slowed kart's top speed drops to `TUNING.maxSpeed * TUNING.slowFactor` through the
  physics, recovers normally when the effect ends, and holding either Shift key reports
  `item: true` in `Controls`; with no slow option and no Shift, every existing behaviour is
  byte-identical.
- **In scope:**
  - `src/logic/kart.js`: a `slow` option on `stepKart`, and two feel constants.
  - `src/logic/controls.js`: `item` on `NO_CONTROLS` and `controlsFromKeys`.
  - `test/logic/kart.test.js`: new slow tests (existing tests untouched).
  - `test/logic/controls.test.js`: extend every expected control object with `item`, add Shift
    cases. Do not remove an assertion (owner instruction, M6 PLAN decision 8).
- **Out of scope:** boxes, the ember, firing, hit detection, the slow timer, rendering, the HUD
  (M6-T02/T03); any change to `rival.js`, `race.js`, `raceFlow.js`, `track.js` or `index.html`.
- **Files:** `src/logic/kart.js`, `src/logic/controls.js`, `test/logic/kart.test.js`,
  `test/logic/controls.test.js`.
- **Consumes:**
  - `src/logic/kart.js:39`: `stepKart(kart, controls, dt, { boost = 0, drift = 0 } = {})`,
    currently called with 3 or 4 arguments (`src/logic/race.js:52`, `test/logic/boost.test.js:20`).
  - `src/logic/kart.js:59`: `const top = Math.sqrt(Math.max(0, (T.maxSpeed + boost) ** 2 - slide ** 2));`
    — the forward speed cap the slow scales.
  - `src/logic/kart.js:61-67`: `accel` and the existing above-the-cap fade
    (`speed - T.boostFade * dt`), the path the slow reuses so a hit slows a moving kart.
  - `src/logic/kart.js:6-29`: `TUNING`; the owner tunes these at the gates.
  - `src/logic/controls.js:4`: `NO_CONTROLS = Object.freeze({ throttle, brake, steer, drift })`.
  - `src/logic/controls.js:7-14`: `controlsFromKeys(codes)` builds the object from
    `KeyboardEvent.code` values.
  - `test/logic/controls.test.js:8-78`: exact-shape `deepEqual` assertions (12 sites) and the
    keyboard fixture.
- **Produces:**
  - `TUNING.slowFactor = 0.55` and `TUNING.slowSeconds = 1.2` (numbers; seconds unused in this
    task, used by M6-T02).
  - `stepKart(..., { boost = 0, drift = 0, slow = 1 } = {})`: `slow` is a multiplier on the
    forward cap, clamped to `[0, 1]`; `1` and any value above `1` drive exactly as today, `0`
    allows no forward speed. Only the forward cap and its existing fade change: reverse, accel,
    steering, grip, drift and boost are untouched.
  - `NO_CONTROLS.item = false`; `controlsFromKeys` sets
    `item: held('ShiftLeft', 'ShiftRight')`. Rivals keep their four-key literal, so read
    `controls.item` as `=== true` (absent means false).
- **Open options:** none. The owner chose the mechanism (PLAN decision 3) and the constants
  (decision 7).
- **Do not:**
  - apply the slow by scaling `controls.throttle`/`controls.brake` or by writing `kart.speed` in
    another module (M6 art. 2);
  - scale `accel` or the reverse cap: only the forward cap changes;
  - remove or edit an existing assertion in `test/logic/controls.test.js`; extend the expected
    objects and add tests instead;
  - add `item` to `src/logic/rival.js` or read it for a rival;
  - rename or reorder existing `TUNING` keys;
  - touch any file outside Files.

## 2. Explore (only if Open options is not "none")

Skipped: none open.

## 3. Verify (before building)

- [ ] `grep -n "export function stepKart\|const top = \|boostFade" src/logic/kart.js` and
      `grep -n "export const NO_CONTROLS\|export function controlsFromKeys" src/logic/controls.js`;
      paste both outputs.
- [ ] `grep -n "stepKart(" src/logic/*.js test/logic/*.js`; confirm every call site passes 3 or
      4 arguments (an options object or nothing), so the new default applies.
- [ ] `grep -n "item" src/logic/rival.js`; expect no output.
- [ ] The standard checks are green before any change: `npm test` (expected `141` tests; read the
      real number) and `npm run smoke` (expected `9 passed`); record both. Check the Playwright
      port is free first (L03).
- [ ] Write the new kart and controls tests first, run `node --test test/logic/kart.test.js
      test/logic/controls.test.js`, and see them fail for the expected reasons (slow key absent;
      `item` missing from the control object). Record the failures.

On any mismatch, record `BLOCKED` with evidence and stop.

## 4. Build

1. `src/logic/kart.js`: add `slowFactor` and `slowSeconds` to `TUNING` after the drift block,
   with comments in the house style (`// Slow (M6); the owner tunes these at G6.`). Add `slow`
   to the options destructure. Just before `top`, clamp it:
   `const cap = Math.min(1, Math.max(0, slow));` and use `T.maxSpeed * cap + boost` in the `top`
   expression. Change nothing else in the function.
2. `src/logic/controls.js`: add `item: false` to `NO_CONTROLS` and
   `item: held('ShiftLeft', 'ShiftRight'),` to `controlsFromKeys`.
3. `test/logic/controls.test.js`: add `item: false` to every expected object (including the
   Space, arrow/WASD and opposite-key expectations) and include `ShiftLeft` in the blur key set;
   add:
   - `keys('ShiftLeft')` and `keys('ShiftRight')` both give
     `{ throttle: 0, brake: 0, steer: 0, drift: false, item: true }`;
   - `ShiftLeft + ArrowUp` gives `throttle: 1` and `item: true` together.
4. `test/logic/kart.test.js`: keep the existing `drive` helper as is; add a local
   `driveWith(kart, controls, n, opts, onStep)` or equivalent for the option tests, then the
   tests in §5.

## 5. Test

```bash
# setup (once per clone): npm ci && npx playwright install chromium
npm test
npm run smoke
```

Acceptance (tick each, with evidence). Items 1–6 are new tests in `test/logic/kart.test.js`;
7–9 are the controls contract:
- [ ] 1. No option and `{ slow: 1 }` are identical: two 120-step scripted runs `deepEqual`, and
      `{ slow: 2 }` equals `{ slow: 1 }` (clamp).
- [ ] 2. Full throttle from rest with `slow: TUNING.slowFactor` reaches
      `TUNING.maxSpeed * TUNING.slowFactor` within `0.01` after 10 s and never exceeds it
      (`speed <= cap + 1e-9` on every step).
- [ ] 3. A kart already at `TUNING.maxSpeed` drops to that cap within 2 s of throttle under
      `slow: TUNING.slowFactor` (within `0.01`), proving the existing fade slows it.
- [ ] 4. Recovery: after 2 s slowed, 1.5 s with no slow option returns the speed to
      `TUNING.maxSpeed` within `0.01`.
- [ ] 5. `slow: 0` from rest under full throttle stays at exactly `0` for 1 s; `slow: -1` behaves
      the same (clamp).
- [ ] 6. Reverse is unaffected: brake from rest with `slow: TUNING.slowFactor` reaches the same
      final kart as with `slow: 1` (`deepEqual`, capped at `-TUNING.maxReverse`).
- [ ] 7. `NO_CONTROLS` includes `item: false` and is frozen; `keys()` equals it.
- [ ] 8. Both Shift codes set `item: true`; Shift plus ArrowUp reports both; Shift clears on
      keyup and on blur.
- [ ] 9. `git diff -U0 test/logic/controls.test.js | grep -E '^-.*assert'` -> no output (no
      assertion removed).
- [ ] `npm test` passes: the 141-test baseline plus the new tests (paste the new count).
- [ ] `npm run smoke` passes with `9 passed` (no smoke change in this task).
- [ ] `grep -n "slow" src/logic/race.js src/logic/rival.js` -> no output.
- [ ] `git status --porcelain -- src test package.json package-lock.json` lists only the four
      Files.
- [ ] `python3 .dragonhoard/scripts/dragonhoard.py check` -> PASS.

## 6. Record and hand off

- [ ] Journal entry written, every attempt recorded, including the fail-first output and the
      slow caps measured.
- [ ] Milestone `PROGRESS.md` row and `STATUS.md` row updated with real output.
- [ ] `dragonhoard.py log M6-T01 task.done "<one line>"` (or `task.blocked "<reason>"`).
- [ ] `dragonhoard.py digest` and `dragonhoard.py check` → PASS.
- **BLOCKED if:** `stepKart` has a different signature, another call site depends on the exact
  `TUNING` object, a controls assertion cannot be extended without removing one, or the slow
  cannot be applied without touching a file outside Files.
- **Next:** M6-T02
