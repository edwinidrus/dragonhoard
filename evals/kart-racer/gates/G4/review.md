# G4 code review (Opus reviewer subagent, diff 618b78b..M4-T04, src + test)

Totals: 1 bug, 7 risks. The orchestrator confirmed the first three by reading the code.

1. src/logic/kartCollision.js:28 — risk: when two karts sit on the same spot, the fallback normal is the same for either pair order, but a always gets -n and b +n. So swapping the pair swaps their pushes (breaks M4 art. 4). Fix: flip n when the pair is swapped.
2. src/logic/rival.js:44 — risk: steering assumes forward motion, but stepKart reverses the turn when speed < 0. After a head-on bump, a reversing rival steers away from its target. Fix: steer * sign(speed).
3. test/logic/race.test.js:108, test/logic/kartCollision.test.js:180 — **bug**: `worstStall` keeps the current slow streak, not the longest one, so the "never stuck" check cannot fail. Fix: keep the max streak.
4. src/main.js:14 — risk: `RIVALS` duplicates race.js defaults. Retuning race.js would not change the game, and the tests run different values. Fix: one source of truth.
5. test/logic/kartCollision.test.js:167 — risk: `contactSteps` is only logged (it is 0), so "collision on" never makes karts touch. Fix: assert contact > 0, or force a shared lane.
6. test/logic/kartCollision.test.js:174 — risk: the "no stacking" check requires every pair to stay > 2 m apart at every step, which contradicts contact at 1.4 m. It passes only because nothing ever touches. Fix: assert that the max pair distance per step is > 2.
7. test/logic/kartCollision.test.js:193, race.test.js:126, rival.test.js:62/:128 — risk: |lateral| is read after containment has clamped it, so "no kart off the road" cannot fail. Fix: assert wallContacts === 0, or check before containment.
8. test/logic/rival.test.js:101 — risk: `Math.sign(lateral) === 0` for lane 0 needs exactly +0, so it is fragile. Fix: skip the sign check at lane 0.

No three.js import outside src/render. The lap/checkpoint flow, the collision maths when the centres are apart, and the curvature are correct. 22/22 M4 tests pass.
