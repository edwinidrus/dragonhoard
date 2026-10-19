# dragonhoard

```text
   \/        \/
   (\   ^^   /)     dragonhoard
    \ ( oo ) /~*    plan . explore . verify . build . test . record
     (__vv__)       one task at a time, learning as it goes
      /|  |\
```

A Claude Code plugin that turns your plan into a delivery system. It breaks the plan into
milestones and self-contained task packs, so the agent only loads the context one task needs.
Each session works one task through **plan → explore → verify → build → test → record**.
Append-only logs act as memory across the whole journey. Lessons you approve carry forward to
later tasks.

## Install

```bash
claude --plugin-dir /path/to/dragonhoard     # try it for one session
# or, permanently:
/plugin marketplace add /path/to/dragonhoard
/plugin install dragonhoard@dragonhoard
```

Requires `python3` (stdlib only).

## Use

| Command | What it does |
|---|---|
| `/dragonhoard:init` | Asks where the workspace lives (`implementation/`, `improvement/`, or your choice), confirms your check commands, then scaffolds the root files. |
| `/dragonhoard:shape <plan.md>` | Proposes a milestone cut and waits for your OK. Then writes the milestone folders, `STATUS.md` and task packs for the first milestone. `/dragonhoard:shape M2` writes the next milestone's packs when it comes up. |
| `/dragonhoard:next` | Works exactly one task through the loop, records real evidence, and stops. |
| `/dragonhoard:explore` | For an open choice: cheap parallel retrieval, up to 3 parallel spikes in isolated worktrees, a comparison by a frontier model. You pick; the decision is logged. |
| `/dragonhoard:learn` | Drafts lessons from journals, screens them deterministically, has the judge review them, then asks you to approve each. `revoke L<nn>` removes one. |

At session start, a hook prints the next task and the memory digest. It stays silent in projects
without `dragonhoard.json`.

## What it creates in your project

```text
dragonhoard.json              # {"root": "...", "checks": [...]}
<root>/
├── README.md CONSTITUTION.md STATUS.md
├── DIGEST.md LESSONS.md      # generated from the logs
├── logs/events.jsonl         # what happened, across the journey
├── logs/lessons.jsonl        # lesson ledger: approved, rejected, revoked
├── templates/                # TASK.md + phase skeletons
└── M<n>-<name>/{CONSTITUTION,PLAN,PROGRESS,GATE}.md, tasks/<pack>.md, tasks/<pack>.journal.md
```

## Models

| Agent | Model | Job |
|---|---|---|
| `scout` | haiku | Read-only fact retrieval with sources. Cheap, run in parallel. |
| `spiker` | sonnet | One throwaway prototype per option, each in its own git worktree. |
| `judge` | opus | Compares spike evidence and reviews lessons. Advises only: it can add warnings, never approve. |

Every lesson passes four gates: deterministic screen → opus judge → **your approval** → used
from the next task on. Nothing is approved automatically.

The design comes from the hand-built EpisAlpha `implementation/` workspace, generalized.
