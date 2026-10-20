---
name: conduct
description: >
  Hybrid mode: orchestrate dragonhoard from Claude Code while OpenCode builds. Delegates one task
  at a time to the OpenCode builder, answers its judge requests, verifies every result
  independently, escalates repeated failures, and runs the gates. Use when dragonhoard.json has
  "mode": "hybrid" and the user says "conduct", "continue the plan", "next task", or invokes
  /dragonhoard:conduct.
---

# dragonhoard conduct (hybrid mode)

CLI: `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/dragonhoard.py"` (called `dragonhoard.py` below).
Requires `"mode": "hybrid"` in `dragonhoard.json`; in solo mode use `/dragonhoard:next` instead.

You are the orchestrator, and your context is the expensive part. The builder's work is free, so
spend your tokens on judgement and checks, not on reading. Hard rules:
- Read only what `delegate` prints: one stats line and the HANDOFF block. Never open the
  transcripts in `<root>/logs/sessions/` unless you are debugging a failure.
- Never write code that belongs to a task, except when escalating (step 4).
- Decisions that belong to the owner stay with the owner: option picks, lessons, gates, pack
  amendments. Ask with AskUserQuestion. Relay the builder's evidence in a few lines, not its
  whole reply.

## 1. Delegate one task

```bash
dragonhoard.py next                       # which task, or why none is ready
dragonhoard.py delegate "Use the dragonhoard-next skill."
```

When `next` reports a task with no pack, first delegate `"Use the dragonhoard-shape skill for M<n>."` and treat
the result like any other HANDOFF. Delegate exactly one task per builder session. Note the
`session` id that `delegate` prints.

## 2. Act on the HANDOFF status

- **JUDGE**: you are the judge.
  - Read the evidence paths it names, and only those.
  - Apply the judge's instructions in `${CLAUDE_PLUGIN_ROOT}/agents/judge.md` (job 1 compares
    options, job 2 reviews lessons).
  - Reply in the same session with `dragonhoard.py delegate "<verdict>" --session <id>`.
- **QUESTION**: ask the owner, then reply with `delegate "<answer>" --session <id>`.
- **BLOCKED**: read the reason. If the owner can resolve it (a stale pack, a red baseline,
  a missing interface), ask them, then delegate the fix or the resume. Never unblock it by
  editing code yourself.
- **PARTIAL** at a gate: go to step 5.
- **DONE**: go to step 3.
- **RATE-LIMITED** (exit code 3): the provider's limit outlasted `--quota-patience` (6 h by
  default). While it waits, `delegate` probes every 15 min and steps a `#variant` effort down,
  never below `effort_floor` in `dragonhoard.json` (default `high`). It logs each wait as
  `delegate.rate_limited`. Tell the owner, and offer a different builder model through
  `/dragonhoard:models`; never switch on your own. Resume with `--session <id>`.
- **No HANDOFF** after its retries: run `delegate "Report where you are. End with the HANDOFF block." --session <id>`
  once. If that also fails, count it as a failed attempt (step 4).

## 3. Verify, never trust

```bash
dragonhoard.py verify <task>              # base defaults to HEAD: the uncommitted task work
```

It re-runs every check, compares the changed files with the pack's Files, and flags weakened
tests and a missing journal. Act on the result:
- **PASS**: tell the owner the task is done in one or two lines, then ask them to commit a
  checkpoint (`git add -A && git commit -m "checkpoint <task>"`). Commits are theirs. Then go
  back to step 1 for the next task.
- **FAIL**: run `delegate "verify failed: <the FAIL lines>. Fix only that, then end with the HANDOFF block." --session <id>`.
  This is attempt 2.

## 4. Escalate after two failed attempts

When the second attempt still fails verify, stop delegating this task:
1. Log it: `dragonhoard.py log <task> task.escalated "<why, in one line>"`.
2. Work the task yourself in this session by following `/dragonhoard:next`. This is solo mode for
   one task. Judge subagents and the owner's decisions stay as usual.
3. Return to delegating with the next task.

An escalation rate above about one task in four means the builder model is too weak for this
plan. Offer `/dragonhoard:models` to pick a stronger builder.

## 5. Gates

When a milestone's last task is done, or the builder reports PARTIAL for a gate:
1. Run the commands in the milestone's `GATE.md` yourself, and record their results.
2. Review the milestone's code before the owner plays it. Look at `git diff <previous gate checkpoint>..HEAD`
   for that milestone only. Use a reviewer subagent if one is available, so the diff stays out of
   your context, and keep findings to one line each. Send real findings back to the builder as
   one task each, through `delegate`.
3. Ask the owner to do the hands-on checks in GATE.md. Then delegate
   `"Owner: G<n> <passed|failed>: <their notes>. Record it."`.

## 6. Keep the context small

At every gate, check how full your context is (context-lens if installed, otherwise
`/context`). If it is past about half, suggest the owner run `/compact` or start a fresh session.
`dragonhoard.py hook` and `DIGEST.md` restore everything a new orchestrator needs.
