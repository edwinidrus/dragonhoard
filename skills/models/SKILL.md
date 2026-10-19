---
name: models
description: >
  Choose which model runs each dragonhoard role (scout, spiker, judge). The current model looks
  at what the host offers, suggests a model per role with a reason tied to the role's needs and
  the journey's evidence, and the owner confirms. Use during init, when the user says "which
  models should we use", "change the judge model", "re-tune roles", or invokes
  /dragonhoard:models.
---

# dragonhoard models

CLI: `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/dragonhoard.py"` (called `dragonhoard.py` below).

## 1. Read the roles

```bash
dragonhoard.py models
```

It prints the host, then each role's needs, how often it runs and its current model (or
`unset`). Last comes a hint for finding the models this host can use. Requirements stay fixed;
only the model per role is a choice.

## 2. Find the available models

- If the hint names a command, such as `opencode models` or the Claude Code aliases, use it.
- Otherwise, ask the owner which models or providers this host can use, and wait.
- **Never open provider config or auth files to find out.** They hold keys.

## 3. Suggest

Propose one model per role. Give each one a single line of reasoning that ties the model to
that role's needs:
- **scout**: the cheapest fast model that uses tools reliably. Many run per task, and they
  retrieve rather than reason.
- **spiker**: a solid coding model at mid cost. Up to 3 run in parallel.
- **judge**: the strongest reasoning model available. It runs rarely, so cost matters least.
  On hosts where `dragonhoard.py role judge` says PAUSE, this is the model the owner will
  switch the session to.

Also use the journey's evidence, when there is any, from `<root>/DIGEST.md` and the journals:
- spikes ending `INCONCLUSIVE` or out of timebox: the spiker may be too weak;
- scouts reporting `not found` for things that existed: the scout may be too weak;
- judge verdicts that later proved wrong: the judge needs a stronger model;
- a role that never struggles on a costly model: try a cheaper one.

Say plainly that your knowledge of newer models may be out of date, and that the host's own list
wins. If a judge is already configured and can run, ask it to review your suggestion (see
`dragonhoard.py role judge`).

## 4. Owner decides

Show the suggestion as a table (role, model, reason). Ask the owner to confirm or edit it, and
wait (in Claude Code, use AskUserQuestion). Never set a model the owner has not confirmed.

## 5. Record

```bash
dragonhoard.py models --set scout=<model> spiker=<model> judge=<model> --why "<one-line reason>"
```

This saves `dragonhoard.json`, regenerates the host's role-agent files (OpenCode and Codex), and
logs a `models.changed` event. Show the final `dragonhoard.py models` output.
