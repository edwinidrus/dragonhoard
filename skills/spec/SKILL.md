---
name: spec
description: >
  Work out WHAT to build with the owner before any plan is shaped: ask one question at a time,
  play back what was heard, then write the plan file that /dragonhoard:shape cuts into
  milestones. Use when the owner has an idea but no written plan, says "help me plan this",
  "I want to build X", "write the spec", or invokes /dragonhoard:spec [idea].
---

# dragonhoard spec

CLI: `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/dragonhoard.py"` (called `dragonhoard.py` below).
Input: $ARGUMENTS. That is the idea in the owner's words, or empty (then ask for it).

Requires `dragonhoard.json`. If it is missing, run `/dragonhoard:init` first.

A wrong plan shaped well gives many verified tasks that build the wrong thing. This skill finds
out what the owner wants, and why, and writes it down. It writes no code and shapes nothing.

## 0. Fit

- The owner already has a written plan: skip this skill; run `/dragonhoard:shape <plan file>`.
- The request is one small change (about three files, no design choice): use
  `/dragonhoard:quick`.
- Otherwise continue.

## 1. Ask

Ask in chat, **one question per message**, in the owner's own vocabulary. Start open ("What
should someone be able to do when this exists?"), and offer choices only when the owner is stuck.
Offer to look at the existing code or at prior art when that would answer a question faster than
the owner can; use one scout for it (`dragonhoard.py role scout` says how).

Cover this ground. It is a checklist for you, not a script to read out:
- what it is, who uses it, and why now;
- what "done" looks like, as something a person can observe;
- **non-goals** (not in this plan) and **anti-goals** (would make it a failure even if it works);
- constraints: platform, language, existing code to build on, budget, deadlines, licences;
- which how-it-is-made choices the owner wants to make, and which they hand to you. A choice
  nobody has settled becomes an open option in the plan, never a silent default;
- the riskiest unknown: the part most likely to turn out impossible or different.

## 2. Play back

Whenever you understand one part, describe it back in a short paragraph and ask what is wrong or
missing. Mark every guess as a guess. Only what the owner said counts as decided.

Stop asking when you could explain the whole thing to a builder who has never met the owner.

## 3. Write the plan

Ask the owner where the plan file goes (suggest `docs/plan.md`). Write it in plain words:

```markdown
# <name>: plan

## Why
## What it does            <!-- observable behaviour, one bullet each -->
## Done means              <!-- checks a person or a command can run -->
## Non-goals
## Anti-goals
## Constraints
## Decided                 <!-- choices the owner made, in their words -->
## Open options            <!-- unsettled choices: question, candidates, what would decide it -->
## Riskiest unknown
## Later                   <!-- wanted, but not in this plan -->
```

Leave a section empty rather than invent content for it. Never write a secret, a credential or
personal data into the plan.

## 4. Owner approves

Ask the owner to read the file and approve or correct it, and wait for the answer (in Claude
Code, use AskUserQuestion). Apply corrections and ask again until approved. Then:

```bash
dragonhoard.py log - spec.approved "<plan file>: <one line, what it builds>"
```

## 5. Hand off

Suggest `/dragonhoard:shape <plan file>`. It has the judge read the plan as a builder first, then
proposes the milestone cut.
