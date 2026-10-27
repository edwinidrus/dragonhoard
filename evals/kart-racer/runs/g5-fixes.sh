#!/usr/bin/env bash
# Owner-proxy approval of the G5 fix tasks, checkpoint, then the routine loop over them.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
cd /home/edwinidrus/hobbys/dragonhoard_test
python3 "$cli" delegate "Owner: 1) approve M5-T05..M5-T11 as shaped. 2) accept the amended finding-2 fix (record finishS at the finish step, then tie-break); keep T06/T07. Log these as one shape.adjusted event and stop; do not start a task." --session ses_ea2d9e35effebMgvnGNnOqBMc2 | sed -n '1,3p'
git add -A && git commit -q -m "checkpoint G5 review fix tasks M5-T05..T11 approved"
bash "$G/loop.sh" 7
