#!/usr/bin/env bash
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
cd /home/edwinidrus/hobbys/dragonhoard_test
out=$(python3 "$cli" delegate "Owner: amendment approved as you worded it: acceptance 3 becomes \"the Lantern screenshot set shows rocks/islands, gold piles and all 8 lanterns across the lap, none on the road; the two countdown shots 1 s apart show the lanterns moving\". No code change, no clustering, no camera hook. Your projection evidence checks out: at most 3 lanterns fit in the 60 degree chase frame, the unit test asserts the count of 8, and I viewed the start frame. Record it as an owner-approved amendment in the pack, the journal and the event log, tick the acceptance, and mark M7-T11 DONE. End with the HANDOFF block." --session ses_e95f1d0b9ffeYCrFyz5lkAiUEF)
echo "$out" | head -10
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "resume: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
v=$(python3 "$cli" verify M7-T11); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"; [ $rc -eq 0 ] || { echo "resume: stop, verify failed"; exit 1; }
git add -A && git commit -q -m "checkpoint M7-T11"
python3 "$G/audit.py" "$PWD" M7-T11 | grep -E "FAIL" && { echo "resume: stop, audit FAIL"; exit 1; }
echo "resume: M7-T11 DONE, verify PASS, audit PASS"
python3 "$cli" next; echo "resume: end"
