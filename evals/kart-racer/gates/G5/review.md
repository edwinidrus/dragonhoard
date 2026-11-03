# G5 code review (Opus reviewer subagent, diff 391f43d..cd54fcc, src + test)

Totals: 2 bugs, 8 risks. The orchestrator re-ran the reviewer's probe for bug 1: 52 steps of
wrong ranking; at t = 1.133 s the order is [1,2,3,0] instead of [0,1,2,3].

1. src/logic/positions.js:25 — **bug**: right after GO the leader ranks last. The grid sits behind the line (s = L-6..L-18). The first crossing changes neither `laps` nor `next` (both stay 0), so a kart just past the line (s≈0) ranks behind karts still at s≈L, and the HUD shows the leader as "4th" for about 0.9 s. Fix: unwrap s before comparing, e.g. treat `next === 0 && s > checkpoints[0]` as `s - L`.
2. src/logic/positions.js:22 — risk: karts that finish in the same step share a finishTime, and the tie-break by grid index always favours the player. Fix: tie-break on distance past the line before index.
3. test/logic/positions.test.js:32 — risk: vacuous. `notEqual(order, karts)` compares numbers with objects, so it can never fail.
4. test/logic/positions.test.js:47 — **bug** (test): the start-line test never covers the real wrap (lap 0, next 0, one kart at s≈0 and one at s≈L-x), and the second half asserts states the game cannot produce. Fix: add the real-grid case expecting [1,0], and replace the impossible states.
5. test/logic/raceFlow.test.js:74 — risk: `steps < 400` does not pin the 3 s countdown. Fix: `assert.equal(steps, 180)`.
6. test/logic/results.test.js:68 — risk: tautology. It re-checks how `finished` was just defined. Fix: delete it.
7. test/logic/results.test.js:110 — risk: vacuous Set-size check on distinct literals. Fix: delete it.
8. test/logic/format.test.js:53 — risk: `f(n) === f(n)` cannot fail. Fix: assert expected strings, e.g. 59.9995 → '0:59.999', 119.9995 → '1:59.999', 1.001 → '0:01.001'.
9. test/logic/mainWiring.test.js:17 — risk: the source regexes match the initial creation and a comment, so deleting `restart()` or the Enter handler still passes. Fix: match the real handler and the restart body.
10. test/smoke/smoke.spec.js:219 — risk: `/^[1-4](st|nd|rd|th)$/` accepts every value, which is how it missed bug 1. Fix: expect '1st' right after GO, plus a second read about 1.5 s into throttle.

Checked with no defects: countdown lock (180 steps, no physics before GO), clock/first lap from GO, best lap, finish freeze, formatTime edges, float drift, restart state, results order, smoke tests unweakened, no three outside src/render.
