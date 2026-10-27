#!/usr/bin/env bash
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
cd /home/edwinidrus/hobbys/dragonhoard_test
out=$(python3 "$cli" delegate "verify failed: FAIL  journal: attempt with Ran and Outcome. Fix only that: the M7-T12 journal attempt needs its Ran lines (the real commands and their output) and an Outcome line. Then end with the HANDOFF block." --session ses_e95cbe96effelEkz3Wq9uyVR8J)
echo "$out" | head -6
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "resume: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
v=$(python3 "$cli" verify M7-T12); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"; [ $rc -eq 0 ] || { echo "resume: stop, verify failed again (escalate)"; exit 1; }
git add -A && git commit -q -m "checkpoint M7-T12"
python3 "$G/audit.py" "$PWD" M7-T12 | grep -E "FAIL" && { echo "resume: stop, audit FAIL"; exit 1; }
echo "resume: M7-T12 DONE (attempt 2), verify PASS, audit PASS"
bash "$G/loop.sh" 6
