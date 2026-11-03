---
name: quick
description: >
  Small fix or change without milestones or packs: one quick task (Q<nn>) through the same
  evidence loop, with approved lessons loaded, a failing test first, every check and a journal,
  then stop. Use when the user says "quick fix", "small change", "just fix X", or invokes
  /dragonhoard:quick "<what>". Hands off to /dragonhoard:shape when the change turns out bigger.
---

# dragonhoard quick

CLI: `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/dragonhoard.py"` (called `dragonhoard.py` below).
`<root>` is the `root` in `dragonhoard.json`; the standard checks are its `checks`.

Quick tasks live outside the milestones: they are not in `STATUS.md` or `PROGRESS.md`, and `next`
never picks them. They still leave evidence and feed lessons. In hybrid mode, quick runs in this
session and does not delegate.

## 0. Fit

Quick is for a change that touches about three files or fewer, needs no design choice between
options and adds no dependency. If the request is bigger, say so, suggest `/dragonhoard:shape`
(or `/dragonhoard:explore` for an open choice), and stop.

No `dragonhoard.json`: run `/dragonhoard:init` first.

## 1. Start

```bash
dragonhoard.py quick "<one-line title>"   # prints the ID (Q<nn>) and its journal path
```

Read `<root>/LESSONS.md` and apply every approved lesson that fits. Read only the files the change
touches.

## 2. Plan

Restate the goal, the files and the acceptance in three lines or fewer.

## 3. Verify (before building)

- Run every standard check and record the counts. If one is red before your change, record
  BLOCKED (section 6); do not fix unrelated breakage.
- Write the focused test first, run it, and confirm it fails **for the expected reason**. If the
  change cannot be tested (docs, configuration), write that in the journal and name the check
  that proves it instead.

## 4. Build

Make the smallest change that meets the acceptance, in the files you named. If it needs more
files or a design decision appears, stop: record BLOCKED with "grew beyond quick: <why>; owner:
/dragonhoard:shape".

## 5. Test and record

Run the focused test, then every standard check. Append an attempt block to the journal in the
format in `<root>/README.md`, with the real commands and the shortest decisive output line. A
failed run is an attempt with Outcome FAIL and its root cause. **Two failed bounded attempts at
the same issue means BLOCKED.**

When it passes:

```bash
dragonhoard.py log Q<nn> task.done "<one line: what now works>" --ref quick/<journal file>
dragonhoard.py digest
```

## 6. BLOCKED

Write a journal attempt with Outcome BLOCKED, then run
`dragonhoard.py log Q<nn> task.blocked "<reason; owner action>"` and `dragonhoard.py digest`.

## 7. Stop

Report what was done and the evidence. Commits are an owner action; do not commit unless asked.
If the journal shows a FAIL→PASS story or a surprising root cause, offer `/dragonhoard:learn`
(provenance `Q<nn>#<attempt>`).
