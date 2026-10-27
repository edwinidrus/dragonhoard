#!/usr/bin/env bash
# Balanced A/B of the unchanged `npm run smoke` under equal load (judge rule since M10-T05):
# H = the committed HEAD in a temporary worktree, W = the working tree with the task's changes.
#   abba.sh <label> [order=HWWHHW]   logs: runs/abba-<label>-<n>.log
# Prints per run: four-model frames / Cinder-only frames, and the pass/fail counts.
set -uo pipefail
label=$1; order=${2:-HWWHHW}
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
game=/home/edwinidrus/hobbys/dragonhoard_test
W=$(mktemp -d /tmp/claude-1000/abba-XXXXXX)
git -C "$game" worktree add -q --detach "$W" HEAD && ln -s "$game/node_modules" "$W/node_modules" || exit 1
echo "abba $label: H = $(git -C "$game" log -1 --format=%h) (worktree), W = working tree; load $(cut -d' ' -f1-3 /proc/loadavg)"
for ((i = 1; i <= ${#order}; i++)); do
  c=${order:i-1:1}; dir=$game; [ "$c" = H ] && dir=$W
  log=$G/runs/abba-$label-$i.log
  (cd "$dir" && timeout 900 npm run smoke > "$log" 2>&1)
  frames=$(grep -oE '"frames":[0-9]+' "$log" | head -2 | cut -d: -f2 | paste -sd/)
  echo "$i $c: $frames | $(grep -oE '[0-9]+ (passed|failed)' "$log" | paste -sd' ') | $(grep -oE '✘ +[0-9]+ [^ ]+' "$log" | awk '{print $3}' | paste -sd' ')"
done
git -C "$game" worktree remove --force "$W"
