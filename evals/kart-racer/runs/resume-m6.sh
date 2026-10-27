#!/usr/bin/env bash
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
cd /home/edwinidrus/hobbys/dragonhoard_test
git add -A && git commit -q -m "checkpoint M6-T01 (blocked by F8)"
out=$(python3 "$cli" delegate "Owner: that applySlowCurve Consumes line was a wrong edit of mine; I have restored the pack (git diff clean), so no journal amendment is needed: the slow reuses the existing fade at kart.js:61-67 as the pack now says. Record the unblock in the journal and event log, set M6-T01 back to IN_PROGRESS, and do M6-T01 from Verify onwards. End with the HANDOFF block." --session ses_ea296e554ffeW4dWrGmlfkYjN2)
echo "$out" | head -10
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "resume: stop"; exit 1; }
v=$(python3 "$cli" verify M6-T01); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"; [ $rc -eq 0 ] || { echo "resume: stop, verify failed"; exit 1; }
git add -A && git commit -q -m "checkpoint M6-T01"
python3 "$G/audit.py" "$PWD" M6-T01 | grep -E "FAIL" && { echo "resume: stop, audit FAIL"; exit 1; }
echo "resume: M6-T01 DONE, verify PASS, audit PASS"
bash "$G/loop.sh" 2
