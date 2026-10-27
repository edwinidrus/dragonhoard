#!/usr/bin/env bash
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
cd /home/edwinidrus/hobbys/dragonhoard_test
out=$(python3 "$cli" delegate "Owner: amendment approved. Your root cause checks out: the last safe point 547.95 is always behind the bridge [560, 590), updateLaps counts only ds > 0, and the target checkpoint never lies inside the set-back span, so the named mutation can't be observed on this geometry. Replace acceptance 4 in the pack with exactly: \"Falling never changes laps.laps or laps.next, asserted deep-equal on every step of the fall and its set-back; the skip is structural (the set-back is always behind the fall, so updateLaps could not count even if called). The surviving 'remove the lap skip' and swapped-argument mutations are recorded in the journal as evidence.\" Record it as an owner-approved amendment in the pack, the journal and the event log. One more fix in a file you already touch: the race.js comment on the fall step says the kart's at 'stays the last on-road value', but the code stores the located fall point; correct the comment to match the code (no behaviour change). Keep your bridge-edge risk for G7. Re-run npm test and npm run smoke, tick the acceptance, mark M7-T05 DONE. End with the HANDOFF block." --session ses_e96350e36ffeerGFJcHYzuaMpw)
echo "$out" | head -10
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "resume: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
v=$(python3 "$cli" verify M7-T05); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"; [ $rc -eq 0 ] || { echo "resume: stop, verify failed"; exit 1; }
git add -A && git commit -q -m "checkpoint M7-T05"
python3 "$G/audit.py" "$PWD" M7-T05 | grep -E "FAIL" && { echo "resume: stop, audit FAIL"; exit 1; }
echo "resume: M7-T05 DONE, verify PASS, audit PASS"
bash "$G/loop.sh" 6
