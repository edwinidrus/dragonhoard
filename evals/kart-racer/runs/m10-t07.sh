#!/usr/bin/env bash
# M10-T07 jump dressing: build, verify, no commit (the judge views the screenshots first). Sol only, no DeepSeek
# fallback (owner, 2026-10-26); a Plus limit is waited out (48 h patience).
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(grep '^quiet()' "$G/loop.sh")"
out=$(python3 "$cli" delegate --quota-patience 172800 "Use the dragonhoard-next skill. Owner note for M10-T07, decided before any T07 measurement: (1) Budget: after T06 the unchanged full npm run smoke measured 311/335/332 four-model frames (median 332) on this machine; T07-T09 share the room above the 300 floor. The judge's acceptance rule since T05: three serial runs of the unchanged smoke with nothing else running, every run at least 300 frames with ratio at least 0.90, and a median of at least 315. Record all three numbers and add the T07 row to the M10 cost table in the M10-T02 journal. Screen area is what costs here, not triangles: keep the jump chevrons, ramps and bridge end posts small and narrow, merge repeats into few draws, no shadows cast or received, no full-screen or transparent large surfaces. If the rule is missed, first thin or shorten the dressing, then drop detail, and report each number; the thresholds stay. If the numbers look far off (more than 20 frames below T06), stop with BLOCKED and the numbers, since the machine load may be the cause and the judge checks that. (2) Evidence: save the production screenshots of the nine fixed review spots plus the two forward chase-camera views (start grid, hairpin exit) into dist/m10-t07/production/; the judge views them before the commit. The road must stay readable and T04's landmark island must stay unoccluded in both forward views. (3) Naming rule as before: an angle-and-radius layout is a radial grid or a ring grid. End with the HANDOFF block.")
echo "$out" | sed -n '1,14p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "t07: stop"; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T07); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"
[ $rc -eq 0 ] || { echo "t07: verify FAIL (check alone for load flake before acting)"; exit 1; }
echo "t07: M10-T07 verify PASS (not committed; the judge views the evidence first)"
