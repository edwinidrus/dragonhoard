# M2-T02 — Edge containment

| Field | Value |
|---|---|
| Status | TODO |
| Depends on | M2-T01 |
| Milestone constitution | [../CONSTITUTION.md](../CONSTITUTION.md) (inherits [global](../../CONSTITUTION.md)) |
| Plan source | `GAME_PLAN.md` §Content (Track), §Acceptance (edges item) |
| Journal | `tasks/M2-T02-edge-containment.journal.md` (create on first attempt) |
| Shaped | 2026-10-20, owner: `KART_RADIUS` 0.7, slide along the wall |

## 0. Context to load

Load these and nothing else:
- `implementation/CONSTITUTION.md`, `implementation/DIGEST.md`, `implementation/LESSONS.md`
- `implementation/M2-track-and-laps/CONSTITUTION.md`
- this pack
- `src/logic/track.js`, `src/logic/trackData.js` (M2-T01, read-only) and the M2-T01 journal's
  final track numbers and `option.chosen` event
- `src/logic/kart.js`, `src/logic/vec2.js`, `src/logic/controls.js` (read-only)
- `test/logic/kart.test.js` (house test style)

Excerpts from the plan the task depends on, copied here so the plan need not be opened:

> **Track:** ... It has visible edges the karts cannot leave ... (plan §Content)

> - [ ] Karts cannot leave the track through its edges. (plan §Acceptance)

## 1. Plan

- **Goal:** `containKart(kart, track)` keeps every kart's centre within
  `halfWidth - KART_RADIUS` of the centreline and makes it slide along the edge, proven by
  fuzzed Node tests.
- **In scope:** `src/logic/containment.js`: `KART_RADIUS`, `containKart`; Node tests.
- **Out of scope:** kart-to-kart collision (M4-T03); wall meshes and wiring (M2-T04); any bounce,
  damage or speed penalty beyond removing the outward velocity (owner tunes feel at G2, a later
  pack change if asked).
- **Files:** `src/logic/containment.js` + `test/logic/containment.test.js`.
- **Consumes:**
  - M2-T01 `src/logic/track.js`: `createTrack(def) -> Track` (`halfWidth`, `length`, `grid`),
    `locate(track, pos) -> { s, lateral, tangent }` (`lateral` + = left of the driving
    direction), `pointAt(track, s, lateral) -> {x, y}`; `src/logic/trackData.js`: `TRACK`.
  - `src/logic/kart.js:17-19`: Kart `{ pos, heading, speed, slide }`; world velocity =
    `fwd * speed + left * slide`, `fwd = fromAngle(heading)`, `left = (-fwd.y, fwd.x)`
    (`kart.js:45-46`).
  - `src/logic/kart.js:23`: `stepKart(kart, controls, dt)` (tests only); `src/logic/loop.js:4`:
    `STEP`.
  - `src/logic/vec2.js:3-24`.
  - If M2-T01's `option.chosen` changed any Track name above, this list is stale: stop and
    report it (L02), do not adapt silently.
- **Produces** (owner-approved at shape M2, 2026-10-20):
  - `KART_RADIUS = 0.7` (m; the body plus wheels reach 0.65 m from the centre).
  - `containKart(kart, track) -> Kart`. With `limit = track.halfWidth - KART_RADIUS` and
    `{ s, lateral, tangent } = locate(track, kart.pos)`:
    - `|lateral| <= limit`: returns the kart unchanged;
    - otherwise: `pos = pointAt(track, s, sign(lateral) * limit)`; the world velocity's
      component along the outward normal is removed when it points outward and kept when it
      points inward; the tangential component is kept; `speed` and `slide` are re-split along
      the kart's unchanged `heading`.
  - Never mutates its inputs.
