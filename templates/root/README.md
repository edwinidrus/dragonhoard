# Implementation workspace

This folder is the **operational layer** of the build, managed by dragonhoard. The owner's plan stays
the source of intent. This folder breaks it into milestone folders and self-contained task
packs, so a coding agent loads only the context one task needs.

## Layout

```text
{{root}}/
├── README.md            # this file: the session protocol
├── CONSTITUTION.md      # global articles; binding on every milestone and task
├── STATUS.md            # one row per task across all milestones; the "next task" pointer
├── DIGEST.md            # generated memory digest (dragonhoard.py digest); never hand-edited
├── LESSONS.md           # approved lessons (dragonhoard.py lesson); never hand-edited
├── logs/events.jsonl    # append-only event log, one JSON line per event
├── logs/lessons.jsonl   # append-only lesson ledger
├── templates/           # skeletons for new milestones and task packs
└── M<n>-<name>/
    ├── CONSTITUTION.md  # milestone articles; inherits ../CONSTITUTION.md
    ├── PLAN.md          # goal, scope, task order, dependencies, owner decisions
    ├── PROGRESS.md      # Task | Status | Changes | Verification | Blocker | Next
    ├── GATE.md          # gate commands, criteria checklist, results log
    └── tasks/
        ├── M<n>-T<nn>-<slug>.md          # task pack
        └── M<n>-T<nn>-<slug>.journal.md  # append-only attempt log, created at first attempt
```

## Session protocol (one task per session)

1. **Pick.** `dragonhoard.py next` returns the task in progress, or the first `TODO` row of
   [STATUS.md](STATUS.md) whose dependencies are all `DONE`. Never take two tasks at once.
2. **Load exactly this context, nothing more:**
   - [CONSTITUTION.md](CONSTITUTION.md), [DIGEST.md](DIGEST.md) and [LESSONS.md](LESSONS.md)
   - the milestone `CONSTITUTION.md`
   - the task pack
   - the files the pack names under "Context to load"
3. **Work the loop in order. Do not skip a step.**

   | Step | What it means |
   |---|---|
   | **Plan** | Restate goal, scope and files in a few lines. If the pack is wrong or stale, stop and report it. |
   | **Explore** | Only when the pack lists an open option or Verify hits an unknown. Retrieve facts cheaply; spike at most 3 options in parallel; the owner picks. |
   | **Verify** | Before building: every upstream interface the pack names exists; the checks are green; the focused test is written first and fails for the expected reason. |
   | **Build** | Smallest change that satisfies acceptance. Stay inside the pack's file list. |
   | **Test** | Focused test, then the standard checks. Tick every acceptance item. |
   | **Record** | Journal entry, `PROGRESS.md` row with real output, `STATUS.md` row, event line, digest, `dragonhoard.py check`. |

4. **Stop.** Report the next task. Commits are an owner action.

### Standard checks

{{checks}}

### Status values

`TODO` · `IN_PROGRESS` · `DONE` (acceptance passed, real output recorded) · `BLOCKED` (reason
and owner action in the Blocker column) · `DONE_OFFLINE` (offline acceptance passed, a live part
is still open).

### BLOCKED rules

Stop and report `BLOCKED` when any of these happens:
- an upstream interface is unverified or differs from the pack;
- a credential for a required live check is missing;
- a contract conflicts;
- the task needs an unapproved architectural change;
- two bounded attempts at the same issue have failed. The journal is the evidence for this.

## Journal entry format

Append one block per attempt to `tasks/<task>.journal.md`. Never edit earlier blocks.

```markdown
## Attempt N — YYYY-MM-DD HH:MM UTC — <model id that did the work>
- Hypothesis: what I expected this change to achieve
- Explored: options tried and the evidence (omit if none)
- Did: files touched, in one line each
- Ran: `exact command` -> real result (shortest decisive line)
- Outcome: PASS | FAIL | BLOCKED
- Root cause (if FAIL): what was actually wrong, with evidence
- Decision: what I chose next and why
```

## Event kinds (`logs/events.jsonl`)

`task.started` · `attempt` · `option.chosen` · `task.blocked` · `task.done` · `gate.run` ·
`lesson.approved` · `lesson.rejected` · `lesson.revoked`.

The journal explains *why*; the event log lets the next session see *what happened* across the
whole journey without reading every journal. `DIGEST.md` is the compact view of both.
