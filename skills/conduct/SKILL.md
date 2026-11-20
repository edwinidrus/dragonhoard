---
name: conduct
description: >
  Run dragonhoard tasks back to back until a gate, from Claude Code. Each task is built in a
  fresh builder context (an OpenCode session in hybrid mode, a builder subagent in solo mode),
  then verified, reviewed and checkpointed by this session. Answers judge requests, escalates
  repeated failures and runs the gates. Use when the user says "conduct", "run the milestone",
  "keep going until the gate", "continue the plan" in hybrid mode, or invokes
  /dragonhoard:conduct.
---

# dragonhoard conduct

CLI: `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/dragonhoard.py"` (called `dragonhoard.py` below).
Works in hybrid mode, and in solo mode on Claude Code. To work a single task yourself, with the
owner watching each step, use `/dragonhoard:next` instead.

You are the orchestrator. Every task gets a fresh builder context, so one task never sees
another's context. You keep the judgement and the checks. Hard rules:
- Read only what the builder hands back: the HANDOFF block (and the stats line in hybrid). Never
  open the transcripts in `<root>/logs/sessions/` unless you are debugging a failure.
- Never write code that belongs to a task, except when escalating (step 4).
- Decisions that belong to the owner stay with the owner: option picks, lessons, gates, pack
  amendments, rule overrides. Ask with AskUserQuestion. Relay the builder's evidence in a few
  lines, not its whole reply.
- Do not stop between tasks to ask whether to continue. Stop only for the reasons in step 6.
- Roles: always run `dragonhoard.py role <judge|reviewer>` and do what it prints. It knows the
  mode: in hybrid it tells you that you are the judge yourself. This also holds inside skills you
  run yourself (`shape`, `explore`, `learn`).

## 0. Before the first task

```bash
dragonhoard.py role builder        # how to start and resume the builder in this mode
git branch --show-current && git status --short
```

- `role builder` prints the transport. In hybrid it is `dragonhoard.py delegate "<prompt>"`, and
  `--session <id>` continues a session. In solo it is a `dragonhoard:builder` subagent, and
  SendMessage continues it. Below, "send the builder" and "reply in the same session" mean
  whichever one it printed.
- This skill commits a checkpoint after every task that passes verify and review. It never
  pushes. If the branch is the default branch, ask the owner once: create a work branch, or
  stay.
- If the work tree holds changes that belong to no task, ask the owner to commit or stash them
  first. A checkpoint commits everything that is pending.

## 1. Send one task

```bash
dragonhoard.py next                       # which task, or why none is ready
dragonhoard.py lint <task>                # FAIL: the pack is stale; do not send it
```

Then send the builder the task, exactly one per builder context. In hybrid:
`dragonhoard.py delegate "Use the dragonhoard-next skill."`, and note the `session` id it prints.

When `lint` fails, show the owner the `stale` lines and ask whether to amend the pack; send the
amendment, never the build. When `next` reports a task with no pack, first send
`"Use the dragonhoard-shape skill for M<n>."` (solo: run `/dragonhoard:shape M<n>` yourself) and
treat the result like any other HANDOFF.

## 2. Act on the HANDOFF status

- **JUDGE**: the builder needs a judgement or an explored choice.
  - A request to compare evidence, review lessons or check a plan: read the evidence paths it
    names, and only those. Run `dragonhoard.py role judge` and do what it prints.
  - An open choice with no evidence yet: run `/dragonhoard:explore` yourself; the owner picks.
  - Reply in the same session with the verdict or the choice.
- **QUESTION**: ask the owner, then reply in the same session with the answer. This includes a
  request that breaks a rule: the owner confirms it or drops it.
- **BLOCKED**: read the reason. If the owner can resolve it (a stale pack, a red baseline, a
  missing interface), ask them, then send the fix or the resume. Never unblock it by editing
  code yourself.
- **PARTIAL** at a gate: go to step 5.
- **DONE**: go to step 3.
- **RATE-LIMITED** (hybrid, exit code 3): the provider's limit outlasted `--quota-patience` (6 h
  by default). While it waits, `delegate` probes every 15 min and steps a `#variant` effort down,
  never below `effort_floor` in `dragonhoard.json` (default `high`). It logs each wait as
  `delegate.rate_limited`. Tell the owner, and offer a different builder model through
  `/dragonhoard:models`; never switch on your own. Resume with `--session <id>`.
