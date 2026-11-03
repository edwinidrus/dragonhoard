#!/usr/bin/env bash
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
cd /home/edwinidrus/hobbys/dragonhoard_test
echo "== G6 record"
python3 "$cli" delegate "Owner: G6 check done on the build after M6-T04..T05. In the browser I picked up the ember from the first box, Shift fired it, and a rival it hit slowed from 17.8 to 11.0 m/s and recovered; the 3-lap race, the HUD (1st right after GO), the results and the Enter restart all still work; no console errors. Mark G6 PASSED; feel is deferred to my final play-test. Record it and stop; do not start a task." --session ses_ea248ea57ffelnN0uQbZcl9NMP | sed -n '1,4p'
git add -A && git commit -q -m "checkpoint G6 passed (base game complete)"
echo "== C3"
python3 "$cli" delegate "What is the next task, and why did we choose pure pursuit for rival steering?"
git add -A && git commit -q -m "checkpoint probe C3" 2>/dev/null
echo "== improvements shape"
python3 "$cli" delegate "Use the dragonhoard-shape skill on IMPROVEMENT_PLAN.md. Propose the milestone cut first and stop with status QUESTION before writing anything."
