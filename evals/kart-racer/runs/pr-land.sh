#!/usr/bin/env bash
# Land one judge-accepted, verified task through a GitHub pull request on the game repo (owner, 2026-10-26:
# earn the YOLO and Pair Extraordinaire achievements). Branch, IP check, checkpoint commit with a co-author
# trailer, hidden audit (base HEAD~1 = master tip), push, PR, merge without review, fast-forward master.
#   pr-land.sh M10-T08 "Sleeping dragon landmark"
set -uo pipefail
task=$1; title=$2
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
game=/home/edwinidrus/hobbys/dragonhoard_test
session=https://claude.ai/code/session_019THy46FswbovBCP9Ud54HK
cd "$game"
br=$(echo "$task" | tr 'A-Z' 'a-z')
pat=$(cd "$G" && python3 -c "import audit; print(audit.IP_TERMS.pattern)")
hits=$(git grep --untracked -nIiE "$pat" -- . ':!node_modules' ':!dist' ':!implementation/logs' ':!implementation/DIGEST.md' ':!*.journal.md')
[ -z "$hits" ] || { echo "pr-land: IP hits, nothing committed"; echo "$hits" | head -5; exit 1; }
git switch -q -c "$br" || exit 1
git add -A
git commit -q -m "checkpoint $task" -m "$title.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: $session" || exit 1
git log --oneline -1
audit=$(python3 "$G/audit.py" "$game" "$task"); echo "$audit" | grep -E "FAIL|PASS" | cut -c1-160
if echo "$audit" | grep -q FAIL; then echo "pr-land: audit FAIL; branch $br kept local, not pushed"; exit 1; fi
git push -q -u origin "$br" || exit 1
url=$(gh pr create --base master --head "$br" --title "$task: $title" --body "Hoard Rally $task ($title), built by the dragonhoard hybrid loop (OpenCode builder on GPT-6.1 Sol), verified and audited by the Claude Code judge before this PR.

- verify: PASS (unit tests and the unchanged smoke, frame floor 300 and ratio 0.90 kept)
- hidden audit: all PASS
- the judge viewed the production screenshots before the commit

🤖 Generated with [Claude Code](https://claude.com/claude-code)

$session") || exit 1
echo "pr-land: $url"
gh pr merge "$url" --merge || exit 1
git switch -q master && git pull -q --ff-only origin master && git branch -q -d "$br" && git push -q origin --delete "$br"
git log --oneline -2
echo "pr-land: $task merged without review into master"