- **OUT-OF-CREDIT** (hybrid, exit code 4): the provider's spending cap is reached, and waiting
  does not lift it. Tell the owner and stop. After a top-up or a builder change through
  `/dragonhoard:models`, resume with `--session <id>`.
- **No HANDOFF**: ask once in the same session:
  `"Report where you are. End with the HANDOFF block."` If that also fails, count it as a failed
  attempt (step 4).

## 3. Verify, review, checkpoint

Never trust a DONE.

```bash
dragonhoard.py verify <task>              # base defaults to HEAD: the uncommitted task work
```

It re-runs every check, compares the changed files with the pack's Files, and flags weakened
tests, a missing journal and a failed attempt with no root cause.

- **verify FAIL**: reply in the same session:
  `"verify failed: <the FAIL lines>. Fix only that, then end with the HANDOFF block."` This is
  attempt 2.
- **verify PASS**: review. Run `dragonhoard.py role reviewer` and do what it prints: it names the
  reviewer subagent and its model. The pack path is the reviewer's whole prompt, so the diff
  stays out of your context. Never review a task yourself.
  - Verdict `fix`: run `dragonhoard.py log <task> review.failed "<the critical and important lines>"`,
    then reply in the same session: `"review: <those lines>. Fix only these, then end with the
    HANDOFF block."` This is attempt 2. Verify and review again afterwards.
  - Verdict `approve`: run `dragonhoard.py log <task> review.passed "<n> minor: <one line each, or none>"`.
- **Checkpoint**:

  ```bash
  dragonhoard.py checkpoint <task>        # refuses unless verify, then review, passed
  ```

  It also refuses when the work changed after the last verify: then verify and review again.

  Tell the owner in one line what now works, and go straight to step 1.

## 4. Escalate after two failed attempts

When the second attempt still fails verify or review, stop sending this task to the builder:
1. Log it: `dragonhoard.py log <task> task.escalated "<why, in one line>"`.
2. Work the task yourself in this session by following `/dragonhoard:next`, including its verify
   and review step: the reviewer subagent reviews it, never you. The owner's decisions stay as
   usual. Then checkpoint it as in step 3.
3. Return to step 1 with the next task.

An escalation rate above about one task in four means the builder model is too weak for this
plan. Offer `/dragonhoard:models` to pick a stronger builder.

## 5. Gates

When a milestone's last task is done, or the builder reports PARTIAL for a gate:
1. Run the commands in the milestone's `GATE.md` yourself, and record their results. The builder
   may have run them with the last task; as with verify, run them again instead of trusting the
   record.
2. Review the milestone as a whole before the owner tries it: one reviewer subagent on
   `git diff <base>..HEAD`, looking for what per-task reviews cannot see (pieces that do not fit
   together, duplicated logic across tasks). `<base>` is the previous gate's commit,
   `git log --grep "^checkpoint G<n-1>" -1 --format=%h`; for the first milestone it is the parent
   of that milestone's first task checkpoint.

   Show the real findings to the owner. Each one the owner accepts becomes a new task in this
   milestone, with a pack and a STATUS row written through the shape skill, so its fix is
   verified, reviewed and checkpointed like any other task. The gate waits for those tasks.
3. Ask the owner to do the hands-on checks in GATE.md. Then record the result. In hybrid, send
   the builder `"Owner: G<n> <passed|failed>: <their notes>. Record it."`. In solo, record it
   yourself: the results log in `GATE.md`, the gate row in `STATUS.md`, and
   `dragonhoard.py log - gate.run "G<n> PASSED|PARTIAL: <why>"`. Then commit the record:

   ```bash
   dragonhoard.py checkpoint G<n>          # commits the gate record; refuses if task work is pending
   ```
4. Harvest lessons here, with `/dragonhoard:learn`, over this milestone's journals and its
   `verify.failed`, `review.failed` and `task.escalated` events. The owner approves each lesson.
   The builder never proposes or applies lessons. Approved lessons reach it through `DIGEST.md`
   from the next task on.

## 6. When to stop

Stop and report to the owner only when:
- a gate is reached (step 5);
- a HANDOFF needs an owner decision (QUESTION, an option pick, BLOCKED the owner must resolve);
- a task failed again after escalation;
- the builder is rate-limited or out of credit;
- your context is past about half (context-lens if installed, otherwise `/context`). Suggest
  `/compact` or a fresh session: `dragonhoard.py hook` and `DIGEST.md` restore everything a new
  orchestrator needs.
