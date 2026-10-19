---
name: explore
description: >
  Resolve an open implementation choice with evidence: cheap parallel retrieval (haiku scouts),
  up to 3 parallel throwaway spikes in isolated worktrees (sonnet spikers), a frontier-model
  comparison (opus judge), then the owner picks and the decision is logged. Use inside
  /dragonhoard:next when a pack lists Open options, or when the user says "explore options",
  "spike these", "which approach works", or invokes /dragonhoard:explore.
---

# dragonhoard explore

CLI: `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/dragonhoard.py"` (called `dragonhoard.py` below).
Input: $ARGUMENTS. That is the open choice, or empty (then take it from the current pack's Open
options).

## 1. Frame the choice

Write down three things:
- the question;
- 2 or 3 candidate options;
- **one success criterion per option, as a command whose output decides pass or fail.**

You may also add a cost ceiling, such as "no new runtime dependency". Check
`<root>/DIGEST.md` first: if an `option.chosen` event already answers this question, stop and
cite it.

## 2. Retrieve (cheap, parallel)

Spawn one `dragonhoard:scout` per factual question, all in **one message** so they run in parallel.
Typical questions: does the library support X in our version; how the codebase already does Y;
what an API returns. Drop options the facts rule out.

If only one option survives, skip to step 5 and present it, with the facts that eliminated the
others.

## 3. Spike (parallel, isolated, bounded)

Spawn one `dragonhoard:spiker` per surviving option, at most 3, in **one message**, each with
`isolation: "worktree"`. Give each spiker:
- the option;
- its success criterion command;
- the files it may touch;
- a timebox of about 15 tool calls;
- the relevant pack excerpt.

Spikes are evidence, not delivery. Their code is never merged.

## 4. Judge

Spawn `dragonhoard:judge` with the question, the criteria and every spiker report. It verifies the
reports, then returns a comparison table, a recommendation and warnings.

## 5. Owner picks

Use AskUserQuestion. Put the judge's recommendation first, labelled "(Recommended)". Each
option's description gives its verdict, its criterion result and its cost. Use the `preview`
field to show each report's evidence lines. The owner may also choose "none — rethink" via
"Other".

## 6. Record

```bash
dragonhoard.py log <task> option.chosen "<question>: <choice> — <decisive evidence>" --ref tasks/<task>.journal.md
```

Add an `Explored:` line to the task's journal attempt, listing each option, its verdict and its
criterion output.

List the spike worktrees that still exist (`git worktree list`). Ask the owner before removing
them; do not delete them yourself.

Return to the Verify step of `/dragonhoard:next`. Build the chosen option properly there, test
first, inside the pack's file list. Do not copy the spike.
