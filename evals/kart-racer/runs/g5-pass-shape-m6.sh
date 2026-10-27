#!/usr/bin/env bash
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
cd /home/edwinidrus/hobbys/dragonhoard_test
python3 "$cli" delegate "Owner: G5 check done on the build after M5-T05..T11. In the browser: nothing moves before GO; the HUD reads 1st right after GO and updates as rivals pass; 3 laps count; the results list Gold 1:44.183, Green 1:52.400, Red 2:00.983, You 2:22.733 in finish order; Enter restarts at the countdown with lap 0 and time 0; no console errors. Mark G5 PASSED; HUD readability and feel are deferred to my final play-test. Record it and stop; do not start a task." --session ses_ea2d9e35effebMgvnGNnOqBMc2 | sed -n '1,4p'
git add -A && git commit -q -m "checkpoint G5 passed"
python3 "$cli" delegate "Use the dragonhoard-shape skill for M6. If the tasks no longer fit, propose the change and stop with status QUESTION before writing packs."
