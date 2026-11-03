#!/usr/bin/env bash
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
cd /home/edwinidrus/hobbys/dragonhoard_test
python3 "$cli" delegate "Owner: 1) approve M6-T04 and M6-T05 as shaped. 2) yes, all four are real; fix them all. 3) run T04 then T05. Log one shape.adjusted event and stop; do not start a task." --session ses_ea248ea57ffelnN0uQbZcl9NMP | sed -n '1,3p'
git add -A && git commit -q -m "checkpoint G6 review fix tasks M6-T04..T05 approved"
bash "$G/loop.sh" 2
