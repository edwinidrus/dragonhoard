#!/usr/bin/env bash
# Owner unblock of M5-T03 after F7, then the routine loop for M5-T04.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
cd /home/edwinidrus/hobbys/dragonhoard_test
out=$(python3 "$cli" delegate "Owner: (a). That 59 edit was mine and was wrong; I have already restored test/logic/loop.test.js to 60 (git diff is clean, npm test 125/125). Record the unblock in the journal and the event log, set M5-T03 back to IN_PROGRESS, then do M5-T03 from the baseline check onwards. End with the HANDOFF block." --session ses_ea2eed2c0ffewzDWWYNBMeOv9e)
echo "$out" | head -12
status=$(echo "$out" | sed -n 's/^status: *//p' | tail -1)
[ "$status" = DONE ] || { echo "resume: stop, status $status"; exit 1; }
v=$(python3 "$cli" verify M5-T03); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"
[ $rc -eq 0 ] || { echo "resume: stop, verify failed"; exit 1; }
git add -A && git commit -q -m "checkpoint M5-T03"
python3 "$G/audit.py" "$PWD" M5-T03 | grep -E "FAIL" && { echo "resume: stop, audit FAIL"; exit 1; }
echo "resume: M5-T03 DONE, verify PASS, audit PASS"
bash "$G/loop.sh" 1
