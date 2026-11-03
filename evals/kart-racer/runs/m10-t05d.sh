#!/usr/bin/env bash
# M10-T05 judge answer: accept the reduced surfaces, close the sky slits under the road edges (bounded). Sol only,
# 48 h patience. Verify, no commit.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(grep '^quiet()' "$G/loop.sh")"
out=$(python3 "$cli" delegate --quota-patience 172800 --session ses_e88597636ffe3U1ZoZtVgCKRBr "External judge verdict for M10-T05: REVISE, one bounded visual fix; everything else is accepted (narrower verges, slender plants, road readability, the landmark in both forward views, 308 frames, ratio 0.99).

The sky slits are visible in the fixed review spots: at the jump ends (m10-jump-1 and m10-jump-2) a sky band about 4 px tall crosses the full road width between the road's cut end and the landmass top, so the road looks detached; in m10-hairpin a thin light seam runs between the grass verge and the lip. Owner direction (one more step, outside the three-step allowance): close every gap with narrow geometry only, for example a short vertical skirt under each road edge and cut end down to the landmass top, or by moving the lip up to meet the road's underside. Do not bring back a surface under the road corridor. Stay inside T05's files, add a focused test that asserts the closure (no vertical gap between the road edge and the landmass along the spans and at the jump cut ends), re-measure with the unchanged npm run smoke and add the cost row. The 300 floor and the 0.90 ratio stay; if the fix costs more than 3 frames, report the number and stop with BLOCKED. Refresh dist/m10-t05/production/ (nine spots plus the two forward views). Do not commit. End with the HANDOFF block.")
echo "$out" | sed -n '1,14p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "t05d: stop"; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T05); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"
[ $rc -eq 0 ] || { echo "t05d: verify FAIL (check alone for load flake before acting)"; exit 1; }
echo "t05d: M10-T05 verify PASS (not committed; the judge views the evidence first)"
