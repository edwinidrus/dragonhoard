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
python3 scripts/dragonhoard.py --help   # CLI: init | next | log | digest | check | hook | lesson | mode | delegate | verify
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
4. `explore` fans out the roles.
5. `learn` gates lessons.
6. `models` has the current model suggest a model per role; the owner confirms.

**Roles** (`ROLES` in the script; bodies in `agents/*.md`):
- `scout` does read-only retrieval.
- `spiker` builds one throwaway prototype per option, in an isolated worktree.
- `judge` advises only: it can add warnings, but it can never clear a screen failure or approve.

Models are per role in `dragonhoard.json` `models`. The frontmatter `model:` in `agents/*.md` is
only the Claude Code default (haiku/sonnet/opus tier aliases). Never hardcode concrete model
names anywhere else.

**Multi-host.** Claude Code uses the plugin directly. For OpenCode, Codex, Cline and generic
`AGENTS.md` agents, `dragonhoard.py install --host <h>`:
- copies `scripts/`, `templates/`, `assets/`, `skills/` and `agents/` to `<project>/.dragonhoard/`;
- renders skills as `dragonhoard-<name>`, with `${CLAUDE_PLUGIN_ROOT}` paths rewritten to the
  copied CLI;
- renders role agents (OpenCode md, Codex TOML) with the configured models;
- upserts a marker block into the host rules file.

**All host differences live in `HOSTS` and `cmd_role`.** Skills stay host-neutral: they say
"ask the owner and wait (Claude Code: AskUserQuestion)" and "follow `dragonhoard.py role <r>`".
On hosts without per-agent models, the judge pauses so the owner can switch models (owner
decision). Host facts and their sources are in `docs/hosts.md`; update it whenever `HOSTS`
changes.

**Two delivery modes** (`dragonhoard.json` `mode`, asked by init; see `docs/modes.md`):
- `solo` (the default) behaves exactly like v0.2.
- `hybrid`: Claude Code orchestrates with `skills/conduct`, and OpenCode builds headless.
  - `delegate` runs `opencode run --format json` with first-event and idle timeouts and retries,
    writes the events to `<root>/logs/sessions/`, and prints only a stats line and the HANDOFF
    block.
  - `verify` re-runs the checks, plus scope, test-weakening and journal checks.
  - The `builder` role exists only in hybrid, and `judge` defaults to `external`. The external
    judge gets no agent file; `role judge` tells the builder to stop with a JUDGE handoff.
  - `install --host opencode` in hybrid also merges `opencode.json`: no `ask` rules (they hang
    headless), git commits denied, skill/task allow-lists, `--mcp-off`.
  - `conduct` is orchestrator-only and is never rendered into a builder host
    (`ORCHESTRATOR_SKILLS`).

The `SessionStart` hook (Claude Code) is in `.claude-plugin/plugin.json` and runs
`dragonhoard.py hook`. Other hosts get the same output through the `AGENTS.md` block
instruction. The hook prints the banner, the role models, the next task and the digest, and
stays silent when `dragonhoard.json` is absent. It renders without writing files, so a session
start never dirties git.

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
- `init` refuses once `dragonhoard.json` has a `root` (it keeps `host` and `models` written by
  `install`). It never overwrites an existing file, and it rejects absolute or `..` roots.
- `install` is idempotent. It touches only `.dragonhoard/`, its own `dragonhoard-*` skill and
  agent files, and the text between `<!-- dragonhoard:start -->` and `<!-- dragonhoard:end -->`.
- Owner decisions:
  - the root folder is always asked, never assumed (offer `implementation/` or `improvement/`);
  - every lesson needs human approval after the judge, which should run on the strongest model;
  - exploration uses parallel subagents, with the cheaper model for retrieval;
  - models are configurable per role: the current model suggests, the owner confirms;
  - on hosts without per-agent models, the judge pauses for a model switch rather than running
    on a weaker model;
  - init always asks the mode: full Claude Code, or Claude Code + OpenCode. In hybrid the
    orchestrating Claude Code session is the judge, and it verifies every builder DONE
    independently.
