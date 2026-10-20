---
name: init
description: >
  Set up dragonhoard in the current project: ask the delivery mode (full Claude Code, or Claude
  Code orchestrating an OpenCode builder), ask where the implementation workspace lives, confirm
  the standard check commands, and scaffold the root files (constitution, status, protocol,
  logs, templates). Use when the user says "dragonhoard init", "set up dragonhoard", or invokes
  /dragonhoard:init. Run once per project.
---

# dragonhoard init

CLI: `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/dragonhoard.py"` (called `dragonhoard.py` below).

1. **Already set up?** If `dragonhoard.json` at the project root already has a `root`, report it
   and stop. Never overwrite it. A `dragonhoard.json` holding only `host` (and `models`) was
   written by `install`; continue.

2. **Ask the delivery mode, always.** Ask the owner and wait (in Claude Code, use
   AskUserQuestion). Offer exactly two options, with the trade-off from `docs/modes.md`:
   - **Full Claude Code** (`solo`, recommended when quality matters most and budget is fine).
     This session builds; scout, spiker and judge run as Claude subagents.
   - **Claude Code + OpenCode** (`hybrid`, recommended to save Claude tokens). This session
     orchestrates, judges and verifies. A headless OpenCode session builds each task on a
     cheaper or free model. Requires `opencode` on PATH: check `opencode --version` before
     offering it, and say so if it is missing.

   Outside Claude Code there is nothing to orchestrate from, so use `solo` without asking.

3. **Ask the root folder, always.** Do not assume one. Ask the owner and wait for the answer (in
   Claude Code, use AskUserQuestion). Offer:
   - `implementation/` — building a plan from scratch.
   - `improvement/` — improving an existing system.
   - Any other relative folder the owner names.

4. **Detect check commands.** Read only the manifests that exist: `pyproject.toml`,
   `package.json` scripts, `Makefile`, `Cargo.toml`, `go.mod`, CI files under `.github/workflows/`.
   Propose the lint, format-check, type-check and test commands the project already uses. Never
   invent a tool the project does not have. Ask the owner to confirm or edit the proposed set,
   and wait. Zero checks is allowed for a project with no code yet.

5. **Scaffold.**

   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/dragonhoard.py" init --root <root> --mode <solo|hybrid> --check "<cmd 1>" --check "<cmd 2>"
   ```

   It writes `dragonhoard.json`, then `<root>/README.md`, `CONSTITUTION.md`, `STATUS.md`,
   `LESSONS.md` and `DIGEST.md`, then `<root>/logs/` and `<root>/templates/`. It never
   overwrites an existing file.

6. **Project articles.** Ask whether the project has hard constraints worth adding to
   `<root>/CONSTITUTION.md`. Examples: allowed dependencies, data conventions, a storage choice,
   security rules. Append each one the owner confirms as a new numbered article after section
   VII. Do not add generic advice.

7. **Hybrid only: set up the builder.**
   - List the MCP servers OpenCode would load (`opencode mcp list`). Ask the owner which ones the
     builder may use. The default is none that reach personal data such as notes, mail or drives.
   - Install, passing the rest as `--mcp-off`:

     ```bash
     dragonhoard.py install --host opencode --mcp-off <name,name>
     ```

     This writes `.dragonhoard/`, the `dragonhoard-*` skills, the role agents, `AGENTS.md`, and
     `opencode.json`. In `opencode.json` git commits are denied, no rule ever asks (a headless run
     would hang), and only the dragonhoard and discipline skills are allowed.
   - The judge stays external: you are the judge.

8. **Role models.** Run `/dragonhoard:models`. The current model suggests a model for each role,
   and the owner confirms. Solo has scout, spiker and judge. Hybrid has builder, scout and
   spiker; for those, see `opencode models`, where models marked `free` cost nothing.

9. **Hand off.** Show the dragon banner the command printed. Then suggest `/dragonhoard:shape
   <plan file>` as the next step. In hybrid, shaping also runs through `/dragonhoard:conduct`, so
   the builder writes the packs and you review them.
