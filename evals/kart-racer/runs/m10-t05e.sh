#!/usr/bin/env bash
# M10-T05 judge answer: seams accepted; T05 sits on the 300 floor (judge samples 285/305/302), so a bounded
# headroom step (owner amendment, rule 3). Sol only, 48 h patience. Verify, no commit.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(grep '^quiet()' "$G/loop.sh")"
out=$(python3 "$cli" delegate --quota-patience 172800 --session ses_e88597636ffe3U1ZoZtVgCKRBr "External judge verdict for M10-T05: the seam closure is accepted (both jump ends and the hairpin are closed). The 3-frame cap is withdrawn: your own control (pre-change 295 against 308) shows the skirt cost is inside run noise. The floor is what counts, and it is not met reliably: the judge ran the unchanged npm run smoke three times in a row on the current tree and got four-model 285 (FAIL), 305, 302.

Owner amendment to the M10-T05 pack (smallest change that keeps scope; note it in the pack as owner amendment, 2026-10-26): add one bounded headroom step.
1. Profile: measure the four-model frame count with each Lantern render layer hidden one at a time (sky dome, sea, each cloud layer, far islands, the T05 batch, the existing scenery), two samples each, in a table in the journal.
2. Recover headroom without visible change first: draw large backgrounds (sky dome, sea and cloud planes) after the opaque geometry with depth testing so they shade only uncovered pixels, cull what is off screen, and skip depth writes where it is safe. Only if that is not enough, make the smallest visible reduction in the most expensive layer.
3. The allowed files grow to the Lantern render-layer files in src/render/ (sky, clouds, far islands, scenery, scenery data) and the wiring order in src/main.js. Do not change the smoke, the renderer, the pixel ratio, quality settings, src/logic/ or any threshold.
4. Target: three serial runs of the unchanged npm run smoke, every run at least 300 frames with ratio at least 0.90, and a median of at least 315. Report all three numbers.
5. Refresh dist/m10-t05/production/ (the nine spots plus the two forward views). If a T02, T03 or T04 layer looks different, say so and point to its accepted evidence (dist/m10-t03/production/, dist/m10-t04/production/).
If the target is not met, stop with BLOCKED and the table. Do not commit. End with the HANDOFF block.")
echo "$out" | sed -n '1,14p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "t05e: stop"; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T05); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"
[ $rc -eq 0 ] || { echo "t05e: verify FAIL (check alone for load flake before acting)"; exit 1; }
echo "t05e: M10-T05 verify PASS (not committed; the judge views the evidence first)"
