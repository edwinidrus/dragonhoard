#!/usr/bin/env bash
# G8 review fixes: owner-proxy approval of the nine packs, then the loop runs M8-T09..T17.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
deleg "Owner: 1) yes, approve the nine-pack cut M8-T09..T17 as shaped. 2) yes, fixed bar maxima speed 25 m/s, accel 15 m/s², steer 3 rad/s with the pinned fractions in T12. 3) yes, the fps ratio >= 0.90 against the same-run Cinder-only baseline, on top of the unchanged >= 300-frame floor. Run them in order T09..T17. Log one shape.adjusted event and stop; don't start a task." --session ses_e8c9d13b0ffeTQm2cvVYKT2U9c
echo "$out" | sed -n '1,8p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "fixes: stop, approval not DONE"; echo "$out" | sed -n '2,40p'; exit 1; }
git add -A && git commit -q -m "checkpoint G8 review fix tasks M8-T09..T17 approved"
bash "$G/loop.sh" 9
