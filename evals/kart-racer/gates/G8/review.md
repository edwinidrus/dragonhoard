# G8 code review (Opus reviewer subagent, diff a19167a..aef26d6, src + test)

The reviewer read M8 HEAD aef26d6 only (no commands run). The auditor saved its report here and
spot-checked the bug (`racers.js:50,53`: the bag spans x -0.7..-0.2 and y 0.52..0.88; spine3 spans
x -0.34..-0.16 and y 0.47..0.85, so only about 4 cm of it shows), the bake context
(`racerMenu.js:50` calls `renderer.dispose()` only; `smoke.spec.js:409` expects at least 2 WebGL
contexts), the key repeat (`main.js:167` never reads `event.repeat`) and the frame test
(`smoke.spec.js:528-547`: no throttle during the sample, floor 300 frames in 10 s).

Totals: 1 bug, 3 risks, 7 test gaps, 6 questions.

## Bug
1. src/logic/racers.js:53 — bug: `spine3` (cone r 0.09, h 0.38 at x -0.25, y 0.66) is almost entirely inside the mail bag (box x -0.7..-0.2, y 0.52..0.88). Its tip at y 0.85 is in the bag and its base is in the body, so only a sliver shows. From the chase camera Pip shows two spines, not three, and the primitive is wasted. racerParts.test.js passes because it counts part ids, not visible parts. Fix: move the spines forward or the bag back so spine3 clears x -0.2, and add a bounding-box test that no spine overlaps the bag.

## Risks
2. src/ui/racerMenu.js:50 — risk: `renderer.dispose()` frees resources but not the context (three 0.186.1 `WebGLRenderer.dispose`). The bake context stays alive until garbage collection, so a race runs with two live WebGL contexts. The smoke test asserts `>= 2` (smoke.spec.js:409), and I-4 later requires exactly one WebGL context in a race. Fix: call `renderer.forceContextLoss()` after `dispose()` (or bake through the main renderer into a render target), and have the smoke test check that the bake context `isContextLost()`.
3. src/ui/racerMenu.js:57 — risk: `bakePreviews` runs at module top level (main.js:49), after the game's own context exists. If the browser refuses the second context (context limit, `webglcontextcreationerror`), three throws and the whole game fails to start, not just the card images. Fix: wrap the bake in try/catch and fall back to a colour swatch per card.
4. src/main.js:167 — risk: the keydown handler never checks `event.repeat`. Holding Enter on the track menu opens the racer menu, then the auto-repeat Enter immediately starts the race with the remembered racer, so the pick is skipped. New in M8 because two Enter-driven screens are now chained. Fix: ignore `event.repeat` for Enter and Escape in the menu branches.

## Test gaps
5. test/smoke/smoke.spec.js:547 — test gap: the floor is 300 frames / 10 s = 30 fps, half the ~60 fps requirement. Measured runs were 31–33 fps, so the margin is a few percent (flaky under load), and there is no baseline to isolate what the four models cost. Fix: compare against a same-run baseline (Cinder-only meshes) with a ratio threshold, and keep the ~60 fps verdict as the owner's headed check.
6. test/smoke/smoke.spec.js:528 — test gap: the player never presses throttle during the 10 s sample. The camera stays on the grid while the three rivals drive out of the chase view, so the test proves four models exist in the scene, not four models on screen. `models` is a constant child count, so the before/after equality checks prove nothing. Fix: hold ArrowUp during the sample, or assert `renderer.info.render.calls` / an in-frustum check that all four karts are drawn.
7. test/logic/racers.test.js:78 — test gap: "Wren turns tightest" is measured as the heading change in one step, which is just `steerRate`. Grip (Wren 13 vs Hyguana 9) and the actual turning radius are never measured. Fix: run 1–2 s of full steer from 15 m/s per racer and compare the path radius or lateral displacement.
8. test/logic/rivalJumps.test.js:121 — test gap: the Lantern zero-fall/take-off guard covers only the default line-up (player Cinder, parked) and same-racer copies (:175). The three other real line-ups are never run: player Hyguana, Pip or Wren, with mixed-mass bumps and different slot skills. Fix: run `createRace(lantern, { racer })` for every roster id in `raceRivals`.
9. test/logic/kartCollision.test.js:296 — test gap: "heavier pushes lighter further" is shown only by one `resolveKartCollisions` call with literal masses 1.35/0.75. No `stepRace`-level bump with roster racers (caps, grip, containment) shows the light kart ending further displaced. Fix: add a two-kart stepRace case comparing Hyguana hitting Pip with Pip hitting Hyguana, and assert the displacement after about 1 s.
10. test/smoke/smoke.spec.js:516 — test gap: results names are checked with a regex on results.js source, and results.test.js uses hand-made `{ name }` stubs. Nothing runs `createRace` → `resultRows`, or the overlay, with real roster entries. Fix: add a logic test of `resultRows` over a real `createRace` flow asserting roster names in rank order.
11. test/smoke/smoke.spec.js:497 — test gap: the browser tests pick only Cinder and Wren. Hyguana and Pip are never started through the racer menu, so "all four pickable" is only proven in logic. Fix: loop the four-model check (it needs no 10 s wait) over all four racers.

## Questions
12. src/logic/racers.js:92 — question: Wren is Cinder plus steerRate 2.6 and grip 13, with the same speed, accel and mass. Wren is at least as good as Cinder on every axis, and its laps are faster on both tracks in the balance table. Intended? Fix: give Wren a cost (accel or top speed) if not.
13. src/logic/rival.js:30 — question: `cornerLimit` uses a fixed 18 m/s² and ignores grip and steerRate. The 4 % protocol therefore cannot see the handling axis: Wren vs Cinder differs by only 0.13 s per lap, and Hyguana's handling penalty is barely felt. Is handling-blind balance accepted? Fix: owner confirms, or add a reported (not asserted) handling-aware run.
14. src/logic/race.js:58 — question: rival skill and lane follow the grid slot, not the racer. An unpicked Cinder is always the weakest rival (0.85), an unpicked Wren is always the strongest (0.95), and Pip is the strongest whenever Wren is picked. Intended? Fix: owner confirms or assigns skill per racer.
15. src/logic/racers.js:63 — question: Wren's propeller sits at the tail (x -0.72), floating about 0.28 m above the body with no mast. The plan says "propeller cap". Fix: move it onto the head (around x 0.5, y 1.03) if a cap is meant.
16. src/ui/results.js:47 — question: the results screen no longer shows "You", and `row.isPlayer` is computed but the overlay never uses it, so the player's row can only be found by racer name. Fix: highlight the `isPlayer` row if the owner wants it marked.
17. src/logic/racers.js:280 — question: after the retune the top-speed range is only 19.3–20.2 m/s (4.6 %), but the bars still stretch min to max. Pip's speed bar is empty (0 %) and Hyguana's full, which overstates the difference. Keep, or move to a fixed scale? Fix: owner confirms or anchors the bars to fixed ranges.

## Owner-proxy triage (rule 1: the judge's recommendation)

- **Fix:** 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11; and from the questions 15 (the plan says "propeller cap"), 16 (the player's row was marked before M8) and 17 (an empty bar reads as no top speed at all).
- **Keep as designed, no task:** 12 (the plan gives Wren "average speed", and the 4 % balance holds; Wren against Cinder is an owner feel item), 13 (the plan's protocol is the rival driver; handling feel is an owner item), 14 (slot skills are the G4 design and give a fixed difficulty spread).
