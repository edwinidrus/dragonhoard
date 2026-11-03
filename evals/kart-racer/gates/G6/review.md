# G6 code review (Opus reviewer subagent, diff 0dd5686..5569c8c, src + test)

Totals: 0 bugs, 4 risks.

1. src/logic/controls.js:15 — risk: Shift is read as a level once per fixed step, so a tap that starts and ends between two steps is missed (rare at human tap lengths; more likely above 60 Hz, when `advance` returns 0 steps). Fix: src/input/keyboard.js keeps a "pressed since last read" flag for Shift, ORs it into `item`, and clears it when a step consumes it.
2. src/logic/ember.js:38 — risk: the slow countdown `Math.max(0, left - dt)` has no `<= 1e-9` guard, unlike the respawn at L44. With slowSeconds 0.5/1.5/2/2.5/3 a ~1e-15 remainder keeps the rival slowed one extra step, and test/logic/ember.test.js:187 would then fail after a retune. Fix: `const v = left - dt; return v <= 1e-9 ? 0 : v;`
3. test/logic/ember.test.js:186 — risk: "the slow runs out" only checks `slow === 0` after `round(slowSeconds/STEP)` steps, so a slow that expires early still passes. Fix: step `steps - 1`, assert it is still slowed, then step once more and assert 0.
4. test/logic/ember.test.js:266 — risk: the purity check freezes a fresh race and steps once with no pickup, fire or hit, so a mutation in those branches would pass. Fix: also deep-freeze an ember mid-action (held item, player on an active box, a shot on a rival, an expired box) and step it.

Clean: no self-hits, no tunnelling (≤0.95 m closure per step vs a 2.6 m hit diameter), respawn of exactly 180 steps, one item max, no auto-fire while held, rivals ignore `item`, no items before GO or after the finish, restart clears everything, stepKart unchanged at slow=1, smoke tests append-only, three only in src/render, 161/161.
