#!/usr/bin/env bash
# M10-T04 far islands: build, verify, no commit (the judge views the screenshots first). Sol only: the
# DeepSeek fallback is out (OpenRouter key credit cap, 402), so a Plus limit is waited out (delegate's 6 h patience).
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(grep '^quiet()' "$G/loop.sh")"
out=$(python3 "$cli" delegate "Use the dragonhoard-next skill. Owner note for M10-T04, decided before any T04 measurement: (1) Budget: after T03 the unchanged full npm run smoke four-model sample is 338 frames against the 300 floor, and T04-T09 share those 38 frames. Spend as little as T04 can: the islands in one or two draws (instanced or merged), low-poly, no shadows cast or received, no full-screen draw. Measure the four-model frame count with the unchanged smoke and add the T04 row to the M10 cost table in the M10-T02 journal. If it misses 300 frames or the 0.90 ratio, first reduce the island count and then the detail, and report each number; the thresholds stay. (2) Evidence: save the production screenshots of the nine fixed review spots, plus one view toward the landmark slot from the hairpin, into dist/m10-t04/production/, a folder Playwright does not wipe; the judge views them before the commit. (3) Naming rule as in T03: an angle-and-radius layout is a radial grid or a ring grid. End with the HANDOFF block.")
echo "$out" | sed -n '1,12p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "t04: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T04); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"
[ $rc -eq 0 ] || { echo "t04: verify FAIL (check alone for load flake before acting)"; exit 1; }
echo "t04: M10-T04 verify PASS (not committed; the judge views the evidence first)"
