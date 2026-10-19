#!/usr/bin/env python3
"""Independent per-task audit for the Hoard Rally reliability trial.

    python3 audit.py /path/to/game-repo M1-T02 [--base <rev>]   # base defaults to HEAD~1
    python3 audit.py --self-check

Checks one task against the scorecard (R1–R5), prints one line per criterion, appends a JSON
line to audit.jsonl next to this file, and exits 1 on any hard FAIL. It lives outside the game
repo so the builder never sees it. stdlib only; parsing is reused from dragonhoard.py.
"""

from __future__ import annotations

import argparse
import contextlib
import io
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1] / "scripts"))
import dragonhoard  # noqa: E402

LOG = HERE / "audit.jsonl"
FAIL_WORDS = re.compile(r"\b(fail(ed|s|ing)?|error|not ok|red|exit [1-9])\b", re.I)


def git(project: Path, *args: str) -> str:
    return subprocess.run(["git", *args], cwd=project, capture_output=True, text=True).stdout


def pack_files(pack: str) -> set[str]:
    """Backticked paths in the pack's `- **Files:**` bullet (it may span several lines)."""
    match = re.search(r"^- \*\*Files:\*\*(.*?)(?=^- \*\*|^#|\Z)", pack, re.M | re.S)
    tokens = dragonhoard.BACKTICKED.findall(match.group(1)) if match else []
    return {t.split("::")[0] for t in tokens if "." in t or "/" in t if not re.search(r"[<>{}*$ ]", t)}


def changed_files(project: Path, base: str) -> set[str]:
    committed = git(project, "diff", "--name-only", base, "HEAD").split()
    pending = [line[3:] for line in git(project, "status", "--porcelain").splitlines()]
    return set(committed) | set(pending)


def audit(project: Path, task: str, base: str) -> dict[str, Any]:
    config = dragonhoard.load_config(project)
    root = project / config["root"]
    results: dict[str, Any] = {}

    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        code = dragonhoard.main(["--project", str(project), "check"])
    results["R2"] = ("PASS" if code == 0 else "FAIL", out.getvalue().strip().splitlines()[-1:])

    rows = {r["task"]: r for r in dragonhoard.status_rows((root / "STATUS.md").read_text())}
    row = rows.get(task)
    if row is None:
        results["status"] = ("FAIL", "task not in STATUS.md")
        return results
    status = row["status"]
    terminal = status in (*dragonhoard.DONE_STATUSES, "BLOCKED")
    results["status"] = ("PASS" if terminal else "FAIL", status)

    pack_path = root / row["pack"] if row["pack"] else None
    pack = pack_path.read_text() if pack_path and pack_path.is_file() else ""
    journal_path = pack_path.with_name(pack_path.name.replace(".md", ".journal.md")) if pack_path else None
    journal = journal_path.read_text() if journal_path and journal_path.is_file() else ""

    kinds = {e["kind"] for e in dragonhoard.read_jsonl(root / "logs" / "events.jsonl") if e["task"] == task}
    evidence = {
        "journal attempt": "## Attempt" in journal,
        "Ran:": "- Ran:" in journal,
        "Outcome:": "- Outcome:" in journal,
        "task.started": "task.started" in kinds,
        "task.done|blocked": bool(kinds & {"task.done", "task.blocked"}),
    }
    missing = [name for name, ok in evidence.items() if not ok]
    results["R3"] = ("FAIL" if missing else "PASS", missing or "complete")

    allowed = pack_files(pack)
    bookkeeping = (f"{config['root']}/", dragonhoard.CONFIG_NAME)
    extra = sorted(f for f in changed_files(project, base) - allowed if not f.startswith(bookkeeping))
    unreported = [f for f in extra if f not in journal]
    results["R4"] = (
        "FAIL" if unreported else "PASS",
        {"allowed": sorted(allowed), "extra": extra, "unreported": unreported},
    )

    if status in dragonhoard.DONE_STATUSES:
        failed = []
        for command in config.get("checks", []):
            run = subprocess.run(command, shell=True, cwd=project, capture_output=True, text=True, timeout=900)
            if run.returncode != 0:
                failed.append(f"{command} -> exit {run.returncode}")
        results["R1"] = ("FAIL" if failed else "PASS", failed or f"{len(config.get('checks', []))} checks re-run green")
    else:
        results["R1"] = ("n/a", f"status {status}")

    ran = [line for line in journal.splitlines() if line.lstrip().startswith("- Ran:")]
    red_first = bool(ran) and bool(FAIL_WORDS.search(" ".join(ran[:-1]) or ran[0]))
    results["R5"] = ("seen" if red_first else "not seen", "report-only heuristic")
    return results


