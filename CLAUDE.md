# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

**dragonhoard** is a Claude Code plugin: a planning harness for coding agents. It takes a user's plan
and shapes it into milestones and self-contained task packs, so the agent loads only one task's
context. It runs one task per session through plan → explore → verify → build → test → record. It
keeps append-only logs as memory and learns gated lessons. Mascot: a cute dragon
(`assets/dragon.txt`); the dragon comes from the owner's origin. The name **dragonhoard**
was chosen to avoid a trademark conflict: use exactly this name in every file, command, folder
and identifier, and do not invent variants.

The design generalizes the hand-built workspace at `/home/edwinidrus/hobbys/EpisAlpha/implementation`.
Read it when changing the protocol or the templates. Copy its structure and process, never its
domain articles (Hermes, SQLite, Phoenix and the rest).

## Commands

```bash
python3 tests/test_dragonhoard.py       # the only test: assert-based self-check, prints "ok"
claude plugin validate .                # manifest check (the CLAUDE.md-at-root warning is expected)
claude --plugin-dir .                   # load the plugin for one session, e.g. from a scratch project
python3 scripts/dragonhoard.py --help   # CLI: init | next | log | digest | check | hook | lesson
```

There is no lint config and no dependencies. `scripts/dragonhoard.py` must stay stdlib-only.

## Architecture

The work is split between two halves:

- **Skills reason** (`skills/<name>/SKILL.md`, invoked as `/dragonhoard:<name>`).
- **`scripts/dragonhoard.py` owns everything that must not drift:**
  - next-task selection (STATUS.md table and gate dependencies);
  - the append-only `events.jsonl` and `lessons.jsonl`;
  - `DIGEST.md` (capped at 150 lines) and `LESSONS.md`, both generated;
  - STATUS/PROGRESS consistency and missing-file checks;
  - the deterministic lesson screen.

  Skills call it as `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/dragonhoard.py"`.

Flow:
1. `init` runs `dragonhoard.py init`. It copies `templates/root/*` into `<root>/` and
   `templates/skeletons/**` into `<root>/templates/`, filling `{{root}}`, `{{checks}}` and
   `{{date}}`.
2. `shape` fills the skeletons per milestone.
3. `next` runs the loop.
4. `explore` fans out the agents.
5. `learn` gates lessons.

Agents (`agents/*.md`) are pinned to models by owner decision:
- `scout` runs on haiku and does read-only retrieval.
- `spiker` runs on sonnet, one per option, launched with `isolation: "worktree"`.
- `judge` runs on opus. It advises only: it can add warnings, but it can never clear a screen
  failure or approve.

The `SessionStart` hook is in `.claude-plugin/plugin.json` and runs `dragonhoard.py hook`. It
prints the banner, the next task and the digest, and stays silent when `dragonhoard.json` is
absent. It renders without writing files, so a session start never dirties git.

## Invariants to keep

- The markdown table formats are parsed by regex:
  - STATUS: `| # | Task | Title | Status | Depends on | Pack |`, plus a Gates table.
  - PROGRESS: `| Task | Status | Changes | ... |`.
  - Task IDs are `M<n>-T<nn>[a-z]`.

  If you change a template, update the parser and `tests/test_dragonhoard.py` in the same change.
- Skeleton placeholders like `M<n>-T01` must not match the task-ID regex. Otherwise the
  templates would pollute `check`.
- `lesson approve` re-screens the text and refuses on any violation. Secret matches are masked
  in screen output and redacted in the ledger.
- `init` never overwrites `dragonhoard.json` or any existing file, and rejects absolute or `..` roots.
- Owner decisions:
  - the root folder is always asked, never assumed (offer `implementation/` or `improvement/`);
  - every lesson needs human approval after the opus judge;
  - exploration uses parallel subagents, with the cheaper model for retrieval.
