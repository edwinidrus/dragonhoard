# G7 code review (Opus reviewer subagent, diff d6361e7..97f5949, src + test)

The reviewer read M7 HEAD 97f5949 only (no commands run). The auditor saved its report here and
spot-checked the bug (`trackMesh.js:15` gives n=0, so s = s0 + 0/0 = NaN), the ember gating
(`ember.js` pickup, fire and hit never check fall or air) and the scenery clearance (rocks up to
4 m in radius, 9 m from the nearest centreline, half-width 6 m).

Totals: 1 bug, 8 risks, 9 test gaps, 2 questions.

## Bug
1. src/render/trackMesh.js:36 — bug: two touching jumps, or a jump with at=0, make roadSpans emit a zero-length span; ribbon (trackMesh.js:15) gets n=0, s becomes NaN and pointAt throws. createTrack accepts these (track.js:132 rejects only strict overlap; trackFeatures test 6 blesses touching), so startRace (main.js:64) throws and the menu stays up. Not in the shipped Lantern data. Fix: skip spans with s1 <= s0, or reject touching jumps and at=0 in createTrack.

## Risks
2. src/logic/race.js:111 — the fall trigger is `>` with no tolerance; a kart exactly tangent to a bridge edge can fall on ulp-level noise. Fix: `> halfWidth - KART_RADIUS + 1e-9`.
3. src/logic/jumps.js:8 — crossesStart needs prevS < jump.s[0], never true for at=0, so a jump on the lap line is never flown or fallen. Fix: reject at=0, or handle the wrap.
4. src/logic/race.js:45 — safeS is seeded at the grid (about L-6, behind the line) until the first ground step. Fix: assert grid slots pass safeForSetback in createTrack, or seed from the first safe point.
5. src/logic/race.js:58 — the set-back ignores other karts; a respawn onto a rival is pushed by collision.
6. src/logic/ember.js:54/63/78 — pickup, fire and hits apply to falling or airborne karts (the player can fire mid-fall; rivals mid-air can be hit). Fix: gate on !fall.falling && !air.
7. src/main.js:68 — the old trackMesh, embers and scenery are removed but never disposed, so GPU memory grows on each menu-to-race cycle. Fix: dispose geometry and materials recursively.
8. src/main.js:148 — airborne karts are drawn at road height, so jumps show no arc.
9. src/render/sceneryData.js:9 — clearance is measured to the centreline only (scenery.test.js:42); a rock of radius up to 4 m can overlap an adjacent road section. Fix: add scale (and halfWidth) to the margin check against every section.

## Test gaps
10. test/logic/falls.test.js:191 — the rival assertion passes whether or not the rival fell (a frozen rival keeps speed 15 > 10). Fix: assert it moved, or check its falls.
11. test/logic/falls.test.js:209 — named "off a bridge" but uses Ember at s=300 (no bridge); no Lantern bridge-edge test at entry or at the exact limit, so `>` → `>=` survives.
12. test/logic/falls.test.js:195 — "without crossing a checkpoint": laps are {0,0} and no fall step crosses a checkpoint. Fix: an authored checkpoint on a bridge.
13. src/logic/race.js:88 — no test puts a rival on an airborne kart, so removing `!entry.air` from movers survives.
14. src/render/trackMesh.js:32 — roadSpans, without and ribbon are untested (the bug above is unguarded).
15. test/logic/mainWiring.test.js:43 — `[\s\S]*?` lets the regex run into later functions; same for startRace.
16. src/ui/hud.js:54 — the best-lap min logic and main.js's recordBest call are untested in Node; smoke never asserts the best lap.
17. src/render/scene.js:50 — the setSky mapping is untested.
18. test/logic/bestLaps.test.js:23 — an equal lap checks value only, so `<=` → `<` survives. Fix: assert identity.

## Questions
19. src/logic/race.js:111 — a rival bump on a bridge edge can push the player off: intended?
20. src/logic/jumps.js:12 — an ember-slowed kart (about 11 m/s, below minSpeed 12/14) always falls at a jump while slowed: intended?
