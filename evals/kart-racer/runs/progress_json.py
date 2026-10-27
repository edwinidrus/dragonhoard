#!/usr/bin/env python3
"""Rows for the progress dashboard, read from the game's STATUS.md: one row per task and gate."""
import json, re, sys, datetime, pathlib
game = pathlib.Path.home() / "hobbys/dragonhoard_test/implementation"
status = (game / "STATUS.md").read_text()
names = {d.name.split("-")[0]: d.name.split("-", 1)[1].replace("-", " ") for d in game.iterdir() if re.match(r"M\d+-", d.name)}
names["M10"] = "lantern reach in full"
rows = []
for n, task, title, st in re.findall(r"^\| *(\d+) *\| *(M\d+-T\d+[a-z]?) *\| *([^|]+?) *\| *([A-Z_]+) *\|", status, re.M):
    m = task.split("-")[0]
    rows.append({"kind": "task", "id": task, "milestone": m, "milestone_name": names.get(m, ""), "title": title, "status": st,
                 "phase": "base game" if int(m[1:]) <= 6 else "improvements"})
for g, st in re.findall(r"^\| *(G\d+) *\| *([^|]+?) *\|", status, re.M):
    m = "M" + g[1:]
    rows.append({"kind": "gate", "id": g, "milestone": m, "milestone_name": names.get(m, ""), "title": f"Gate {g}",
                 "status": "PASSED" if st.startswith("PASSED") else "TODO", "phase": "base game" if int(g[1:]) <= 6 else "improvements"})
# Planned work outside STATUS.md: one row, so it shows without inventing task counts.
rows.append({"kind": "planned", "id": "VERDICT", "milestone": "END", "milestone_name": "verdict report", "title": "Trial verdict report and scorecard", "status": "PLANNED", "phase": "verdict"})
json.dump({"generated": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"), "rows": rows}, sys.stdout, indent=1)
