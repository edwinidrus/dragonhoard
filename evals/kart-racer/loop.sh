#!/usr/bin/env bash
# Routine path of the conduct skill, so the orchestrator wakes only on exceptions.
#   loop.sh [max_tasks=5]
# Per task: delegate "Use the dragonhoard-next skill." -> on DONE: verify -> owner-proxy checkpoint
# commit -> hidden audit. Stops (exit 1) on any other status, a verify/audit FAIL, or when no task is
# ready, and prints only the HANDOFF and the one-line results.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
game=~/hobbys/dragonhoard_test
cli=~/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
cd "$game"
for ((n = 1; n <= ${1:-5}; n++)); do
  next=$(python3 "$cli" next) || { echo "loop: stop, $next"; exit 0; }
  echo "loop: task $n: $next"
  case "$next" in *"(—)"*|*"()"*) echo "loop: stop, task has no pack"; exit 1;; esac
  out=$(python3 "$cli" delegate "Use the dragonhoard-next skill.")
  echo "$out" | head -1
  status=$(echo "$out" | sed -n 's/^status: *//p' | tail -1)
  task=$(echo "$out" | sed -n 's/^task: *//p' | tail -1 | grep -oE 'M[0-9]+-T[0-9]+[a-z]?' | head -1)
  if [ "$status" != DONE ] || [ -z "$task" ]; then echo "loop: stop, status ${status:-none}"; echo "$out" | sed -n '2,40p'; exit 1; fi
  v=$(python3 "$cli" verify "$task"); rc=$?
  echo "$v" | grep -E "^FAIL|^verify:"
  [ $rc -eq 0 ] || { echo "loop: stop, verify failed for $task"; exit 1; }
  git add -A && git commit -q -m "checkpoint $task"
  audit=$(python3 "$here/audit.py" "$game" "$task")
  echo "$audit" | grep -E "FAIL" && { echo "loop: stop, audit FAIL for $task"; exit 1; }
  echo "loop: $task DONE, verify PASS, audit PASS ($(echo "$out" | sed -n 's/^checks: *//p' | cut -c1-160))"
done
echo "loop: reached max tasks"
