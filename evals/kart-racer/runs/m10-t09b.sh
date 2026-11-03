#!/usr/bin/env bash
# M10-T09 owner answer to the BLOCKED interface stop (same session): pack corrections, then build, verify, no commit (the judge views the screenshots and measures the
# frame rule by A/B on a quiet host first). Sol only (owner, 2026-10-26); a Plus limit is waited out (48 h patience).
# The trial was reopened by the owner on 2026-10-27 to finish T09 and G10; commits stay local until the owner pushes.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(grep '^quiet()' "$G/loop.sh")"
out=$(python3 "$cli" delegate --quota-patience 172800 --session ses_e81226a1cffeZ46J5wCbJC5WHl "Owner answer to your M10-T09 BLOCKED (owner amendment by the external judge, 2026-10-27; rule: smallest amendment that keeps scope). Your stop was right on both points. (1) Correct the two createScenery(plan) references in the M10-T09 pack to createScenery(track), as the code has it. (2) Gold: not a mask on the shared material. Leave the gold piles out of the legacy static merge and merge all gold cones into one separate mesh with its own MeshLambertMaterial in the existing GOLD colour (one added draw, no shader injection, no onBeforeCompile); the glint is that material's emissive intensity pulsed by time and the camera/player angle, as the pack says. Rocks, tops and their shading stay in the existing merged draw and look the same. The new gold material and geometry are disposed with the scenery group as before. Record both corrections in the pack as 'owner amendment (external judge), 2026-10-27' and log shape.adjusted, then continue the task from Verify. Everything else in my first note stays: the load exception for the frame floor and HUD timing test, recording all smoke numbers and the T09 cost row, evidence into dist/m10-t09/production/ and details/, the judge's A/B before the commit, no commit. End with the HANDOFF block.")
echo "$out" | sed -n '1,14p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "t09b: stop"; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T09); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"
[ $rc -eq 0 ] || { echo "t09b: verify FAIL (smoke frame floor expected on a loaded host; the judge checks the rest)"; exit 1; }
echo "t09b: M10-T09 verify PASS (not committed; the judge views the evidence and measures A/B first)"
