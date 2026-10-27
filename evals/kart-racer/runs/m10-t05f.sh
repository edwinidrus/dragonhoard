#!/usr/bin/env bash
# M10-T05 judge answer: the 211-245 smoke samples came from an overloaded machine; under equal load the tree
# measures 326/335 (committed T04: 333/342). Re-measure and close. Sol only, 48 h patience. Verify, no commit.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(grep '^quiet()' "$G/loop.sh")"
out=$(python3 "$cli" delegate --quota-patience 172800 --session ses_e88597636ffe3U1ZoZtVgCKRBr "External judge finding for M10-T05: no new direction is needed. Your 245/232/211 samples were taken on an overloaded machine that has since restarted. The judge measured the current tree and the committed T04 tree alternately under the same load: current 326 and 335 four-model frames, T04 333 and 342 (all 35 smoke tests passed). The headroom amendment worked; the T05 visuals and the cloud draw-order change are accepted from the refreshed dist/m10-t05/production/ screenshots.
Now: run the unchanged npm run smoke three times in a row, nothing else running, and record all three numbers in the journal and the T05 cost row together with the judge's A/B pairs. If every run is at least 300 frames with ratio at least 0.90 and the median is at least 315, mark M10-T05 DONE as the skill says (status, progress, task.done event, digest, check) and end with status DONE. Otherwise stop with BLOCKED and the numbers. No code changes. Do not commit. End with the HANDOFF block.")
echo "$out" | sed -n '1,14p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "t05f: stop"; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T05); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"
[ $rc -eq 0 ] || { echo "t05f: verify FAIL (check alone for load flake before acting)"; exit 1; }
pat=$(cd "$G" && python3 -c "import audit; print(audit.IP_TERMS.pattern)")
hits=$(git grep --untracked -nIiE "$pat" -- . ':!node_modules' ':!dist' ':!implementation/logs' ':!implementation/DIGEST.md' ':!*.journal.md')
[ -z "$hits" ] || { echo "t05f: IP hits, not committed"; echo "$hits" | head -5; exit 1; }
git add -A && git commit -q -m "checkpoint M10-T05" && git log --oneline -1
python3 "$G/audit.py" "$game" M10-T05 | grep -E "FAIL|PASS" | cut -c1-160
echo "t05f: M10-T05 committed (judge accepted the visuals before this run)"
