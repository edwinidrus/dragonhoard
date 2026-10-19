---
name: shape
description: >
  Turn the owner's plan into dragonhoard milestones and self-contained task packs (divide and
  conquer). Proposes the milestone cut first and writes nothing until the owner confirms. Also
  writes the packs for the next milestone when it becomes current. Use when the user says
  "shape this plan", "break this plan down", "make milestones", or invokes /dragonhoard:shape
  [plan file | milestone ID].
---

# dragonhoard shape

CLI: `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/dragonhoard.py"` (called `dragonhoard.py` below).
Arguments: $ARGUMENTS. That is a plan file path, a milestone ID such as `M2`, or empty (then ask
for the plan).

Requires `dragonhoard.json`. If it is missing, run `/dragonhoard:init` first. `<root>` is its `root`
value.

## A. First shape (a plan file or pasted plan)

1. **Read the whole plan.** Also read `<root>/CONSTITUTION.md`, `<root>/README.md`,
   `<root>/LESSONS.md` and the skeletons in `<root>/templates/`. If the project already has
   code, have one `dragonhoard:scout` map the existing structure; do not read it all yourself.

2. **Propose the milestone cut, and write nothing yet.** Present `M0..Mn`. For each milestone
   give:
   - its goal, as one observable sentence;
   - why it comes in this order (what it unblocks);
   - its gate criterion (how we know it works end to end);
   - its rough tasks (titles only).

   Rules for the cut:
   - M0 is foundation: the project runs, the checks run, and the first test passes.
   - Each milestone ends in something runnable.
   - Contracts and interfaces come before their consumers.
   - Risky unknowns come early, as tasks with Open options.
   - Anything the plan calls "later" or "nice to have" goes into a final milestone, or out of
     scope.

   Confirm with AskUserQuestion: approve, or adjust (the owner says what to change via
   "Other"). Repeat until approved. Log the approved cut:

   ```bash
   dragonhoard.py log - shape.approved "<n> milestones: M0 <name>, M1 <name>, ..."
   ```

3. **Write the milestone folders.** For every milestone, create `<root>/M<n>-<slug>/`. Copy the
   files in `<root>/templates/phase/` into it and fill them in:
   - `PLAN.md`: goal, why, a task table, owner decisions, out of scope.
   - `CONSTITUTION.md`: only the rules specific to this milestone, such as its contracts,
     boundaries and traps. Leave the article list empty rather than invent rules.
   - `PROGRESS.md`: one `TODO` row per task, with the planned files in backticks.
   - `GATE.md`: the gate commands and the criteria checklist.

4. **Write task packs for the first milestone only.** Copy `<root>/templates/TASK.md` to
   `<root>/M0-<slug>/tasks/M0-T<nn>-<slug>.md` for each task. Later milestones get packs when
   they become current (section B). Packs written early go stale.

   Every pack must be self-contained:
   - **Context to load** names the exact files, and copies the plan excerpts the task needs,
     with section references. A coding agent must never need to open the whole plan.
   - **Files**: 1–3 implementation files plus one focused test. Split anything bigger.
   - **Consumes** points at real `path:line` locations for code that exists. For code an earlier
     task will produce, give the task ID and the planned signature.
   - **Open options** lists every unresolved choice: library, storage, algorithm, API shape.
     Those choices get explored in the loop instead of guessed.
   - **Acceptance** lists observable checks, never "works well".

5. **Write `STATUS.md`.** Add one row per task across all milestones, in execution order:
   `| # | M<n>-T<nn> | title | TODO | deps | [pack](M<n>-<slug>/tasks/...) |`. Use `—` for the
   pack while it is unwritten. Add one row per gate: `| G<n> | not started | [GATE](M<n>-<slug>/GATE.md) |`.
   The first task of milestone M<n>, for n ≥ 1, depends on `G<n-1>`.

6. **Verify and hand off.**

   ```bash
   dragonhoard.py check     # must PASS: STATUS and PROGRESS agree
   dragonhoard.py next      # must name M0-T01
   dragonhoard.py digest
   ```

   Report the milestone list and the first task. Then suggest `/dragonhoard:next`.

## B. Next milestone (`/dragonhoard:shape M<n>`)

Run this when `dragonhoard.py next` reaches a task with no pack.

1. Read `<root>/M<n>-<slug>/PLAN.md`, `DIGEST.md`, `LESSONS.md`, the previous milestone's
   `GATE.md` results, and the `option.chosen` events that affect this milestone. Reality has
   moved since the first shape; the packs must reflect what was actually built.
2. If the tasks no longer fit (scope, order or contracts changed), propose the change and
   confirm it with AskUserQuestion before writing anything.
3. Write the packs as in A.4. Fill the `[pack]` links in `STATUS.md` and the milestone's
   `PLAN.md`. Log `dragonhoard.py log - shape.milestone "M<n>: <k> packs"`, then run `check`.
