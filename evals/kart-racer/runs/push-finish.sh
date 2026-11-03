#!/usr/bin/env bash
# Run only when the owner says to push (prepared 2026-10-27, not run). Lands the local game branch m10-finish
# (checkpoint M10-T09, checkpoint G10 passed) on the private Dragon_test as one PR merged without review,
# then pushes the dragonhoard v0.3-modes trial write-up to the public repo.
#   bash evals/kart-racer/runs/push-finish.sh
set -euo pipefail
game=/home/edwinidrus/hobbys/dragonhoard_test
plugin=/home/edwinidrus/hobbys/dragonhoard_planing
session=https://claude.ai/code/session_019THy46FswbovBCP9Ud54HK

cd "$game"
[ "$(git branch --show-current)" = m10-finish ] || git switch -q m10-finish
[ -z "$(git status --porcelain)" ] || { echo "push-finish: game tree not clean, nothing pushed"; exit 1; }
git push -q -u origin m10-finish
url=$(gh pr create --base master --head m10-finish --title "M10-T09 and G10: lantern halos, gold glints, Lantern Reach gate" --body "Finishes Hoard Rally: M10-T09 (lantern halos and gold glints) and gate G10 (Lantern Reach in full), built by the dragonhoard hybrid loop (OpenCode builder on GPT-6.1 Sol) and checked by the Claude Code judge.

- M10-T09: npm test 467/467; hidden audit all PASS (R1 limited to npm test); the judge viewed the production screenshots.
- G10: REA, races, falls, collisions, budget and code review (0 bugs) recorded in GATE.md.
- **Owner override:** this host misses the 300-frame smoke floor with T08 and T09 alike (A/B: T09 costs nothing measurable). T09 and G10 are accepted on the owner's override; the 300 floor and 0.90 ratio were not changed.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

$session")
echo "push-finish: $url"
gh pr merge "$url" --merge
git switch -q master && git pull -q --ff-only origin master && git branch -q -d m10-finish && git push -q origin --delete m10-finish
git log --oneline -3

cd "$plugin"
git push -q origin v0.3-modes
git log --oneline -1
echo "push-finish: game PR merged into master; dragonhoard v0.3-modes pushed"
