---
name: init
description: >
  Set up dragonhoard in the current project: ask where the implementation workspace lives, confirm
  the standard check commands, and scaffold the root files (constitution, status, protocol,
  logs, templates). Use when the user says "dragonhoard init", "set up dragonhoard", or invokes
  /dragonhoard:init. Run once per project.
---

# dragonhoard init

CLI: `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/dragonhoard.py"` (called `dragonhoard.py` below).

1. **Already set up?** If `dragonhoard.json` exists at the project root, report its `root` and
   stop. Never overwrite it.

2. **Ask the root folder, always.** Do not assume one. Use AskUserQuestion:
   - `implementation/` — building a plan from scratch.
   - `improvement/` — improving an existing system.
   - The user can type another relative folder via "Other".

3. **Detect check commands.** Read only the manifests that exist: `pyproject.toml`,
   `package.json` scripts, `Makefile`, `Cargo.toml`, `go.mod`, CI files under `.github/workflows/`.
   Propose the lint, format-check, type-check and test commands the project already uses. Never
   invent a tool the project does not have. Confirm with AskUserQuestion (proposed set first;
   the user can edit via "Other"). Zero checks is allowed for a project with no code yet.

4. **Scaffold.**

   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/dragonhoard.py" init --root <root> --check "<cmd 1>" --check "<cmd 2>"
   ```

   It writes `dragonhoard.json`, then `<root>/README.md`, `CONSTITUTION.md`, `STATUS.md`,
   `LESSONS.md` and `DIGEST.md`, then `<root>/logs/` and `<root>/templates/`. It never
   overwrites an existing file.

5. **Project articles.** Ask whether the project has hard constraints worth adding to
   `<root>/CONSTITUTION.md`. Examples: allowed dependencies, data conventions, a storage choice,
   security rules. Append each one the owner confirms as a new numbered article after section
   VII. Do not add generic advice.

6. **Hand off.** Show the dragon banner the command printed. Then suggest `/dragonhoard:shape
   <plan file>` as the next step.
