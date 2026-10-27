#!/usr/bin/env bash
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
cd /home/edwinidrus/hobbys/dragonhoard_test
git add -A && git commit -q -m "checkpoint shape improvements M7-M9"
echo "== C4"
python3 "$cli" delegate "What is the next task, and why are the improvements ordered track first, then racers, then music?"
git add -A && git commit -q -m "checkpoint probe C4" 2>/dev/null
echo "== M7 loop"
bash "$G/loop.sh" 11
