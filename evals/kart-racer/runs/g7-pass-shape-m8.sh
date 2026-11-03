#!/usr/bin/env bash
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
cd /home/edwinidrus/hobbys/dragonhoard_test
echo "== G7 record"
python3 "$cli" delegate "Owner: G7 passed (owner-proxy). Automated evidence: npm test 260/260, smoke 11 passed, both tracks race 3 laps headless in the real build with results and Enter restart, falls and jumps behave as specified, 0 console errors. Hands-on feel items (menu feel, jump and fall feel, scenery look) are owner-unverified for now; the owner may still play it and reopen findings. Record G7 as PASSED in GATE.md, STATUS and the event log with exactly that note, keep the skills unchanged, and end with the HANDOFF block."
git add -A && git commit -q -m "checkpoint G7 passed"
echo "== shape M8"
python3 "$cli" delegate "Use the dragonhoard-shape skill for M8. If the tasks no longer fit, propose the change and stop with status QUESTION before writing packs. Carry forward the M7-T07 risk: per-racer stats must re-check take-off speeds against each jump's minSpeed on Lantern Reach."
