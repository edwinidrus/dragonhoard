#!/usr/bin/env bash
# M10-T04 judge answer: the islands are accepted, the landmark slot is revised (owner amendment, rule 3).
# Same builder session, Sol only; a Plus limit is waited out (48 h patience). Verify, no commit.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(grep '^quiet()' "$G/loop.sh")"
out=$(python3 "$cli" delegate --quota-patience 172800 --session ses_e8889c99bffeyZacH06SB9Z5Ys "External judge verdict for M10-T04: REVISE, bounded to the landmark slot.

Accepted as delivered: the ring grid of 12 low-poly islands in one merged draw, no shadows, skyline in every Lantern review direction, the road corridor clear, Ember unchanged, 323 frames and ratio 0.968.

Your question, answered: yes, the landmark must be in the forward chase-camera view on the start straight. docs/m10/REFERENCE.md says the shape task measures the spot from pointAt and the camera heading, and the player is meant to see the dragon while racing, not by looking back. The start straight heads east and the hairpin's outward bearing points west, so the pack's outward-bearing rule cannot meet that.

Owner amendment (smallest change, decided by the owner's proxy): in M10-T04 and in M10-T08's preconditions and BLOCKED line, replace 'on the hairpin's outward bearing' with 'measured from pointAt and the chase-camera heading so that the slot is inside the forward chase-camera view (within 25 degrees of the camera heading, not hidden by other islands) on the start straight from the grid, and at one chase-camera pose in the hairpin (entry, apex or exit)'. Everything else in both packs stays. Note the amendment in both packs as 'owner amendment (external judge), 2026-10-26'.

Then:
1. Move the slot in farIslandPlan by that rule: outside the road corridor, inside the 500 m far plane, near enough that the fog leaves it readable. Keep the island count, the single draw and no shadows.
2. Update the focused test so it asserts the new rule (the angle from the grid pose and from the chosen hairpin pose), not the outward bearing.
3. Re-measure the four-model frame count with the unchanged npm run smoke and update the T04 cost row. The 300 floor and 0.90 ratio stay.
4. Re-capture dist/m10-t04/production/: the nine fixed spots plus two forward chase-camera views (start grid, and the hairpin pose you chose) that show the slot island; they replace the two look-back slot views.

If no slot meets both views inside the far plane and off the road, stop with BLOCKED and the measured angles. Do not commit. End with the HANDOFF block.")
echo "$out" | sed -n '1,14p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "t04j: stop"; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T04); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"
[ $rc -eq 0 ] || { echo "t04j: verify FAIL (check alone for load flake before acting)"; exit 1; }
echo "t04j: M10-T04 verify PASS (not committed; the judge views the evidence first)"
