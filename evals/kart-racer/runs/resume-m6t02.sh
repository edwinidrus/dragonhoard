#!/usr/bin/env bash
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
cd /home/edwinidrus/hobbys/dragonhoard_test
out=$(python3 "$cli" delegate "Owner: (a). Pin the rival's lane (laneOffset 2.5) and assert the boost-aware cap maxSpeed*slowFactor + boostBonus(entry.boost) + 0.05, as the smallest honest amendment; record it as an owner-approved amendment in the pack and the event log, then finish M6-T02 from Build. End with the HANDOFF block." --session ses_ea28e5948ffedIKwv7ekGgKUnw)
echo "$out" | head -8
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "resume: stop"; exit 1; }
v=$(python3 "$cli" verify M6-T02); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"; [ $rc -eq 0 ] || { echo "resume: stop, verify failed"; exit 1; }
git add -A && git commit -q -m "checkpoint M6-T02"
python3 "$G/audit.py" "$PWD" M6-T02 | grep -E "FAIL" && { echo "resume: stop, audit FAIL"; exit 1; }
echo "resume: M6-T02 DONE, verify PASS, audit PASS"
bash "$G/loop.sh" 1
