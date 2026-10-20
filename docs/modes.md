# Delivery modes

`/dragonhoard:init` asks which mode to use and stores it as `"mode"` in `dragonhoard.json`. You
can change it later with `dragonhoard.py mode <solo|hybrid> --why "..."`. The change is logged as
`mode.changed`.

| | **Solo: full Claude Code** | **Hybrid: Claude Code + OpenCode** |
|---|---|---|
| Who builds each task | this Claude Code session (`/dragonhoard:next`) | a headless OpenCode session on the `builder` model, started by `dragonhoard.py delegate` |
| Scout / spiker | Claude subagents (haiku / sonnet) | OpenCode subagents (`dragonhoard-scout`, `dragonhoard-spiker`), usually on the builder's model |
| Judge | the opus judge subagent | **external**: the Claude Code session itself |
| Verification | the builder's own checks, plus the gates | the same, plus `dragonhoard.py verify` after every task: checks re-run, scope, weakened tests, journal |
| Claude tokens | every step | judgement, verification, gates and escalations only |
| Best when | quality comes first and the budget is fine | you want to save Claude tokens and still get a frontier-level reviewer |

Outside Claude Code (OpenCode, Codex, Cline and others used on their own), the mode is always
solo. See [hosts.md](hosts.md).

## How hybrid works

```text
Claude Code (orchestrator, /dragonhoard:conduct)            OpenCode (builder, headless)
  dragonhoard.py next            -> task M2-T03
  dragonhoard.py delegate "Use the dragonhoard-next skill."  -> works the task with the
                                                                dragonhoard-next skill
  <- stats line + HANDOFF block (status, files, checks, questions, judge request, risks)
  JUDGE?    judge here, reply with delegate --session <id>
  QUESTION? ask the owner, reply with delegate --session <id>
  DONE?     dragonhoard.py verify M2-T03 -> PASS: owner checkpoint -> next task
                                          -> FAIL: one retry with the FAIL lines
  2nd FAIL? log task.escalated and work the task here with /dragonhoard:next (solo for one task)
  gate:     run GATE.md, review the milestone diff, the owner plays it
```

Why it saves tokens:
- `delegate` prints only one stats line and the HANDOFF block. The transcript goes to
  `<root>/logs/sessions/` and never enters the orchestrator's context.
- The builder's model can be free. The orchestrator spends tokens only on decisions and checks.

Why quality holds:
- The builder still follows the dragonhoard loop: small packs, test first, journals, gates.
- The orchestrator never trusts a DONE. `verify` re-runs the checks, compares the changed files
  with the pack, and catches deleted assertions and new `.skip`/`.only` marks.
- The frontier model still judges every option pick and every lesson. Repeated failures move to
  the frontier model instead of looping.

## Setup

1. Install OpenCode, and check `opencode --version` (2.x tested) and `opencode models`.
2. In Claude Code, with the plugin loaded, run `/dragonhoard:init` and choose **Claude Code +
   OpenCode**. Init runs:

   ```bash
   dragonhoard.py init --root implementation --mode hybrid --check "<checks>"
   dragonhoard.py install --host opencode --mcp-off <servers the builder must not see>
   dragonhoard.py models --set builder=opencode/<model> scout=opencode/<model> spiker=opencode/<model>
   ```

3. Shape and work through the plan with `/dragonhoard:conduct`.

What `install` writes to the project `opencode.json` (it is merged; your other keys stay):
- `model`: the builder model.
- `permission`:
  - edits are allowed;
  - shell is allowed, but `git commit|push|reset|checkout|rebase|clean` and `rm -rf` are
    denied;
  - `external_directory` and the interactive `question` tool are denied.
  - No rule is `ask`, because a headless run would wait forever.
- `skill` and `task` allow-lists: only `dragonhoard-*` skills and agents, plus the superpowers
  discipline skills, are visible. A builder can't wander into skills that commit or plan
  differently.
- `mcp.<name>.enabled = false` for every server passed to `--mcp-off`.

Free tiers have usage limits (OpenCode Zen answers `FreeUsageLimitError`). `delegate` treats a
limit as a wait, not a failure:
- it probes every `--quota-wait` seconds (900);
- it steps a `#variant` effort down one level per limit, but never below `effort_floor` (default
  `high`);
- after `--quota-patience` (6 h) it exits with code 3, `RATE-LIMITED`.

The free models on OpenCode Zen may use prompts to improve the model. Keep secrets out of the
repository, and turn off MCP servers that reach personal data.

## Measured cost

From the Hoard Rally trial (`evals/kart-racer/scorecard.md`). Costs are list-price equivalents,
taken from session usage.

| Phase | Mode | Tasks | Builder | Orchestrator | Per task |
|---|---|---|---|---|---|
| A (M0–M3) | solo, Claude Code builder (opus/sonnet/haiku) | 14 + 3 gates | $72.45 (Opus 95 %) | ≈ $64 (context median 296K tokens) | ≈ $9.8 |
| B (M4–M9) | hybrid, OpenCode `deepseek-v4.1-flash-free` | in progress | — | — | — |

Phase A taught the main lesson: the orchestrator's context, not its output, is half the bill.
Hybrid addresses both halves. The builder is free, and the orchestrator reads short handoffs.
