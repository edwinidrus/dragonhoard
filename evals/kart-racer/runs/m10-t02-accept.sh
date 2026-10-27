#!/usr/bin/env bash
# M10-T02 accepted by the judge (fifth amendment, generated backdrop image): re-verify (the first verify flaked under load; alone smoke 35/35, 341 frames),
# commit, audit, then start M10-T03 with an owner note on the frame budget (expected to stop with JUDGE for the clouds pick).
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
eval "$(grep '^quiet()' "$G/loop.sh")"              # quiet(): wait for port 5173
quiet; v=$(python3 "$cli" verify M10-T02); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"
[ $rc -eq 0 ] || { echo "accept: stop, verify failed again"; exit 1; }
git add -A && git commit -q -m "checkpoint M10-T02"
python3 "$G/audit.py" "$PWD" M10-T02 | grep -E "FAIL" | grep -v "^IP" && { echo "accept: stop, audit FAIL"; exit 1; }
echo "accept: M10-T02 DONE"
deleg "Use the dragonhoard-next skill. Owner note for M10-T03, decided before any T03 measurement: the M10 cost table in the M10-T02 journal is the frame budget. The unchanged full npm run smoke four-model sample is now about 341-350 frames against the 300 floor, so T03 has about 40-50 frames to spend. Any full-screen WebGL draw costs about 95 frames in the headless renderer, however trivial its shader is, while the generated backdrop behind the transparent canvas costs almost nothing on a straight. So: (1) each cloud spike measures the four-model frame count in the unchanged smoke-style run, beside its draw calls and gzip, and the external judge weighs it; (2) the far sea of clouds below the road may be painted by the same backdrop colour function below the horizon (lit warm on the sun side), with WebGL used only for near cloud puffs, if that keeps the I-4 look; (3) the floor and the 0.90 ratio stay unchanged. Stop with status JUDGE for the clouds pick, as the pack says." 
echo "$out" | sed -n '1,40p'
echo "accept: end"
