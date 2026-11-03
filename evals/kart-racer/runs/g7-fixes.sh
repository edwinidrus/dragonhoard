#!/usr/bin/env bash
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
while pgrep -f "g7-browser2.sh" >/dev/null; do sleep 15; done # keep the auditor's browser evidence on 97f5949
cd /home/edwinidrus/hobbys/dragonhoard_test
python3 "$cli" delegate "Owner: 1) yes, approve the 7-pack append M7-T12..T18 as shaped. 2) yes, split (f) into T17 (15+18) and T18 (16+17). 3) yes, accept T17's caveat: test-only, with acceptance as the checked mutation pair. Run them in order T12..T18. Log one shape.adjusted event and stop; don't start a task." --session ses_e95d95e68ffevBxQy3Q6HzFrSe | sed -n '1,4p'
git add -A && git commit -q -m "checkpoint G7 review fix tasks M7-T12..T18 approved"
bash "$G/loop.sh" 7
