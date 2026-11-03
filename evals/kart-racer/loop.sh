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
# Builder: GPT-6.1 Sol on ChatGPT Plus only (owner, 2026-10-26). The DeepSeek fallback on OpenRouter is
# dropped for cost; a Plus limit is waited out (delegate retries every 15 min, up to 48 h for a weekly cap).
deleg() { out=$(python3 "$cli" delegate --quota-patience 172800 "$@"); } # sets $out; same arguments as `dragonhoard.py delegate`
# The builder's own smoke can outlive its HANDOFF inside `opencode serve` and hold the dev port; verify
# waits for it (up to 3 min) instead of failing on "port is already used" or a loaded machine (M9-T04, T07).
quiet() { for _ in $(seq 36); do ss -ltn | grep -q ':5173 ' || return 0; sleep 5; done; echo "loop: port 5173 still busy, verifying anyway"; }
for ((n = 1; n <= ${1:-5}; n++)); do
  next=$(python3 "$cli" next) || { echo "loop: stop, $next"; exit 0; }
  echo "loop: task $n: $next"
  case "$next" in *"(—)"*|*"()"*) echo "loop: stop, task has no pack"; exit 1;; esac
  deleg "Use the dragonhoard-next skill."
  echo "$out" | head -1
  status=$(echo "$out" | sed -n 's/^status: *//p' | tail -1)
  task=$(echo "$out" | sed -n 's/^task: *//p' | tail -1 | grep -oE 'M[0-9]+-T[0-9]+[a-z]?' | head -1)
  if [ "$status" != DONE ] || [ -z "$task" ]; then echo "loop: stop, status ${status:-none}"; echo "$out" | sed -n '2,40p'; exit 1; fi
  quiet; v=$(python3 "$cli" verify "$task"); rc=$?
  echo "$v" | grep -E "^FAIL|^verify:"
  if [ $rc -ne 0 ]; then # conduct step 3: attempt 2 in the same session with only the FAIL lines
    session=$(echo "$out" | head -1 | grep -oE 'ses_[A-Za-z0-9]+')
    [ -n "$session" ] || { echo "loop: stop, verify failed for $task (no session)"; exit 1; }
    echo "loop: $task verify FAIL, attempt 2 in $session"
    deleg "verify FAIL for $task. Fix only these, then end with the HANDOFF block:
$(echo "$v" | grep -E '^FAIL')" --session "$session"
    echo "$out" | head -1
    quiet; v=$(python3 "$cli" verify "$task"); rc=$?
    echo "$v" | grep -E "^FAIL|^verify:"
    [ $rc -eq 0 ] || { echo "loop: stop, verify failed twice for $task"; exit 1; }
  fi
  git add -A && git commit -q -m "checkpoint $task"
  audit=$(python3 "$here/audit.py" "$game" "$task")
  fails=$(echo "$audit" | grep -E "FAIL")
  if [ -n "$fails" ]; then
    # Fault F6's echo: the generated DIGEST quotes the owner's protected name from the log until it rolls
    # off. The audit still records IP FAIL; the driver goes on only when DIGEST is the sole source.
    other=$(echo "$fails" | grep -v "^IP")
    ip_src=$(cd "$game" && git grep -nIiE "$(python3 -c "import sys; sys.path.insert(0, '$here'); import audit; print(audit.IP_TERMS.pattern)")" -- . ':!node_modules' ':!implementation/logs' ':!*.journal.md' ':!implementation/DIGEST.md')
    if [ -n "$other" ] || [ -n "$ip_src" ]; then echo "$fails"; echo "$ip_src" | head -5; echo "loop: stop, audit FAIL for $task"; exit 1; fi
    echo "loop: $task audit IP FAIL recorded, hits only in the generated DIGEST (F6 echo); continuing"
  fi
  echo "loop: $task DONE, verify PASS, audit PASS ($(echo "$out" | sed -n 's/^checks: *//p' | cut -c1-160))"
done
echo "loop: reached max tasks"
