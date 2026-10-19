# Status rollup

Execution order runs top to bottom. `dragonhoard.py next` reads this table. Detail, real command
output and blockers live in each milestone's `PROGRESS.md`; update both when a task changes
state (`dragonhoard.py check` catches drift).

| # | Task | Title | Status | Depends on | Pack |
|---:|---|---|---|---|---|

## Gates

A dependency on `G<n>` is satisfied once that gate's status starts with `PASSED`.

| Gate | Status | Detail |
|---|---|---|
