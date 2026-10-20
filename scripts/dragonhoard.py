#!/usr/bin/env python3
"""dragonhoard: the deterministic half of the harness.

The skills do the reasoning; this script owns everything that must not drift:
which task is next, the append-only logs, the memory digest, STATUS/PROGRESS consistency,
and the lesson screen and ledger.

    dragonhoard.py init --root implementation --check "pytest -q" [--mode solo|hybrid]
    dragonhoard.py next
    dragonhoard.py log M1-T01 option.chosen "picked sqlite over json" --ref journal#2
    dragonhoard.py digest
    dragonhoard.py check
    dragonhoard.py lesson screen < lesson.txt
    dragonhoard.py lesson approve --text "..." --provenance "M1-T01#3" --judge "..." --by owner
    dragonhoard.py lesson revoke L01 --reason "..." --by owner
    dragonhoard.py hook                       # SessionStart: banner, next task, digest
    dragonhoard.py models [--set judge=<model> --why "..."]
    dragonhoard.py role judge                 # how to run a role on this host
    dragonhoard.py install --host opencode    # non-Claude hosts: vendor CLI, skills, agents, rules
    dragonhoard.py mode hybrid --why "..."    # solo: one host does everything; hybrid: Claude Code
                                              # orchestrates, OpenCode builds
    dragonhoard.py delegate "<prompt>" [--session <id>]   # hybrid: one OpenCode builder turn
    dragonhoard.py verify M1-T01 [--base HEAD]            # independent re-check of a task

stdlib only. It never edits source or tests and never reads `.env`.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import selectors
import shutil
import subprocess
import sys
import time
import unicodedata
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

PLUGIN_ROOT = Path(__file__).resolve().parents[1]
TEMPLATES = PLUGIN_ROOT / "templates"
CONFIG_NAME = "dragonhoard.json"
VENDOR_DIR = ".dragonhoard"
VENDORED = ("scripts", "templates", "assets", "skills", "agents")
CLI_REF = re.compile(r'"?\$\{CLAUDE_PLUGIN_ROOT\}/scripts/dragonhoard\.py"?')
BLOCK_START, BLOCK_END = "<!-- dragonhoard:start -->", "<!-- dragonhoard:end -->"
MODES = ("solo", "hybrid")  # solo: one host does everything; hybrid: Claude Code orchestrates, OpenCode builds
EXTERNAL = "external"  # a role answered by the orchestrating session, not by a host model
ORCHESTRATOR_SKILLS = ("conduct",)

# What each role needs. Requirements only, never model names: the current model suggests
# concrete models (skills/models). Defaults are Claude Code tier aliases, used only there.
ROLES: dict[str, dict[str, Any]] = {
    "scout": {
        "needs": "fast and cheap, reliable tool use, long context; retrieval, not reasoning",
        "runs": "often, several in parallel",
        "default": "haiku",
        "permission": {"edit": "deny", "bash": "deny", "webfetch": "allow"},
    },
    "spiker": {
        "needs": "solid coding and test running at mid cost",
        "runs": "up to 3 in parallel, one per option",
        "default": "sonnet",
        "permission": {"edit": "allow", "bash": "allow", "webfetch": "allow"},
    },
    "judge": {
        "needs": "strongest available reasoning; cost secondary",
        "runs": "rarely: option comparison and lesson review",
        "default": "opus",
        "permission": {"edit": "deny", "bash": "deny", "webfetch": "deny"},
    },
    "builder": {  # hybrid only: the OpenCode main session itself, never a subagent
        "needs": "solid coding and test running at the lowest cost; follows a skill step by step",
        "runs": "one headless session per task, started by the orchestrator",
        "default": None,
        "permission": {},
    },
}
CLAUDE_ALIASES = ("haiku", "sonnet", "opus", "fable")  # values the Agent tool's `model` accepts

# Host differences live here and only here (sources and dates: docs/hosts.md).
HOSTS: dict[str, dict[str, Any]] = {
    "claude-code": {"skills": None, "agents": None, "rules": None,
                    "list_models": "Agent tool aliases: " + ", ".join(CLAUDE_ALIASES)},
    "opencode": {"skills": ".opencode/skills", "agents": ".opencode/agents", "rules": "AGENTS.md",
                 "list_models": "run `opencode models`"},
    "codex": {"skills": ".agents/skills", "agents": ".codex/agents", "rules": "AGENTS.md",
              "list_models": None},
    "cline": {"skills": ".cline/skills", "agents": None, "rules": ".clinerules/dragonhoard.md",
              "list_models": None},
    "generic": {"skills": ".agents/skills", "agents": None, "rules": "AGENTS.md", "list_models": None},
}

DONE_STATUSES = ("DONE", "DONE_OFFLINE")
TASK_ID = r"M\d+-T\d+[a-z]?"
TASK_ROW = re.compile(rf"^\|\s*\**({TASK_ID})\**\s*\|")
BACKTICKED = re.compile(r"`([^`\s]+)`")
LINK = re.compile(r"\]\(([^)]+)\)")
DIGEST_MAX_LINES = 150
LESSON_MAX_CHARS = 800

SCREEN_RULES: list[tuple[str, re.Pattern[str]]] = [
    ("url", re.compile(r"https?://\S+|www\.\S+", re.I)),
    ("absolute-path", re.compile(r"(?<![\w.])(/[\w.-]+){2,}|~/\S+|\b[A-Za-z]:\\\S+")),
    ("secret", re.compile(r"\b(sk-|ghp_|gho_|xox[bp]-|AKIA)[A-Za-z0-9_-]{8,}")),
    ("secret", re.compile(r"\b(api[_-]?key|token|password|secret)\s*[:=]\s*\S+", re.I)),
    (
        "injection",
        re.compile(
            r"ignore (all |any )?(previous|prior|above|earlier) (instructions|rules)"
            r"|disregard (the |all )?(instructions|rules|constitution)"
            r"|you are now|system prompt|do not (tell|inform) the (user|owner)"
            r"|without (asking|telling) the (user|owner)|exfiltrat\w*"
            r"|(curl|wget)\b[^\n|]*\|\s*(ba|z)?sh",
            re.I,
        ),
    ),
]


# --- project and tables ------------------------------------------------------------------


def now() -> str:
    return datetime.now(UTC).isoformat(timespec="seconds")


def find_project(start: Path) -> Path | None:
    for folder in (start, *start.parents):
        if (folder / CONFIG_NAME).is_file():
            return folder
    return None


def load_config(project: Path) -> dict[str, Any]:
    path = project / CONFIG_NAME
    config: dict[str, Any] = json.loads(path.read_text()) if path.is_file() else {}
    config.setdefault("host", "claude-code")
    config.setdefault("mode", "solo")
    config.setdefault("models", {})
    return config


def save_config(project: Path, config: dict[str, Any]) -> None:
    (project / CONFIG_NAME).write_text(json.dumps(config, indent=2) + "\n")


def role_models(config: dict[str, Any]) -> dict[str, str | None]:
    """Configured model per role; Claude Code falls back to its tier aliases, others to unset.
    Hybrid adds the builder role and answers the judge in the orchestrating session."""
    claude = config["host"] == "claude-code"
    hybrid = config.get("mode") == "hybrid"
    return {
        role: config["models"].get(role) or (EXTERNAL if hybrid and role == "judge" else None)
        or (spec["default"] if claude else None)
        for role, spec in ROLES.items()
        if role != "builder" or hybrid
    }


def skill_ref(host: str, name: str) -> str:
    return f"/dragonhoard:{name}" if host == "claude-code" else f"dragonhoard-{name}"


def agent_name(host: str, role: str) -> str:
    # Codex names agents by a `name` field; its docs use underscores.
    return {"claude-code": f"dragonhoard:{role}", "codex": f"dragonhoard_{role}"}.get(
        host, f"dragonhoard-{role}"
    )


def _cells(line: str) -> list[str]:
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def _bare(cell: str) -> str:
    return cell.strip().strip("*").strip()


def status_rows(markdown: str) -> list[dict[str, str]]:
    """Task rows of STATUS.md in file order: # | Task | Title | Status | Depends on | Pack."""
    rows = []
    for line in markdown.splitlines():
        cells = _cells(line)
        if len(cells) >= 5 and re.fullmatch(TASK_ID, _bare(cells[1])):
            pack = LINK.search(cells[5]) if len(cells) > 5 else None
            rows.append(
                {
                    "task": _bare(cells[1]),
                    "title": _bare(cells[2]),
                    "status": _bare(cells[3]),
                    "depends": _bare(cells[4]),
                    "pack": pack.group(1) if pack else "",
                }
            )
    return rows


