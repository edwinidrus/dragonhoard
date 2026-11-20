---
name: next
description: >
  Work exactly one dragonhoard task through the loop plan → explore → verify → build → test →
  record, then stop. Use when the user says "next task", "continue the plan", "work the next
  pack", or invokes /dragonhoard:next. Never takes two tasks in one session.
---

# dragonhoard next

CLI: `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/dragonhoard.py"` (called `dragonhoard.py` below).
`<root>` is the `root` in `dragonhoard.json`; the standard checks are its `checks`.

This skill works one task and stops. To run task after task until a gate, the Claude Code session
uses `/dragonhoard:conduct`: it gives each task to a builder, which follows this skill, and runs
this skill itself only when it escalates a task. In hybrid mode conduct is the normal path.

## 0. Pick

```bash
dragonhoard.py next
```

- `none ready`: report the blockers from `<root>/DIGEST.md` and stop.
- The task has no pack: run `/dragonhoard:shape M<n>` first.
- Run `dragonhoard.py lint <task>`. On FAIL the pack is stale: record BLOCKED (section 7) with
  the `stale` lines as the reason, and stop. Do not load the pack's context first.
- Otherwise set the task's row to `IN_PROGRESS` in both `STATUS.md` and the milestone's
  `PROGRESS.md`. Then run `dragonhoard.py log <task> task.started "<title>"`.

Load exactly the context in `<root>/README.md` step 2: the global constitution, `DIGEST.md`,
`LESSONS.md`, the milestone constitution, the pack, and the files the pack names. Nothing else.
Apply every approved lesson that fits this task.

## 1. Plan

Restate the goal, scope, files and acceptance in five lines or fewer.

If the pack is wrong or stale (it names an interface that does not exist, or contradicts an
`option.chosen` event or a lesson): record BLOCKED (section 7) and stop. Never quietly rewrite a
pack's scope. A pack changes only when the owner approves it, and the change is recorded with
`dragonhoard.py log <task> pack.amended "<what changed>: <the owner's reason>"`.

If the owner asks for something that breaks a constitution article or a plan rule, do not do
it: stop, name the rule and ask (a headless builder ends with HANDOFF status QUESTION). After an
explicit confirmation, run `dragonhoard.py log <task> owner.override "<rule>: <what was allowed>"`.

## 2. Explore (only if needed)

Skip this step when the pack's Open options says "none" and you have no unknowns.

Otherwise:
- **A fact is missing:** run scouts, one question each, as `dragonhoard.py role scout` says.
  Scouts are cheap and read-only.
- **Two or more viable options remain:** run `/dragonhoard:explore`. It spikes options in
  parallel, gets the judge's comparison and asks the owner to pick.

Never re-open a choice that already has an `option.chosen` event unless there is new evidence.

## 3. Verify (before building)

- `grep -n` every interface the pack's Consumes names. Paste the hits into the journal. If one
  is missing or different, record BLOCKED.
- Run every standard check and record the counts. If a check is red before your change, record
  BLOCKED; do not fix unrelated breakage.
- Write the focused test first. Run it and confirm it fails **for the expected reason**.

## 4. Build

Make the smallest change that satisfies acceptance, inside the pack's file list only. If you
need a file outside the list, stop and report it; that is a pack change.

## 5. Test

Run the focused test, then every standard check. Tick each acceptance item with evidence.

If a run fails, write a journal attempt (Outcome FAIL, with the root cause and evidence) and try
again. **Two failed bounded attempts at the same issue means BLOCKED.**

Before a second attempt, find the root cause. Reproduce the failure, read the whole error, compare
with the last green state (`git diff`), then state one hypothesis and make one change that tests
it. An attempt with Outcome FAIL and no `Root cause` line fails `dragonhoard.py verify`.

## 6. Record

1. Append the attempt block to `tasks/<task>.journal.md`. Use the format in `<root>/README.md`,
   with the real commands and the shortest decisive output line.
2. Update the milestone `PROGRESS.md` row: status, the changed files in backticks, the
   verification command and its real result, and the next task.
3. Update the `STATUS.md` row with the same status.
4. Log and refresh:

   ```bash
   dragonhoard.py log <task> task.done "<one line: what now works>" --ref tasks/<task>.journal.md
   dragonhoard.py digest
   dragonhoard.py check   # must PASS
   ```

5. Verify and review. Run `dragonhoard.py role reviewer` and follow what it prints; when it says
   SKIP, skip that part.

   ```bash
   dragonhoard.py verify <task>   # re-runs the checks; checks scope, weakened tests and the journal
   ```

   - `verify` FAIL: fix only what the FAIL lines name. That is a new attempt (section 5).
     `verify` compares with the last commit, so uncommitted work from an earlier task shows up
     under scope: report it, do not touch it.
   - Then run the reviewer, in a fresh context, with the pack path as its whole prompt.
   - Verdict `fix`: run `dragonhoard.py log <task> review.failed "<the critical and important lines>"`,
     fix exactly those as a new attempt, then verify and review again.
   - Verdict `approve`: run `dragonhoard.py log <task> review.passed "<n> minor: <one line each, or none>"`.

6. If this was the milestone's last task, run the `GATE.md` commands. (A builder working for an
   orchestrator skips this item: the orchestrator runs the gate.) Append the real output to
   its results log, set the gate row in `STATUS.md`, and run
   `dragonhoard.py log - gate.run "G<n> PASSED|PARTIAL: <why>"`.

## 7. BLOCKED

- Set `BLOCKED` in both tables, and put the reason and the owner action in the Blocker column.
- Write a journal attempt with Outcome BLOCKED.
- Log `dragonhoard.py log <task> task.blocked "<reason; owner action>"`, then run `digest` and
  `check`.

## 8. Stop

Report what was done, the evidence, and the next task (`dragonhoard.py next`). Commits are an
owner action. Offer `dragonhoard.py checkpoint <task>`: it commits the task's work, and refuses
unless verify and then review passed. Run it only when the owner says so.

If the journal shows a FAIL→PASS story, a surprising root cause or an owner correction, offer
`/dragonhoard:learn`. A builder working for an orchestrator does not offer anything: it names the
story under `risks` in its HANDOFF, and the orchestrator checkpoints and harvests lessons.
