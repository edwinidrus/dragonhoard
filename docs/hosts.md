# Host support

What each host supports, where the fact came from, and when it was checked. The `HOSTS` table
in `scripts/dragonhoard.py` is the only place this lives in code. Update both together, and
never guess: if a fact cannot be confirmed, the host falls back to the inline/pause tier for
that feature.

| Host | Skills | Role subagents with own model | Session start | Tier |
|---|---|---|---|---|
| Claude Code | plugin `skills/` | yes: plugin `agents/*.md`, model passed per Agent call | SessionStart hook | full |
| OpenCode | `.opencode/skills/` | yes: `.opencode/agents/dragonhoard-<role>.md` | `AGENTS.md` block | full |
| Codex CLI | `.agents/skills/` | yes: `.codex/agents/dragonhoard_<role>.toml` | `AGENTS.md` block | full, live check open |
| Cline | `.cline/skills/` (experimental toggle) | not confirmed: roles inline, judge pauses | `.clinerules/dragonhoard.md` | inline |
| Generic (Cursor, Gemini CLI, Copilot, Windsurf, …) | `.agents/skills/` | none assumed: roles inline, judge pauses | `AGENTS.md` block | inline |

## Evidence (checked 2026-10-19)

**OpenCode** (docs: opencode.ai/docs/agents, opencode.ai/docs/skills; local `opencode 1.18.34`)
- Skills are read from `.opencode/skills/`, `.claude/skills/` and `.agents/skills/` as
  `<name>/SKILL.md`. Frontmatter `name` must equal the directory name, plus a `description`.
- Agents are markdown files in `.opencode/agents/`; the file name is the agent name.
  - Frontmatter: `description` (required), `mode: subagent`, `model: provider/model-id`, and a
    `permission` map with keys such as `edit`, `bash` and `webfetch`, valued `allow|ask|deny`.
  - With no `model`, a subagent uses the model of the agent that invoked it.
- `opencode models [provider]` lists the available models (local `--help`).
- **Live check passed** (2026-10-19, after `install --host opencode`):
  - `opencode run` listed all 6 `dragonhoard-*` skills and all 3 `dragonhoard-*` subagents;
  - with `scout=opencode/deepseek-v4.1-flash-free` set, the main agent delegated to
    `dragonhoard-scout`, which answered in the scout format, correct against `grep -n`.

**Codex CLI** (docs: learn.chatgpt.com/docs/agent-configuration/subagents; local `codex-cli 0.162.1`)
- Custom agents are TOML files in `.codex/agents/`, one agent per file.
  - Required keys: `name`, `description`, `developer_instructions`. Optional: `model` and
    `model_reasoning_effort`.
  - `sandbox_mode` and `approval_policy` follow the parent session.
  - Agents are invoked by naming them in the prompt. The docs' example name uses underscores,
    hence `dragonhoard_<role>`.
- Project skills folder: the official page does not name it. The installed binary contains the
  literals `.agents/skills` and `.codex/agents`, so the project skills folder is `.agents/skills/`.
- **Open:** live discovery check. `codex exec` failed with `refresh token has expired`. Owner
  action: `codex login`, then run the Verification step in the README.

**Cline** (docs: docs.cline.bot/customization/skills, docs.cline.bot/customization/cline-rules)
- Project skills live in `.cline/skills/` (also `.clinerules/skills/` and `.claude/skills/`).
  Skills are experimental: Settings → Features → Enable Skills.
- Workspace rules are `.md` files in `.clinerules/` (or `.cline/rules/`). `AGENTS.md` is also read.
- Subagents and per-mode models are not documented on those pages, so dragonhoard does not rely
  on them.
- Not installed locally, so only file-level tests were run.

**Generic.** `.agents/skills/` is the cross-agent skills location used by several hosts. `AGENTS.md`
is the widest instruction-tier fallback.
