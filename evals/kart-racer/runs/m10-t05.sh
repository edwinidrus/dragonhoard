#!/usr/bin/env bash
# M10-T05 road islands: build, verify, no commit (the judge views the screenshots first). Sol only, no
# DeepSeek fallback (owner, 2026-10-26); a Plus limit is waited out (48 h patience).
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(grep '^quiet()' "$G/loop.sh")"
out=$(python3 "$cli" delegate --quota-patience 172800 "Use the dragonhoard-next skill. Owner note for M10-T05, decided before any T05 measurement: (1) Budget: after T04 the unchanged full npm run smoke four-model sample is 331 frames against the 300 floor (T04 measured 323 to 331 across runs, so treat about 25 frames as the real headroom), and T05-T09 share it. Spend as little as T05 can: merge or instance the island bodies, trees, bushes and rocks into as few draws as possible, low-poly, no new shadow casters, no full-screen draw. Measure the four-model frame count with the unchanged smoke and add the T05 row to the M10 cost table in the M10-T02 journal. If it misses 300 frames or the 0.90 ratio, first reduce the tree/bush/rock counts, then the detail, and report each number; the thresholds stay. (2) Evidence: save the production screenshots of the nine fixed review spots plus the two forward chase-camera views from T04 (start grid, hairpin exit) into dist/m10-t05/production/, a folder Playwright does not wipe; the judge views them before the commit. Keep the road readable: nothing on the road corridor, and T04's landmark island stays unoccluded in both forward views. (3) Naming rule as in T03/T04: an angle-and-radius layout is a radial grid or a ring grid. End with the HANDOFF block.")
echo "$out" | sed -n '1,14p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "t05: stop"; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T05); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"
[ $rc -eq 0 ] || { echo "t05: verify FAIL (check alone for load flake before acting)"; exit 1; }
echo "t05: M10-T05 verify PASS (not committed; the judge views the evidence first)"
