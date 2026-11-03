#!/usr/bin/env bash
# M10-T07 judge answer: host load explains the 309 (A/B under equal load: T07 318/317, T06 318/322).
# Builder records and closes; the script verifies, IP-checks, commits and audits. Sol only.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(grep '^quiet()' "$G/loop.sh")"
out=$(python3 "$cli" delegate --quota-patience 172800 --session ses_e8700c15affeavPhfBm7TtLEcl "External judge finding for M10-T07: no new direction is needed. Host load explains your 309: the judge ran the unchanged npm run smoke on the current tree and on the committed T06 tree alternately under the same load: T07 318 and 317 four-model frames (ratios 0.99 and 1.00), T06 318 and 322, all 35 tests passed each time. T07 costs about 3 frames. Your 309 plus the judge's 318 and 317 are three serial runs: every run at least 300, ratio at least 0.90, median 317, so the rule is met. The visuals are accepted from dist/m10-t07/production/ (chevrons, plank bridge with end posts, clear road, landmark visible in both forward views). Now record these numbers in the T07 journal and the T07 cost row, mark M10-T07 DONE as the skill says (status, progress, task.done event, digest, check) and end with status DONE. No code changes and no new smoke runs. Do not commit. End with the HANDOFF block.")
echo "$out" | sed -n '1,14p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "t07b: stop"; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T07); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"
[ $rc -eq 0 ] || { echo "t07b: verify FAIL (check alone for load flake before acting)"; exit 1; }
pat=$(cd "$G" && python3 -c "import audit; print(audit.IP_TERMS.pattern)")
hits=$(git grep --untracked -nIiE "$pat" -- . ':!node_modules' ':!dist' ':!implementation/logs' ':!implementation/DIGEST.md' ':!*.journal.md')
[ -z "$hits" ] || { echo "t07b: IP hits, not committed"; echo "$hits" | head -5; exit 1; }
git add -A && git commit -q -m "checkpoint M10-T07" && git log --oneline -1
python3 "$G/audit.py" "$game" M10-T07 | grep -E "FAIL|PASS" | cut -c1-160
echo "t07b: M10-T07 committed (judge accepted the visuals before this run)"
