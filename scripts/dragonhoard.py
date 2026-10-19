#!/usr/bin/env python3
"""dragonhoard: the deterministic half of the harness.

The skills do the reasoning; this script owns everything that must not drift:
which task is next, the append-only logs, the memory digest, STATUS/PROGRESS consistency,
and the lesson screen and ledger.

    dragonhoard.py init --root implementation --check "pytest -q"
    dragonhoard.py next
    dragonhoard.py log M1-T01 option.chosen "picked sqlite over json" --ref journal#2
    dragonhoard.py digest
    dragonhoard.py check
    dragonhoard.py lesson screen < lesson.txt
    dragonhoard.py lesson approve --text "..." --provenance "M1-T01#3" --judge "..." --by owner
    dragonhoard.py lesson revoke L01 --reason "..." --by owner
    dragonhoard.py hook                       # SessionStart: banner, next task, digest

stdlib only. It never edits source or tests and never reads `.env`.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
import unicodedata
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

PLUGIN_ROOT = Path(__file__).resolve().parents[1]
TEMPLATES = PLUGIN_ROOT / "templates"
CONFIG_NAME = "dragonhoard.json"

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
    config: dict[str, Any] = json.loads((project / CONFIG_NAME).read_text())
    return config


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
    if (project / CONFIG_NAME).exists():
        print(f"{CONFIG_NAME} already exists in {project}; refusing to overwrite.")
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
    (project / CONFIG_NAME).write_text(
        json.dumps({"root": root_name, "checks": checks}, indent=2) + "\n"
    )
    workspace = Workspace(project)
    append_jsonl(workspace.events, {"ts": now(), "task": "-", "kind": "init", "summary": f"root {root_name}", "ref": ""})
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
    workspace = Workspace(project)
    banner = (PLUGIN_ROOT / "assets" / "dragon.txt").read_text().rstrip()
    print(banner)
    print(f"\ndragonhoard project. Root: {workspace.config['root']}/. CLI: python3 {Path(__file__).resolve()}")
    print("Run /dragonhoard:next to work the next task (one task per session).\n")
    text = workspace.status_text()
    events, ledger = read_jsonl(workspace.events), read_jsonl(workspace.ledger)
    print(render_digest(status_rows(text), gate_rows(text), events, ledger))
    lessons = workspace.root / "LESSONS.md"
    if approved_lessons(ledger) and lessons.is_file():
        print(lessons.read_text())
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="dragonhoard")
    parser.add_argument("--project", default=".", help="project folder (searched upward for dragonhoard.json)")
    sub = parser.add_subparsers(dest="command", required=True)
    init = sub.add_parser("init")
    init.add_argument("--root", required=True)
    init.add_argument("--check", action="append")
    sub.add_parser("next").add_argument("--json", action="store_true")
    log = sub.add_parser("log")
    log.add_argument("task")
    log.add_argument("kind")
    log.add_argument("summary")
    log.add_argument("--ref", default="")
    sub.add_parser("digest")
    sub.add_parser("check")
    sub.add_parser("hook")
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
    project = find_project(Path(args.project).resolve())
    if args.command == "hook":
        return cmd_hook(project)
    if project is None:
        print(f"no {CONFIG_NAME} found; run /dragonhoard:init first")
        return 1
    workspace = Workspace(project)
    if args.command == "digest":
        print(workspace.write_digest())
        return 0
    handlers = {"next": cmd_next, "log": cmd_log, "check": cmd_check, "lesson": cmd_lesson}
    return handlers[args.command](workspace, args)


if __name__ == "__main__":
    sys.exit(main())
