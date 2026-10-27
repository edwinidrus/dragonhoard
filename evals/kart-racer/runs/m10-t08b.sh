#!/usr/bin/env bash
# M10-T08 judge answer: visuals accepted; T08 costs about 14 frames in a balanced A/B (rule missed), so a bounded
# revision to find and remove the cause. Same session, Sol only, 48 h patience. Verify, no commit (PR landing later).
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(grep '^quiet()' "$G/loop.sh")"
out=$(python3 "$cli" delegate --quota-patience 172800 --session ses_e86ddf94effev8qKsgs2rup2U9 "External judge verdict for M10-T08: REVISE, bounded to performance; the visuals are accepted (curled green creature with horns, spines and the gold hoard on the landmark island, readable from both forward views).

The judge measured the current tree against the committed T07 tree in a balanced order (T07, T08, T08, T07, T07, T08) under equal load: T07 314/320/318 (median 318), T08 301/307/302 (median 302). So T08 costs about 14 frames, and its cold first runs were worse (your 286, a judge pair run at 254). Two merged draws and about 1,500 triangles should not cost that much, so look for the cause before cutting the look:
1. Profile with controls in the unchanged smoke setup: dragon hidden, dragon shown but update() not called, and the race-start path timed (dragonPlan, the merges, and the second farIslandPlan(track) call in src/main.js). Record each number in the journal.
2. Remove the cause with no visible change first. For example, build the dragon once and reuse it across races instead of rebuilding it on every race start, reuse the far-island plan instead of recomputing it, and merge the dragon into one draw. Your audio activeGesture failure (audio.spec.js:217) suggests the race-start path runs long after the click, so keep heavy work out of that path; do not change the audio code or its test.
3. Only if that is not enough, reduce the dragon's detail while keeping the accepted silhouette.
4. Rule unchanged: three serial runs of the unchanged npm run smoke, the first one cold (first run after a pause), every run at least 300 frames with ratio at least 0.90 and all 35 tests passing, median at least 315. The 300 floor and 0.90 ratio stay.
5. Refresh dist/m10-t08/production/ and details/.
If the rule is still missed, stop with BLOCKED and the table. Stay inside the T08 files (src/render/dragon.js, its test, the wiring in src/main.js). Do not commit. End with the HANDOFF block.")
echo "$out" | sed -n '1,14p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "t08b: stop"; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T08); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"
[ $rc -eq 0 ] || { echo "t08b: verify FAIL (check alone for load flake before acting)"; exit 1; }
echo "t08b: M10-T08 verify PASS (not committed; judge view, then runs/pr-land.sh)"
