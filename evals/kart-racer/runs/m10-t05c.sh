#!/usr/bin/env bash
# M10-T05 answer to BLOCKED (frame floor 285 < 300; cost follows covered pixels, not triangles): bounded
# surface/overdraw reduction inside T05's files. Sol only, 48 h patience. Verify, no commit.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(grep '^quiet()' "$G/loop.sh")"
out=$(python3 "$cli" delegate --quota-patience 172800 --session ses_e88597636ffe3U1ZoZtVgCKRBr "Owner answer to your BLOCKED question: approved, bounded as follows. Judge preview of the 11 PNGs: the direction is accepted (grass verges, lip, cliff sides and taper read well; the road stays readable); the final visual check comes after the numbers.

Your controls show the cost follows screen coverage and overdraw, not triangles (halving detail gave 5 frames, hiding the batch gave 337). So:
1. Profile the body surfaces with serial controls as before (top, lip, sides, underside, spikes, scatter, one at a time) and record each number.
2. Reduce surface work, smallest visual change first, for example: no top or grass surface under the road corridor (the road already covers it), drop faces the chase camera never sees (inner shell faces, caps hidden by the road), and narrow the grass verge or the visible underside extent. Keep the required grass, lip, taper, spikes, hazard holes, clearance and the landmark sightlines from both forward views.
3. Stay inside T05's files (src/render/sceneryData.js, src/render/scenery.js, the focused test, the journal and cost rows). Do not change the smoke, the renderer, the pixel ratio, quality settings, other tasks' geometry or any threshold. The 300 floor and the 0.90 ratio stay.
4. Leave as much headroom as you can for T06-T09 and report the final unchanged-smoke frame count and the headroom left.
5. At most three measured reduction steps. If the unchanged smoke is still under 300 after them, stop with BLOCKED and the numbers.
Then refresh dist/m10-t05/production/ (the nine spots plus the two forward views). Do not commit. End with the HANDOFF block.")
echo "$out" | sed -n '1,14p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "t05c: stop"; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T05); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"
[ $rc -eq 0 ] || { echo "t05c: verify FAIL (check alone for load flake before acting)"; exit 1; }
echo "t05c: M10-T05 verify PASS (not committed; the judge views the evidence first)"
