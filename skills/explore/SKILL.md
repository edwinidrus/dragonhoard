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

Run `dragonhoard.py role scout` and follow what it prints, one scout per factual question. Where
the host has scout subagents, launch them together so they run in parallel. Typical questions:
does the library support X in our version; how the codebase already does Y; what an API returns.
Drop options the facts rule out.

If only one option survives, skip to step 5 and present it, with the facts that eliminated the
others.

## 3. Spike (parallel, isolated, bounded)

Run `dragonhoard.py role spiker` and follow what it prints: one spiker per surviving option, at most
3, each in its own isolated worktree. They run in parallel where the host has spiker subagents,
and one at a time inline otherwise. Give each spiker:
- the option;
- its success criterion command;
- the files it may touch;
- a timebox of about 15 tool calls;
- the relevant pack excerpt.

Spikes are evidence, not delivery. Their code is never merged.

## 4. Judge

Run `dragonhoard.py role judge` and follow what it prints. If it says PAUSE, stop and ask the
owner to switch models before judging. Give the judge the question, the criteria and every
spiker report. It verifies the reports, then returns a comparison table, a recommendation and
warnings.

## 5. Owner picks

Ask the owner and wait for the answer (in Claude Code, use AskUserQuestion with the evidence in
each option's `preview`). Put the judge's recommendation first, labelled "(Recommended)". For
each option, give its verdict, its criterion result and its cost. The owner may also answer
"none — rethink".

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