def gate_rows(markdown: str) -> dict[str, str]:
    """Gate -> status cell from the Gates table of STATUS.md."""
    gates = {}
    for line in markdown.splitlines():
        cells = _cells(line)
        if len(cells) >= 2 and re.fullmatch(r"G\d+", _bare(cells[0])):
            gates[_bare(cells[0])] = _bare(cells[1])
    return gates


def progress_rows(markdown: str) -> list[dict[str, str]]:
    """Task rows of a phase PROGRESS.md: Task | Status | Changes | ..."""
    rows = []
    for line in markdown.splitlines():
        if TASK_ROW.match(line):
            cells = _cells(line)
            if len(cells) >= 3:
                rows.append(
                    {"task": _bare(cells[0]), "status": _bare(cells[1]), "changes": cells[2]}
                )
    return rows


def _dependencies(cell: str) -> list[str]:
    return [dep for dep in re.split(r"[,\s]+", cell) if re.fullmatch(rf"{TASK_ID}|G\d+", dep)]


def next_task(rows: list[dict[str, str]], gates: dict[str, str]) -> dict[str, str] | None:
    """The task in progress, else the first TODO whose dependencies are all done."""
    for row in rows:
        if row["status"] == "IN_PROGRESS":
            return row
    status = {row["task"]: row["status"] for row in rows}
    for row in rows:
        if row["status"] != "TODO":
            continue
        ready = all(
            gates.get(dep, "").upper().startswith("PASSED")
            if dep.startswith("G")
            else status.get(dep) in DONE_STATUSES
            for dep in _dependencies(row["depends"])
        )
        if ready:
            return row
    return None


def _path_token(token: str) -> str | None:
    if "/" not in token or "://" in token or token.startswith(("/", "~")):
        return None
    if any(char in token for char in "*<>{}$"):
        return None
    path = token.split("::")[0]
    return re.sub(r":\d+(-\d+)?$", "", path).rstrip(".,;")


def missing_files(rows: list[dict[str, str]], project: Path) -> list[str]:
    """Backticked relative paths named by DONE progress rows that do not exist."""
    missing = []
    for row in rows:
        if row["status"] not in DONE_STATUSES:
            continue
        for token in BACKTICKED.findall(row["changes"]):
            path = _path_token(token)
            if path is not None and not (project / path).exists():
                missing.append(f"{row['task']}: {path}")
    return missing


def status_mismatches(status: dict[str, str], progress: dict[str, str]) -> list[str]:
    return [
        f"{task}: STATUS={status.get(task)} PROGRESS={progress.get(task)}"
        for task in sorted(status.keys() | progress.keys())
        if status.get(task) != progress.get(task)
    ]


# --- logs and lessons --------------------------------------------------------------------


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.is_file():
        return []
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]


