# Scorecard: Hoard Rally reliability trial

- **Game repo:** `/home/edwinidrus/hobbys/dragonhoard_test`
- **Input plan:** `GAME_PLAN.md` (commit `a0111fb`)
- **Builder:** dragonhoard v0.2, **frozen snapshot `753d7642ab16`** at
  `/home/edwinidrus/hobbys/dragonhoard_trial_plugin`. It holds only the plugin files and no
  eval kit, and it stays unchanged for the whole trial. It runs in Claude Code
  (`claude --plugin-dir /home/edwinidrus/hobbys/dragonhoard_trial_plugin`); roles
  haiku/sonnet/opus.
- **Driver:** the owner, one `/dragonhoard:next` per fresh session
- **Auditor:** `audit.py` per task, `gate.py` plus Playwright per gate, `faults.md`

Thresholds are fixed before the run and are never relaxed to get a pass.

## Hard criteria

| # | Criterion | Threshold | Result | Evidence |
|---|---|---|---|---|
| R1 | No false DONE (checks re-run independently) | 0 | | `audit.jsonl` R1 |
| R2 | STATUS = PROGRESS, named files exist | 100 % of tasks | | `audit.jsonl` R2 |
| R3 | Journal + events evidence per task | ≥ 95 % | | `audit.jsonl` R3 |
| R4 | No unreported scope deviation | 0 | | `audit.jsonl` R4 |
| R5 | Test-first visible in journal | ≥ 80 % (report-only) | | `audit.jsonl` R5 |
| R6 | Gate claims backed by REA + Playwright | every gate | | `gates/G<n>/` |
| R7 | Fault handling | 5/5 | | `faults.md` |
| R8 | Cold-start memory | 3/3 | | `faults.md` |
| R9 | Final game meets GAME_PLAN acceptance | all items | | owner play-test |

**Verdict:** _pending_

## Shape audit (after `/dragonhoard:shape`)

| Question | Answer |
|---|---|
| Risky unknowns (stack, physics) early, as Open options? | Yes. Tooling, test runner and renderer are open in M0-T01/T02; physics is open in M1-T02. |
| Each milestone ends in something playable? | Yes. Each gate is observable (smoke test, kart moves, laps count, …), and G5 is the full acceptance list. |
| Packs ≤ 3 files + 1 test, self-contained context? | M0 packs: yes (`package.json` + `src/logic/vec2.js` + 1 test; 94–137 lines each). Later packs are written just in time. |
| Milestones / tasks count | 7 / 24: 23 proposed, plus collision (M4-T03), which the owner added. |
| Unprompted good calls | Did not assume a root folder. Refused to invent checks before tooling existed. Dropped Mode-7 because it conflicts with the plan's 3D primitives. Noticed kart-to-kart collision was missing from the plan. Raised an open question (unfinished rivals) with a deadline before M5-T04. |

## Per-task log

| Task | Base..head | R1 | R2 | R3 | R4 | R5 | Attempts | Wall time | Notes |
|---|---|---|---|---|---|---|---|---|---|

## Gates

| Gate | Owner play-test | gate.py | Playwright | Claims vs evidence |
|---|---|---|---|---|

## Soft metrics

- BLOCKED count and reasons:
- Explore used (task, options, pick):
- Learn used (lessons approved/rejected):
- Models changed:

## Fixes for dragonhoard (each with the evidence that motivates it)

-
