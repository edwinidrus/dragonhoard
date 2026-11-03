#!/usr/bin/env bash
# M9: owner-proxy approval of the five packs, then the loop runs M9-T01..T05 (T01 should stop with JUDGE on the engine pick).
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
deleg "Owner: yes, approve the M9-T01..T05 packs as written, in order T01..T05. Log one shape.adjusted event and stop; don't start a task." --session ses_e8bbc6715ffegG9s5H6xWdwSVB
echo "$out" | sed -n '1,8p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "m9: stop, approval not DONE"; echo "$out" | sed -n '2,40p'; exit 1; }
git add -A && git commit -q -m "checkpoint M9 packs M9-T01..T05 approved"
bash "$G/loop.sh" 5