def append_jsonl(path: Path, record: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a") as handle:
        handle.write(json.dumps(record, ensure_ascii=False) + "\n")


def screen(text: str) -> list[dict[str, str]]:
    """Deterministic lesson screen. Every violation names its rule and the offending text."""
    violations = []
    if len(text) > LESSON_MAX_CHARS:
        violations.append({"rule": "size", "match": f"{len(text)} > {LESSON_MAX_CHARS} chars"})
    if not text.strip():
        violations.append({"rule": "empty", "match": ""})
    for rule, pattern in SCREEN_RULES:
        for match in pattern.finditer(text):
            found = match.group(0)
            # never echo a secret value back into the transcript or the ledger
            violations.append({"rule": rule, "match": found[:4] + "…" if rule == "secret" else found})
    for char in text:
        category = unicodedata.category(char)
        if category in ("Cf", "Co", "Cn") or (category == "Cc" and char not in "\n\t"):
            violations.append({"rule": "invisible-unicode", "match": f"U+{ord(char):04X}"})
    return violations


def redact(text: str) -> str:
    for rule, pattern in SCREEN_RULES:
        if rule == "secret":
            text = pattern.sub("[redacted]", text)
    return text


def lesson_states(ledger: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    """Latest ledger record per lesson ID (the ledger is append-only)."""
    latest: dict[str, dict[str, Any]] = {}
    for record in ledger:
        if record.get("id"):
            latest[record["id"]] = {**latest.get(record["id"], {}), **record}
    return latest


def approved_lessons(ledger: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [rec for rec in lesson_states(ledger).values() if rec["status"] == "approved"]


def next_lesson_id(ledger: list[dict[str, Any]]) -> str:
    numbers = [int(rec["id"][1:]) for rec in ledger if re.fullmatch(r"L\d+", rec.get("id", ""))]
    return f"L{max(numbers, default=0) + 1:02d}"


def render_lessons(ledger: list[dict[str, Any]]) -> str:
    lines = [
        "# Lessons",
        "",
        "Approved lessons only. Generated from `logs/lessons.jsonl` by `dragonhoard.py`; do not",
        "edit by hand. Load these before the Plan step of every task.",
        "",
    ]
    lessons = approved_lessons(ledger)
    if not lessons:
        lines.append("_None approved yet._")
    for rec in lessons:
        lines += [
            f"## {rec['id']}@v{rec['version']}",
            "",
            rec["text"].strip(),
            "",
            f"- Provenance: {rec['provenance']}",
            f"- Approved: {rec['ts']} by {rec['by']}",
            "",
        ]
    return "\n".join(lines).rstrip() + "\n"


# --- digest ------------------------------------------------------------------------------


def render_digest(
    rows: list[dict[str, str]],
    gates: dict[str, str],
    events: list[dict[str, Any]],
    ledger: list[dict[str, Any]],
) -> str:
    task = next_task(rows, gates)
    counts: dict[str, int] = {}
    for row in rows:
        counts[row["status"]] = counts.get(row["status"], 0) + 1
    blocked = [row for row in rows if row["status"] == "BLOCKED"]
    blocked_reason = {e["task"]: e["summary"] for e in events if e["kind"] == "task.blocked"}
    decisions = [e for e in events if e["kind"] == "option.chosen"][-10:]

    lines = [
        "# Digest",
        "",
        "Generated by `dragonhoard.py digest`. Do not edit; sources are STATUS.md,",
        "`logs/events.jsonl` and `logs/lessons.jsonl`.",
        "",
        "## Now",
        "",
        f"- Next task: {_task_line(task) if task else 'none ready'}",
        f"- Tasks: {', '.join(f'{k} {v}' for k, v in sorted(counts.items())) or 'none'}",
        f"- Gates: {', '.join(f'{k} {v}' for k, v in gates.items()) or 'none'}",
        "",
        "## Blocked",
        "",
        *[f"- {r['task']}: {blocked_reason.get(r['task'], 'see PROGRESS.md')}" for r in blocked],
        *([] if blocked else ["- none"]),
        "",
        "## Recent decisions",
        "",
        *[f"- {e['ts'][:10]} {e['task']}: {e['summary']}" for e in decisions],
        *([] if decisions else ["- none"]),
        "",
        "## Approved lessons",
        "",
        *[f"- {rec['id']}: {rec['text'].strip().splitlines()[0]}" for rec in approved_lessons(ledger)],
        *([] if approved_lessons(ledger) else ["- none"]),
        "",
        "## Recent events",
        "",
    ]
    budget = DIGEST_MAX_LINES - len(lines)
    # ponytail: tail-N digest; add search over events.jsonl only if the tail proves too lossy
    tail = events[-max(budget, 0) :] if budget > 0 else []
    lines += [f"- {e['ts'][:16]} {e['task']} {e['kind']}: {e['summary']}" for e in tail]
    if not tail:
        lines.append("- none")
    return "\n".join(lines[:DIGEST_MAX_LINES]) + "\n"


def _task_line(task: dict[str, str]) -> str:
    pack = f" ({task['pack']})" if task["pack"] else ""
    return f"{task['task']} [{task['status']}] {task['title']}{pack}"


# --- commands ----------------------------------------------------------------------------


class Workspace:
    def __init__(self, project: Path) -> None:
        self.project = project
        self.config = load_config(project)
        self.root = project / self.config["root"]
        self.status_md = self.root / "STATUS.md"
        self.events = self.root / "logs" / "events.jsonl"
        self.ledger = self.root / "logs" / "lessons.jsonl"

    def status_text(self) -> str:
        return self.status_md.read_text() if self.status_md.is_file() else ""

    def progress(self) -> list[dict[str, str]]:
        rows = []
        for path in sorted(self.root.glob("M*/PROGRESS.md")):
            rows += progress_rows(path.read_text())
        return rows

    def write_digest(self) -> str:
        text = self.status_text()
        digest = render_digest(
            status_rows(text), gate_rows(text), read_jsonl(self.events), read_jsonl(self.ledger)
        )
        (self.root / "DIGEST.md").write_text(digest)
        return digest

    def write_lessons(self) -> None:
        (self.root / "LESSONS.md").write_text(render_lessons(read_jsonl(self.ledger)))


def _fill(text: str, values: dict[str, str]) -> str:
    for key, value in values.items():
        text = text.replace("{{" + key + "}}", value)
    return text


def cmd_init(args: argparse.Namespace) -> int:
    project = Path(args.project).resolve()
    config = load_config(project)  # `install` may have written host (and models) already
    if config.get("root"):
        print(f"{CONFIG_NAME} in {project} already has root {config['root']!r}; refusing to overwrite.")
        return 1
    root_name = args.root.strip("/")
    if not root_name or Path(root_name).is_absolute() or ".." in Path(root_name).parts:
        print(f"root must be a relative folder inside the project, got {args.root!r}")
        return 1
    checks = args.check or []
    checks_block = "```bash\n" + ("\n".join(checks) or "# no checks configured") + "\n```"
    values = {"root": root_name, "checks": checks_block, "date": now()[:10]}
    root = project / root_name
    # templates/root/* become the root files; templates/skeletons/** are copied for /dragonhoard:shape.
    copies = [(TEMPLATES / "root", root), (TEMPLATES / "skeletons", root / "templates")]
    for source_dir, target_dir in copies:
        for source in sorted(source_dir.rglob("*.md")):
            target = target_dir / source.relative_to(source_dir)
            if target.exists():
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(_fill(source.read_text(), values))
    (root / "logs").mkdir(parents=True, exist_ok=True)
    mode = args.mode or config.get("mode", "solo")
    save_config(project, {**config, "mode": mode, "root": root_name, "checks": checks})
    workspace = Workspace(project)
    append_jsonl(workspace.events, {"ts": now(), "task": "-", "kind": "init", "summary": f"root {root_name}, mode {mode}", "ref": ""})
    workspace.write_lessons()
    workspace.write_digest()
    print((PLUGIN_ROOT / "assets" / "dragon.txt").read_text())
    print(f"dragonhoard initialised: {root.relative_to(project)}/ and {CONFIG_NAME}")
    return 0


def cmd_next(workspace: Workspace, args: argparse.Namespace) -> int:
    text = workspace.status_text()
    task = next_task(status_rows(text), gate_rows(text))
    if task is None:
        print("none ready")
        return 1
    print(json.dumps(task) if args.json else _task_line(task))
    return 0


def cmd_log(workspace: Workspace, args: argparse.Namespace) -> int:
    record = {"ts": now(), "task": args.task, "kind": args.kind, "summary": args.summary, "ref": args.ref}
    append_jsonl(workspace.events, record)
    print(json.dumps(record))
    return 0


def cmd_check(workspace: Workspace, args: argparse.Namespace) -> int:
    rows = workspace.progress()
    status = {row["task"]: row["status"] for row in status_rows(workspace.status_text())}
    problems = status_mismatches(status, {row["task"]: row["status"] for row in rows})
    problems += [f"missing file {item}" for item in missing_files(rows, workspace.project)]
    for problem in problems:
        print(problem)
    print(f"check: {'FAIL' if problems else 'PASS'} | {len(status)} tasks | {len(problems)} problems")
    return 1 if problems else 0


def cmd_lesson(workspace: Workspace, args: argparse.Namespace) -> int:
    ledger = read_jsonl(workspace.ledger)
    if args.action == "screen":
        text = Path(args.file).read_text() if args.file else sys.stdin.read()
        violations = screen(text)
        print(json.dumps({"pass": not violations, "violations": violations}, ensure_ascii=False))
        return 1 if violations else 0
    if args.action in ("approve", "reject"):
        violations = screen(args.text)
        if args.action == "approve" and violations:
            # A judge or an owner can never clear a deterministic screen failure.
            print(json.dumps({"refused": "screen failed", "violations": violations}))
            return 1
        record = {
            "ts": now(),
            "id": next_lesson_id(ledger),
            "version": 1,
            "status": "approved" if args.action == "approve" else "rejected",
            "text": redact(args.text),
            "provenance": args.provenance,
            "judge": args.judge,
            "screen": violations,
            "by": args.by,
            "reason": args.reason,
        }
    else:  # revoke
        if args.id not in lesson_states(ledger):
            print(f"unknown lesson {args.id}")
            return 1
        record = {"ts": now(), "id": args.id, "status": "revoked", "by": args.by, "reason": args.reason}
    append_jsonl(workspace.ledger, record)
    append_jsonl(
        workspace.events,
        {"ts": record["ts"], "task": "-", "kind": f"lesson.{record['status']}", "summary": record["id"], "ref": "logs/lessons.jsonl"},
    )
    workspace.write_lessons()
    workspace.write_digest()
    print(f"{record['id']} {record['status']}")
    return 0


def cmd_hook(project: Path | None) -> int:
    if project is None:
        return 0  # not a dragonhoard project: stay silent
    config = load_config(project)
    host = config["host"]
    if not config.get("root"):
        print(f"dragonhoard installed for {host}; run {skill_ref(host, 'init')} to set it up.")
        return 0
    workspace = Workspace(project)
    print((PLUGIN_ROOT / "assets" / "dragon.txt").read_text().rstrip())
    script = Path(__file__).resolve()
    cli = script.relative_to(project) if script.is_relative_to(project) else script
    models = ", ".join(f"{r}={m or 'unset'}" for r, m in role_models(config).items())
    print(f"\ndragonhoard project ({host}, mode {config['mode']}). Root: {config['root']}/. CLI: python3 {cli}")
    print(f"Role models: {models}. Change with {skill_ref(host, 'models')}.")
    if config["mode"] != "hybrid":
        print(f"Run {skill_ref(host, 'next')} to work the next task (one task per session).\n")
    elif script.is_relative_to(project):  # the vendored CLI: an OpenCode builder session
        print("Mode hybrid: you are the builder. Follow the skill your prompt names, end with the HANDOFF block.\n")
    else:
        print("Mode hybrid: you are the orchestrator. Run /dragonhoard:conduct; it delegates each task to "
              "OpenCode and verifies the result. Never read builder transcripts unless debugging.\n")
    text = workspace.status_text()
    events, ledger = read_jsonl(workspace.events), read_jsonl(workspace.ledger)
    print(render_digest(status_rows(text), gate_rows(text), events, ledger))
    lessons = workspace.root / "LESSONS.md"
    if approved_lessons(ledger) and lessons.is_file():
        print(lessons.read_text())
    return 0


# --- hosts and models --------------------------------------------------------------------


def split_frontmatter(text: str) -> tuple[str, str]:
    match = re.match(r"^---\n(.*?)\n---\n?(.*)$", text, re.S)
    return (match.group(1), match.group(2)) if match else ("", text)


def frontmatter_description(front: str) -> str:
    """The `description:` value, folded (`>`) or inline."""
    match = re.search(r"^description:\s*>?\s*\n((?:[ \t]+.*\n?)+)", front, re.M)
    if match:
        return " ".join(line.strip() for line in match.group(1).splitlines()).strip()
    inline = re.search(r"^description:\s*(.+)$", front, re.M)
    return inline.group(1).strip() if inline else ""


def render_skill(text: str, name: str) -> str:
    """A plugin skill rewritten for a non-Claude host: prefixed name, vendored CLI path."""
    text = CLI_REF.sub(f"{VENDOR_DIR}/scripts/dragonhoard.py", text)
    text = re.sub(r"^name:\s*\S+", f"name: dragonhoard-{name}", text, count=1, flags=re.M)
    return re.sub(r"dragonhoard:([a-z]+)", r"dragonhoard-\1", text)


def render_agent(host: str, role: str, model: str | None, source: str) -> tuple[str, str]:
    """(relative path, file text) of one role agent for a host with per-agent models."""
    front, body = split_frontmatter(source)
    description = frontmatter_description(front)
    body = body.strip() + "\n"
    if host == "opencode":
        permission = "".join(f"  {k}: {v}\n" for k, v in ROLES[role]["permission"].items())
        model_line = f"model: {json.dumps(model)}\n" if model else ""
        text = (
            f"---\ndescription: {json.dumps(description)}\nmode: subagent\n{model_line}"
            f"permission:\n{permission}---\n\n{body}"
        )
        return f"{HOSTS[host]['agents']}/{agent_name(host, role)}.md", text
    if host == "codex":
        assert "'''" not in body, "agent body cannot hold a TOML literal-string delimiter"
        model_line = f"model = {json.dumps(model)}\n" if model else ""
        text = (
            f"name = {json.dumps(agent_name(host, role))}\ndescription = {json.dumps(description)}\n"
            f"{model_line}developer_instructions = '''\n{body}'''\n"
        )
        return f"{HOSTS[host]['agents']}/{agent_name(host, role)}.toml", text
    raise ValueError(f"host {host} has no role agents")


def write_agents(project: Path, config: dict[str, Any]) -> list[str]:
    host = config["host"]
    if not HOSTS[host]["agents"]:
        return []
    written = []
    for role, model in role_models(config).items():
        if role == "builder" or model == EXTERNAL:
            continue
        source = (PLUGIN_ROOT / "agents" / f"{role}.md").read_text()
        relative, text = render_agent(host, role, model, source)
        (project / relative).parent.mkdir(parents=True, exist_ok=True)
        (project / relative).write_text(text)
        written.append(relative)
    return written


def upsert_block(path: Path, block: str) -> None:
    """Write `block` between the dragonhoard markers; everything outside them is preserved."""
    wrapped = f"{BLOCK_START}\n{block.strip()}\n{BLOCK_END}"
    text = path.read_text() if path.is_file() else ""
    pattern = re.compile(re.escape(BLOCK_START) + r".*?" + re.escape(BLOCK_END), re.S)
    if pattern.search(text):
        text = pattern.sub(lambda _: wrapped, text, count=1)
    else:
        text = (text.rstrip() + "\n\n" if text.strip() else "") + wrapped
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.rstrip() + "\n")


def rules_block(host: str, skills: list[str], config: dict[str, Any]) -> str:
    agents = HOSTS[host]["agents"]
    subagents = [r for r, m in role_models(config).items() if r != "builder" and m != EXTERNAL]
    roles = (
        f"Role subagents: {', '.join('`' + agent_name(host, r) + '`' for r in subagents)} in `{agents}/`."
        if agents
        else "No role subagents on this host: scout and spiker run inline; the judge pauses for a model switch."
    )
    hybrid = [
        "- Mode hybrid: you are the builder, run headless by an orchestrating Claude Code session.",
        "  Nobody can answer you mid-turn: never use an interactive question tool. Put owner questions",
        "  and judge requests in the HANDOFF block your prompt asks for, then stop.",
    ] if config.get("mode") == "hybrid" else []
    return "\n".join([
        "## dragonhoard",
        "",
        "This project is delivered with dragonhoard: plan → explore → verify → build → test → record,",
        "one task per session.",
        "",
        f"- At the start of every session, run `python3 {VENDOR_DIR}/scripts/dragonhoard.py hook` and read",
        "  its output before anything else.",
        f"- Skills: {', '.join('`' + s + '`' for s in skills)}.",
        f"- {roles}",
        f"- How to run a role here: `python3 {VENDOR_DIR}/scripts/dragonhoard.py role <scout|spiker|judge>`.",
        *hybrid,
        "- If superpowers is installed, use only its discipline skills (test-driven-development,",
        "  systematic-debugging, verification-before-completion, receiving-code-review). Its planning,",
        "  execution and branch skills duplicate shape/next/explore and commit, which is the owner's job.",
        "- Generated by `dragonhoard.py install`; edit outside these markers only.",
    ])


def cmd_install(args: argparse.Namespace) -> int:
    host = args.host
    project = Path(args.project).resolve()
    if host == "claude-code":
        print("Claude Code uses the plugin directly: `claude --plugin-dir <dragonhoard>` or /plugin install.")
        return 1
    vendor = project / VENDOR_DIR
    if PLUGIN_ROOT != vendor:  # re-running from the vendored copy must not copy onto itself
        for name in VENDORED:
            shutil.copytree(PLUGIN_ROOT / name, vendor / name, dirs_exist_ok=True,
                            ignore=shutil.ignore_patterns("__pycache__"))
    config = load_config(project)
    config["host"] = host
    save_config(project, config)
    written = [f"{VENDOR_DIR}/"]
    skills = []
    for source in sorted((PLUGIN_ROOT / "skills").glob("*/SKILL.md")):
        name = source.parent.name
        if name in ORCHESTRATOR_SKILLS:
            continue  # runs in the orchestrating Claude Code session, never in the builder
        relative = f"{HOSTS[host]['skills']}/dragonhoard-{name}/SKILL.md"
        (project / relative).parent.mkdir(parents=True, exist_ok=True)
        (project / relative).write_text(render_skill(source.read_text(), name))
        skills.append(f"dragonhoard-{name}")
        written.append(relative)
    written += write_agents(project, config)
    upsert_block(project / HOSTS[host]["rules"], rules_block(host, skills, config))
    written.append(HOSTS[host]["rules"])
    if host == "opencode" and config["mode"] == "hybrid":
        write_opencode_config(project, config, args.mcp_off or [])
        written.append("opencode.json")
    print("\n".join(f"wrote {path}" for path in written))
    unset = [r for r, m in role_models(config).items() if not m]
    if unset:
        print(f"models unset for {', '.join(unset)}: run the models skill.")
    if config["mode"] == "hybrid":
        print("next: in Claude Code, run /dragonhoard:conduct; it delegates each task to OpenCode.")
    else:
        print(f"next: open the project in {host} and run dragonhoard-init.")
    return 0


# Headless builders cannot answer an "ask" prompt (the run hangs), so every rule is allow or deny.
DENIED_COMMANDS = ("git commit", "git push", "git reset", "git checkout", "git rebase", "git clean", "rm -rf")
DISCIPLINE_SKILLS = ("test-driven-development", "systematic-debugging", "verification-before-completion",
                     "receiving-code-review")


def write_opencode_config(project: Path, config: dict[str, Any], mcp_off: list[str]) -> None:
    """Merge the hybrid builder's model and permissions into the project opencode.json."""
    path = project / "opencode.json"
    data = json.loads(path.read_text()) if path.is_file() else {"$schema": "https://opencode.ai/config.json"}
    builder = role_models(config).get("builder")
    if builder:
        data["model"] = builder
    data["permission"] = {
        "edit": "allow",
        "question": "deny",
        "external_directory": "deny",
        "bash": {"*": "allow", **{f"{command}*": "deny" for command in DENIED_COMMANDS}},
        "skill": {"*": "deny", "dragonhoard-*": "allow", **{s: "allow" for s in DISCIPLINE_SKILLS}},
        "task": {"*": "deny", "dragonhoard-*": "allow"},
    }
    for name in mcp_off:
        data.setdefault("mcp", {}).setdefault(name, {})["enabled"] = False
    path.write_text(json.dumps(data, indent=2) + "\n")


def cmd_models(project: Path, args: argparse.Namespace) -> int:
    config = load_config(project)
    host = config["host"]
    if args.set:
        changes = {}
        for pair in args.set:
            role, _, model = pair.partition("=")
            if role not in ROLES or not model.strip():
                print(f"expected <{'|'.join(ROLES)}>=<model>, got {pair!r}")
                return 1
            changes[role] = model.strip()
            if host == "claude-code" and changes[role] not in CLAUDE_ALIASES:
                print(f"warning: Claude Code's Agent tool accepts {', '.join(CLAUDE_ALIASES)}; "
                      f"{changes[role]!r} may be rejected")
        config["models"] = {**config["models"], **changes}
        save_config(project, config)
        for path in write_agents(project, config):
            print(f"wrote {path}")
        if host == "opencode" and config["mode"] == "hybrid" and (project / "opencode.json").is_file():
            write_opencode_config(project, config, [])
            print("wrote opencode.json")
        if config.get("root"):
            summary = ", ".join(f"{r}={m}" for r, m in changes.items()) + (f": {args.why}" if args.why else "")
            append_jsonl(project / config["root"] / "logs" / "events.jsonl",
                         {"ts": now(), "task": "-", "kind": "models.changed", "summary": summary, "ref": CONFIG_NAME})
    print(f"host: {host} | mode: {config['mode']}")
    for role, model in role_models(config).items():
        spec = ROLES[role]
        print(f"{role}: {model or 'unset: run the models skill'} | needs: {spec['needs']} | runs: {spec['runs']}")
    print(f"find available models: {HOSTS[host]['list_models'] or 'ask the owner which models this host can use'}")
    return 0


def cmd_role(project: Path, args: argparse.Namespace) -> int:
    config = load_config(project)
    host, role = config["host"], args.role
    model = role_models(config).get(role)
    name = agent_name(host, role)
    worktree = ("one git worktree per option: `git worktree add ../<repo>-spike-<option> -b spike/<option>`; "
                "the spike works only there and is never merged")
    if model == EXTERNAL:
        print("PAUSE. The judge is external: the orchestrating session answers it. Stop now and end "
              "your reply with the HANDOFF block, status JUDGE, and a judge request: the question, the "
              "options, the criteria and the evidence file paths. The verdict arrives as your next prompt.")
        print(f"Journal: record `role {role} ran on {EXTERNAL} via orchestrator`.")
        return 0
    if role == "builder":
        if config["mode"] != "hybrid":
            print("Solo mode has no builder role: this session builds.")
            return 0
        print("The builder is the main OpenCode session itself. The orchestrator starts it with "
              "`dragonhoard.py delegate`; never spawn it as a subagent.")
        return 0
    if host == "claude-code":
        extra = ', isolation: "worktree"' if role == "spiker" else ""
        print(f"Spawn subagent_type `{name}` with model `{model}`{extra}. Put several in one message to run them in parallel.")
    elif HOSTS[host]["agents"]:
        print(f"Invoke the subagent `{name}` (defined in {HOSTS[host]['agents']}/).")
        print(f"Its model: {model or 'unset, so it inherits the session model; run the models skill first'}.")
        if role == "spiker":
            print(f"Before invoking, create {worktree}. Pass that path to the subagent.")
    elif role == "judge":
        print(f"PAUSE. This host cannot run the judge on its own model. Ask the owner to switch this session "
              f"to `{model or 'a frontier model (none configured: run the models skill)'}` "
              f"(judge needs: {ROLES[role]['needs']}). Wait for their confirmation, then judge.")
    elif role == "spiker":
        print(f"Run inline in this session, one option at a time, in {worktree}.")
    else:
        print("Run inline in this session: read-only retrieval with sources; no edits.")
    print(f"Journal: record `role {role} ran on <model> via <how>`.")
    return 0


def cmd_mode(project: Path, args: argparse.Namespace) -> int:
    config = load_config(project)
    if args.mode != config["mode"]:
        config["mode"] = args.mode
        save_config(project, config)
        if config.get("root"):
            append_jsonl(project / config["root"] / "logs" / "events.jsonl",
                         {"ts": now(), "task": "-", "kind": "mode.changed", "summary": f"{args.mode}: {args.why}", "ref": CONFIG_NAME})
    print(f"mode: {config['mode']}")
    if config["mode"] == "hybrid" and config["host"] != "opencode":
        print("next: dragonhoard.py install --host opencode, then the models skill (builder, scout, spiker).")
    return 0


# --- hybrid: delegate a turn to the builder, verify what it did ----------------------------


HANDOFF_STATUSES = ("DONE", "BLOCKED", "QUESTION", "JUDGE", "PARTIAL")
HANDOFF_ASK = """

---
End your reply with this block, filled in, as plain lines (no code fence):
HANDOFF
status: DONE | BLOCKED | QUESTION | JUDGE | PARTIAL
task: <task id, or ->
files: <files you changed, or none>
checks: <commands you ran and their result>
questions: <questions for the owner, or none>
judge: <judge request: question, options, criteria, evidence paths; or none>
risks: <or none>"""
TEST_FILE = re.compile(r"(^|/)(tests?|__tests__|spec)/|[._-](test|spec)\.[a-z]+$")
ASSERTION = re.compile(r"\bassert\w*|\bexpect\s*\(")
SKIP_MARK = re.compile(r"\b(it|test|describe)\.(skip|only|todo)\b|\{\s*(skip|only|todo)\s*:|@pytest\.mark\.skip|\bxit\(")


def git(project: Path, *args: str) -> str:
    return subprocess.run(["git", *args], cwd=project, capture_output=True, text=True).stdout


def changed_files(project: Path, base: str) -> set[str]:
    """Files changed since `base`: committed after it, plus anything pending in the work tree."""
    committed = git(project, "diff", "--name-only", base, "HEAD").split()
    pending = [line[3:].split(" -> ")[-1] for line in git(project, "status", "--porcelain", "-uall").splitlines()]
    return set(committed) | set(pending)


def pack_files(pack: str) -> set[str]:
    """Backticked paths in the pack's `- **Files:**` bullet (it may span several lines)."""
    match = re.search(r"^- \*\*Files:\*\*(.*?)(?=^- \*\*|^#|\Z)", pack, re.M | re.S)
    tokens = BACKTICKED.findall(match.group(1)) if match else []
    return {t.split("::")[0] for t in tokens if "." in t or "/" in t if not re.search(r"[<>{}*$ ]", t)}


def weakened_tests(project: Path, base: str) -> list[str]:
    """Existing test files that lost assertions, were deleted, or gained skip/only/todo marks."""
    problems = []
    for path in sorted(f for f in changed_files(project, base) if TEST_FILE.search(f)):
        before = subprocess.run(["git", "show", f"{base}:{path}"], cwd=project, capture_output=True, text=True)
        if before.returncode != 0:
            continue  # a new test file cannot weaken an old one
        old, file = before.stdout, project / path
        new = file.read_text(errors="replace") if file.is_file() else ""
        if not new:
            problems.append(f"{path}: deleted")
            continue
        if len(ASSERTION.findall(new)) < len(ASSERTION.findall(old)):
            problems.append(f"{path}: assertions {len(ASSERTION.findall(old))} -> {len(ASSERTION.findall(new))}")
        if len(SKIP_MARK.findall(new)) > len(SKIP_MARK.findall(old)):
            problems.append(f"{path}: new skip/only/todo mark")
    return problems


def cmd_verify(workspace: Workspace, args: argparse.Namespace) -> int:
    """The orchestrator's own check of a builder's task; it never trusts the builder's report."""
    config, project = workspace.config, workspace.project
    row = next((r for r in status_rows(workspace.status_text()) if r["task"] == args.task), None)
    if row is None:
        print(f"verify FAIL: {args.task} is not in STATUS.md")
        return 1
    pack_path = workspace.root / row["pack"] if row["pack"] else None
    pack = pack_path.read_text() if pack_path and pack_path.is_file() else ""
    journal_path = pack_path.with_name(pack_path.name.replace(".md", ".journal.md")) if pack_path else None
    journal = journal_path.read_text() if journal_path and journal_path.is_file() else ""
    results = [("status", row["status"] in (*DONE_STATUSES, "BLOCKED"), row["status"])]
    for command in config.get("checks", []):
        run = subprocess.run(command, shell=True, cwd=project, capture_output=True, text=True, timeout=1800)
        tail = (run.stdout + run.stderr).strip().splitlines()[-1:] or [""]
        results.append((f"check `{command}`", run.returncode == 0, f"exit {run.returncode}: {tail[0][:120]}"))
    bookkeeping = (f"{config['root']}/", CONFIG_NAME, f"{VENDOR_DIR}/", ".opencode/", "AGENTS.md", "opencode.json")
    extra = sorted(f for f in changed_files(project, args.base) - pack_files(pack) if not f.startswith(bookkeeping))
    unreported = [f for f in extra if f not in journal]
    results.append(("scope", not unreported, f"outside the pack: {extra or 'none'}; unreported: {unreported or 'none'}"))
    weakened = weakened_tests(project, args.base)
    results.append(("tests not weakened", not weakened, weakened or "ok"))
    results.append(("journal", "- Ran:" in journal and "- Outcome:" in journal, "attempt with Ran and Outcome"))
    for name, ok, detail in results:
        print(f"{'PASS' if ok else 'FAIL'}  {name}: {detail}")
    failed = [name for name, ok, _ in results if not ok]
    print(f"verify: {'FAIL' if failed else 'PASS'} | {args.task} | {len(failed)} failed")
    return 1 if failed else 0


def run_events(command: list[str], cwd: Path, first: float, idle: float) -> tuple[list[dict[str, Any]], bool]:
    """Run a JSON-lines command; kill it when it stays silent too long. Returns (events, stalled)."""
    proc = subprocess.Popen(command, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, stdin=subprocess.DEVNULL)
    assert proc.stdout is not None
    selector = selectors.DefaultSelector()
    selector.register(proc.stdout, selectors.EVENT_READ)
    events: list[dict[str, Any]] = []
    buffer = b""
    while True:
        if not selector.select(timeout=idle if events else first):
            proc.kill()
            proc.wait()
            return events, True
        chunk = os.read(proc.stdout.fileno(), 65536)
        if not chunk:
            break
        *lines, buffer = (buffer + chunk).split(b"\n")
        for line in lines:
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                pass
    proc.wait()
    return events, False


def parse_handoff(text: str) -> tuple[dict[str, str], str] | None:
    """The last HANDOFF block in a reply: (fields, raw block), or None if absent or invalid."""
    lines = text.splitlines()
    starts = [i for i, line in enumerate(lines) if line.strip().strip("*#` ").upper() == "HANDOFF"]
    if not starts:
        return None
    block = [line for line in lines[starts[-1]:] if line.strip() and not line.strip().startswith("```")]
    fields = {}
    for line in block[1:]:
        key, sep, value = line.strip().lstrip("-* ").partition(":")
        if sep:
            fields[key.strip().strip("*").lower()] = value.strip()
    status = fields.get("status", "").strip("*` ").upper()
    if status not in HANDOFF_STATUSES:
        return None
    fields["status"] = status
    return fields, "\n".join(block[:40])


def cmd_delegate(workspace: Workspace, args: argparse.Namespace) -> int:
    """One builder turn in OpenCode. Prints only a stats line and the HANDOFF block: the raw
    transcript goes to <root>/logs/sessions/, never into the orchestrator's context."""
    config = workspace.config
    builder = role_models(config).get("builder")
    if config["mode"] != "hybrid" or not builder:
        print("delegate needs mode hybrid and a builder model: dragonhoard.py mode hybrid, then the models skill")
        return 1
    folder = workspace.root / "logs" / "sessions"
    folder.mkdir(parents=True, exist_ok=True)
    if not (folder / ".gitignore").exists():  # raw transcripts can hold command output: keep them local
        (folder / ".gitignore").write_text("*\n")
    session, prompt, started = args.session, args.prompt, time.time()
    totals = {"steps": 0, "input": 0, "output": 0, "cache": 0, "cost": 0.0}
    handoff, text = None, ""
    for attempt in range(1, args.retries + 2):
        command = [args.opencode, "run", "--format", "json", "-m", builder,
                   *(["-s", session] if session else []), prompt + HANDOFF_ASK]
        events, stalled = run_events(command, workspace.project, args.first, args.idle)
        session = session or next((e.get("sessionID") for e in events if e.get("sessionID")), None)
        stamp = now().replace(":", "").replace("+0000", "Z")
        (folder / f"{stamp}-{(session or 'none')[-8:]}.jsonl").write_text("".join(json.dumps(e) + "\n" for e in events))
        for event in events:
            part = event.get("part") or {}
            if event.get("type") == "step_finish":
                tokens = part.get("tokens") or {}
                totals["steps"] += 1
                totals["input"] += tokens.get("input", 0)
                totals["output"] += tokens.get("output", 0) + tokens.get("reasoning", 0)
                totals["cache"] += (tokens.get("cache") or {}).get("read", 0)
                totals["cost"] += part.get("cost") or 0
        text = "\n".join((e.get("part") or {}).get("text", "") for e in events if e.get("type") == "text")
        handoff = parse_handoff(text)
        if handoff:
            break
        errors = [e for e in events if e.get("type") == "error"]
        if attempt <= args.retries:
            time.sleep(args.backoff * attempt if (stalled or errors or not events) else 0)
            # Resume the same session when it got going; otherwise start the turn again.
            prompt = ("Continue where you stopped." if stalled else "Your reply had no HANDOFF block.") if session else args.prompt
    print(f"delegate session {session} | attempts {attempt} | steps {totals['steps']} | tokens in {totals['input']} "
          f"out {totals['output']} cache-read {totals['cache']} | cost {totals['cost']:.4f} | {time.time() - started:.0f}s")
    if handoff is None:
        print("no valid HANDOFF block. Last reply lines:")
        print("\n".join(text.strip().splitlines()[-15:]) or "(no reply)")
        return 1
    print(handoff[1])
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="dragonhoard")
    parser.add_argument("--project", default=".", help="project folder (searched upward for dragonhoard.json)")
    sub = parser.add_subparsers(dest="command", required=True)
    init = sub.add_parser("init")
    init.add_argument("--root", required=True)
    init.add_argument("--check", action="append")
    init.add_argument("--mode", choices=MODES)
    sub.add_parser("next").add_argument("--json", action="store_true")
    log = sub.add_parser("log")
    log.add_argument("task")
    log.add_argument("kind")
    log.add_argument("summary")
    log.add_argument("--ref", default="")
    sub.add_parser("digest")
    sub.add_parser("check")
    sub.add_parser("hook")
    install = sub.add_parser("install")
    install.add_argument("--host", required=True, choices=sorted(HOSTS))
    install.add_argument("--mcp-off", type=lambda s: [n for n in s.split(",") if n], default=[],
                         help="hybrid: comma-separated MCP servers the builder must not see")
    mode = sub.add_parser("mode")
    mode.add_argument("mode", choices=MODES)
    mode.add_argument("--why", default="")
    delegate = sub.add_parser("delegate")
    delegate.add_argument("prompt")
    delegate.add_argument("--session")
    delegate.add_argument("--retries", type=int, default=3)
    delegate.add_argument("--first", type=float, default=240, help="seconds to wait for the first event")
    delegate.add_argument("--idle", type=float, default=1200, help="seconds of silence before a retry")
    delegate.add_argument("--backoff", type=float, default=30)
    delegate.add_argument("--opencode", default="opencode", help=argparse.SUPPRESS)
    verify = sub.add_parser("verify")
    verify.add_argument("task")
    verify.add_argument("--base", default="HEAD", help="revision the task started from")
    models = sub.add_parser("models")
    models.add_argument("--set", nargs="+", metavar="ROLE=MODEL")
    models.add_argument("--why", default="")
    sub.add_parser("role").add_argument("role", choices=list(ROLES))
    lesson = sub.add_parser("lesson")
    actions = lesson.add_subparsers(dest="action", required=True)
    actions.add_parser("screen").add_argument("--file")
    for name in ("approve", "reject"):
        action = actions.add_parser(name)
        action.add_argument("--text", required=True)
        action.add_argument("--provenance", required=True)
        action.add_argument("--judge", default="")
        action.add_argument("--by", required=True)
        action.add_argument("--reason", default="")
    revoke = actions.add_parser("revoke")
    revoke.add_argument("id")
    revoke.add_argument("--reason", required=True)
    revoke.add_argument("--by", required=True)
    args = parser.parse_args(argv)

    if args.command == "init":
        return cmd_init(args)
    if args.command == "install":
        return cmd_install(args)
    project = find_project(Path(args.project).resolve())
    if args.command == "hook":
        return cmd_hook(project)
    if project is None:
        print(f"no {CONFIG_NAME} found; run the dragonhoard init skill first")
        return 1
    if args.command in ("models", "role", "mode"):
        return {"models": cmd_models, "role": cmd_role, "mode": cmd_mode}[args.command](project, args)
    if not load_config(project).get("root"):
        print(f"{CONFIG_NAME} has no root yet; run the dragonhoard init skill first")
        return 1
    workspace = Workspace(project)
    if args.command == "digest":
        print(workspace.write_digest())
        return 0
    handlers = {"next": cmd_next, "log": cmd_log, "check": cmd_check, "lesson": cmd_lesson,
                "delegate": cmd_delegate, "verify": cmd_verify}
    return handlers[args.command](workspace, args)


if __name__ == "__main__":
    sys.exit(main())