def report(project: Path, task: str, base: str, results: dict[str, Any], log: Path = LOG) -> int:
    for key, (verdict, detail) in results.items():
        print(f"{key:<7} {verdict:<9} {json.dumps(detail, ensure_ascii=False)}")
    record = {
        "ts": dragonhoard.now(), "task": task, "base": base,
        "head": git(project, "rev-parse", "--short", "HEAD").strip(),
        "results": {k: v[0] for k, v in results.items()}, "detail": {k: v[1] for k, v in results.items()},
    }
    dragonhoard.append_jsonl(log, record)
    return 1 if any(v[0] == "FAIL" for v in results.values()) else 0


def self_check() -> None:
    """Fixture repo: task A clean, task B out of scope, task C a false DONE."""
    with tempfile.TemporaryDirectory() as folder:
        project = Path(folder) / "repo"  # the audit log sits beside the repo, never inside it
        project.mkdir()
        sh = lambda *cmd: subprocess.run(cmd, cwd=project, check=True, capture_output=True)  # noqa: E731
        sh("git", "init", "-q")
        sh("git", "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "--allow-empty", "-m", "base")
        with contextlib.redirect_stdout(io.StringIO()):
            dragonhoard.main(["--project", str(project), "init", "--root", "impl", "--check", "test ! -f broken"])
        root = project / "impl"
        tasks = {"M1-T01": ["src/a.js"], "M1-T02": ["src/b.js"], "M1-T03": ["src/c.js"]}
        status_lines = ["| # | Task | Title | Status | Depends on | Pack |", "|---|---|---|---|---|---|"]
        progress = ["| Task | Status | Changes |", "|---|---|---|"]
        for n, (task, files) in enumerate(tasks.items(), 1):
            pack = f"M1-x/tasks/{task}-x.md"
            status_lines.append(f"| {n} | {task} | t | DONE | — | [pack]({pack}) |")
            progress.append(f"| {task} | DONE | `{files[0]}` |")
            (root / pack).parent.mkdir(parents=True, exist_ok=True)
            (root / pack).write_text(f"## 1. Plan\n\n- **Files:** `{files[0]}` + `tests/{task}.test.js`\n- **Do not:** x\n")
            (root / pack.replace(".md", ".journal.md")).write_text(
                "## Attempt 1\n- Ran: `node --test` -> 1 failing\n- Ran: `node --test` -> pass\n- Outcome: PASS\n")
            for kind in ("task.started", "task.done"):
                if (task, kind) != ("M1-T03", "task.started"):  # M1-T03 skips its start event
                    dragonhoard.append_jsonl(root / "logs/events.jsonl", {"ts": "t", "task": task, "kind": kind, "summary": "", "ref": ""})
        (root / "STATUS.md").write_text("\n".join(status_lines) + "\n")
        (root / "M1-x/PROGRESS.md").write_text("\n".join(progress) + "\n")

        def checkpoint(task: str, *paths: str) -> None:
            for path in paths:
                (project / path).parent.mkdir(parents=True, exist_ok=True)
                (project / path).write_text("x")
            sh("git", "add", "-A")
            sh("git", "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "-m", f"checkpoint {task}")

        log = Path(folder) / "audit.jsonl"
        quiet = contextlib.redirect_stdout(io.StringIO())
        checkpoint("setup", *(files[0] for files in tasks.values()))  # DONE rows name existing files
        checkpoint("M1-T01", "src/a.js", "tests/M1-T01.test.js")
        with quiet:
            assert report(project, "M1-T01", "HEAD~1", audit(project, "M1-T01", "HEAD~1"), log) == 0
        checkpoint("M1-T02", "src/b.js", "src/extra.js", "impl/notes.md")  # bookkeeping is in scope
        result = audit(project, "M1-T02", "HEAD~1")
        assert result["R4"][0] == "FAIL" and result["R4"][1]["extra"] == ["src/extra.js"], result["R4"]
        checkpoint("M1-T03", "src/c.js", "broken")
        result = audit(project, "M1-T03", "HEAD~1")
        assert result["R1"][0] == "FAIL", result["R1"]
        assert result["R3"] == ("FAIL", ["task.started"]), result["R3"]
        assert result["R5"][0] == "seen"
        assert len(log.read_text().splitlines()) == 1
    print("self-check ok")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("project", nargs="?")
    parser.add_argument("task", nargs="?")
    parser.add_argument("--base", default="HEAD~1")
    parser.add_argument("--self-check", action="store_true")
    args = parser.parse_args()
    if args.self_check:
        self_check()
        return 0
    if not (args.project and args.task):
        parser.error("project and task are required")
    project = dragonhoard.find_project(Path(args.project).resolve())
    if project is None:
        print("no dragonhoard.json found")
        return 1
    return report(project, args.task, args.base, audit(project, args.task, args.base))


if __name__ == "__main__":
    sys.exit(main())
