#!/usr/bin/env python3
"""REA-backed independent gate verification for the Hoard Rally trial.

    python3 gate.py /path/to/served/dir gates/G1 [--wait-ms 4500] [--static]
    python3 gate.py --self-check        # calibration: clean page PASS, broken page FAIL

Serves the directory on 127.0.0.1, has REA drive one bounded browser scenario (boot, wait out
the countdown, tap accelerate and drift), and optionally runs REA static analysis. Scores page
errors, real 404s, step completion and whether rendered frames change. Raw REA evidence is kept
in the output directory. REA's `press` is a tap, not a hold; "holding accelerate moves the kart"
is the auditor's own Playwright check at the gate, not this script's.
"""

from __future__ import annotations

import argparse
import glob
import json
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent
REA = ["npx", "-y", "rea-agents@latest"]
REQUEST = re.compile(r'"GET (\S+) HTTP/[\d.]+" (\d{3})')


def chromium() -> str:
    found = sorted(glob.glob(str(Path.home() / ".cache/ms-playwright/chromium-*/chrome-linux64/chrome")))
    if not found:
        sys.exit("no Playwright chromium in ~/.cache/ms-playwright")
    return found[-1]


def scenario(port: int, wait_ms: int) -> dict[str, Any]:
    canvas = {"kind": "css", "selector": "canvas"}
    return {
        "browser": {"mode": "launch", "executable_path": chromium()},
        "start_url": {"url": f"http://127.0.0.1:{port}/"},
        "actions": [
            {"step_id": "boot", "action": "wait_for_timeout", "duration_ms": wait_ms},
            # G7+: a track menu comes first; Enter starts the first track (a no-op on older builds).
            {"step_id": "start", "action": "press", "locator": canvas, "key": "Enter"},
            # G8+: a racer menu follows; Enter takes the first card (on older builds, Enter mid-countdown is ignored).
            {"step_id": "racer_menu", "action": "wait_for_timeout", "duration_ms": 400},
            {"step_id": "racer", "action": "press", "locator": canvas, "key": "Enter"},
            {"step_id": "countdown", "action": "wait_for_timeout", "duration_ms": wait_ms},
            {"step_id": "accelerate", "action": "press", "locator": canvas, "key": "ArrowUp"},
            {"step_id": "drive", "action": "wait_for_timeout", "duration_ms": 1000},
            {"step_id": "drift", "action": "press", "locator": canvas, "key": "Space"},
            {"step_id": "settle", "action": "wait_for_timeout", "duration_ms": 1000},
        ],
        "capture": {"events": ["console", "page-errors"], "after_each_step": ["screenshot"], "at_end": ["url", "dom"]},
    }


def score(evidence: dict[str, Any], server_log: str) -> dict[str, tuple[str, Any]]:
    result = evidence["normalized_result"]
    events = result["events"]["items"]
    steps = result["steps"]
    missing = sorted({path for path, code in REQUEST.findall(server_log) if code == "404" and path != "/favicon.ico"})
    page_errors = [e.get("text") or e.get("message") or e.get("kind") for e in events if e["kind"] == "page-error"]
    console_errors = [e.get("text", "") for e in events if e["kind"] == "console" and e.get("level") == "error"]
    if not missing:  # the browser's own favicon probe is the only allowed failed load
        console_errors = [t for t in console_errors if not t.startswith("Failed to load resource")]
    frames = {s["artifacts"]["screenshot"]["value"]["sha256"] for s in steps
              if s.get("artifacts", {}).get("screenshot", {}).get("state") == "captured"}
    unfinished = [s.get("step_id", i) for i, s in enumerate(steps) if s["status"] != "completed"]
    return {
        "page-errors": ("FAIL" if page_errors else "PASS", page_errors),
        "console-errors": ("FAIL" if console_errors else "PASS", console_errors),
        "missing-files": ("FAIL" if missing else "PASS", missing),
        "steps": ("FAIL" if unfinished else "PASS", unfinished or f"{len(steps)} completed"),
        "frames-change": ("PASS" if len(frames) >= 2 else "FAIL", f"{len(frames)} distinct screenshots"),
    }


def verify(serve_dir: Path, out_dir: Path, wait_ms: int, port: int, static: bool) -> dict[str, tuple[str, Any]]:
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "scenario.json").write_text(json.dumps(scenario(port, wait_ms), indent=2))
    with (out_dir / "server.log").open("w") as log:
        server = subprocess.Popen([sys.executable, "-m", "http.server", str(port), "--bind", "127.0.0.1",
                                   "-d", str(serve_dir)], stdout=log, stderr=subprocess.STDOUT)
        try:
            time.sleep(1)
            run = subprocess.run([*REA, "capture-browser-scenario", str(out_dir / "scenario.json"), "--format", "json"],
                                 capture_output=True, text=True, timeout=300, stdin=subprocess.DEVNULL)
        finally:
            server.terminate()
            server.wait()
    (out_dir / "rea-scenario.json").write_text(run.stdout)
    if run.returncode != 0 or not run.stdout.strip():
        return {"rea-scenario": ("FAIL", f"exit {run.returncode}: {run.stderr.strip()[-300:]}")}
    results = score(json.loads(run.stdout), (out_dir / "server.log").read_text())
    if static:
        static_run = subprocess.run([*REA, "analyze-javascript-application", str(serve_dir), "--format", "json"],
                                    capture_output=True, text=True, timeout=900, stdin=subprocess.DEVNULL)
        (out_dir / "rea-static.json").write_text(static_run.stdout)
        ok = static_run.returncode == 0 and static_run.stdout.strip().startswith("{")
        results["rea-static"] = ("PASS" if ok else "FAIL", "rea-static.json" if ok else static_run.stderr.strip()[-300:])
    return results


def show(results: dict[str, tuple[str, Any]]) -> int:
    for key, (verdict, detail) in results.items():
        print(f"{key:<15} {verdict:<5} {json.dumps(detail, ensure_ascii=False)}")
    return 1 if any(v == "FAIL" for v, _ in results.values()) else 0


def self_check() -> None:
    with tempfile.TemporaryDirectory() as folder:
        clean = verify(HERE / "calibration/clean", Path(folder) / "clean", 1500, 8766, static=False)
        broken = verify(HERE / "calibration/broken", Path(folder) / "broken", 1500, 8767, static=False)
    assert all(v == "PASS" for v, _ in clean.values()), clean
    assert broken["page-errors"][0] == "FAIL" and "undefinedKartPhysics" in str(broken["page-errors"][1]), broken
    print("self-check ok: clean page passes, broken page fails on its page error")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("serve_dir", nargs="?")
    parser.add_argument("out_dir", nargs="?")
    parser.add_argument("--wait-ms", type=int, default=4500, help="boot wait; covers the 3-2-1-GO countdown")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--static", action="store_true", help="also run REA static JavaScript analysis")
    parser.add_argument("--self-check", action="store_true")
    args = parser.parse_args()
    if args.self_check:
        self_check()
        return 0
    if not (args.serve_dir and args.out_dir):
        parser.error("serve_dir and out_dir are required")
    out_dir = Path(args.out_dir)
    if not out_dir.is_absolute():
        out_dir = HERE / out_dir
    return show(verify(Path(args.serve_dir).resolve(), out_dir, args.wait_ms, args.port, args.static))


if __name__ == "__main__":
    sys.exit(main())