- **Open options:** none.
- **Do not:**
  - re-derive distance-along-track or edges from raw points (M2 art. 1): use `locate` and
    `pointAt` only;
  - change `kart.js` or `track.js` (a needed change there is a pack change: stop and report);
  - read `Math.random`, `Date.now`, `performance.now`, `window` or `document` in `src/logic/`.

## 2. Explore (only if Open options is not "none")

Skipped: none open.

## 3. Verify (before building)

- [ ] `grep -n "export" src/logic/track.js src/logic/trackData.js src/logic/kart.js
      src/logic/loop.js`: paste; confirm each Consumes name. A missing or different name ->
      BLOCKED.
- [ ] The standard checks are green before any change. Record the counts. Port 5173 free
      first (L03).
- [ ] `test/logic/containment.test.js` written first, run, and fails for the expected reason
      (`ERR_MODULE_NOT_FOUND` for `containment.js`).

On any mismatch, record `BLOCKED` with evidence and stop.

## 4. Build

1. Write the tests for §5 items 1–7 (step 3). Use a test-local seeded generator (for example a
   small LCG), never `Math.random`, so a fuzz failure reproduces from its seed.
2. Write `src/logic/containment.js`.
3. Run `npm test`, then `npm run smoke`.

## 5. Test

```bash
# setup (once per clone): npm ci && npx playwright install chromium
npm test
npm run smoke
```

Acceptance (tick each, with evidence). Items 1–7 are tests in `test/logic/containment.test.js`
on `createTrack(TRACK)`:
- [ ] 1. A kart with `|lateral| <= limit` is returned unchanged (`deepEqual`).
- [ ] 2. A kart placed at `lateral = ±(halfWidth + 0.5)` comes back with `|lateral|` equal to
      `limit` (1e-6), on the same side, at about the same `s` (0.5 m).
- [ ] 3. Outside and moving outward: after `containKart`, world velocity · outward normal
      `<= 1e-9`, and the tangential component is unchanged (1e-9).
- [ ] 4. Outside and moving inward: the world velocity is unchanged (1e-9).
- [ ] 5. Fuzz, static: 1000 seeded karts at `|lateral|` up to `halfWidth + 1`, random heading,
      `speed`, `slide` -> every result has `|lateral| <= limit + 1e-6`.
- [ ] 6. Fuzz, driving: 20 seeded runs of 600 steps each (`STEP`), starting from the `grid`
      slots, random `Controls` held for random short spells; each step is
      `containKart(stepKart(kart, controls, STEP), track)` -> `|lateral| <= limit + 1e-6`
      after every step.
- [ ] 7. Slide, not stick: a kart at the edge heading 30° into it at speed 15 with throttle,
      over 60 steps, keeps `|lateral| <= limit + 1e-6` and its `s` keeps advancing (net
      forward progress > 5 m).
- [ ] Frozen kart and track inputs do not throw.
- [ ] The fail-first run is in the journal.
- [ ] `npm test` passes: baseline count plus the new tests. `npm run smoke` still `2 passed`.
- [ ] `grep -rnE "Math\.random|Date\.now|performance\.now|window|document|from 'three'" src/logic/`
      -> no output.
- [ ] `git diff --stat -- src/logic/kart.js src/logic/track.js src/logic/trackData.js` empty.
- [ ] `git status --porcelain -- src test package.json package-lock.json` lists only files in
      Files.

## 6. Record and hand off

- [ ] Journal entry written, every attempt recorded.
- [ ] Milestone `PROGRESS.md` row and `STATUS.md` row updated with real output.
- [ ] `dragonhoard.py log M2-T02 task.done "<one line>"` (or `task.blocked "<reason>"`).
- [ ] `dragonhoard.py digest` and `dragonhoard.py check` → PASS.
- **BLOCKED if:** a Track name differs from Consumes; containment cannot hold without changing
  `kart.js` or `track.js`; `locate` snaps to the wrong stretch for a point within
  `halfWidth + 1` (that is an M2-T01 data defect: report it, do not patch it here).
- **Next:** M2-T03
