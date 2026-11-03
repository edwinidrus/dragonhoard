#!/usr/bin/env bash
# M9-T03 BLOCKED twice: (a) bounded audio.spec.js amendment, then the observation-only probe helpers; finish T03, then the loop runs T04..T05.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
deleg "Owner: yes. The observation-only helper additions are allowed: the probe and the longVoice helper may record source identities, cancellation and echo events, and scheduling windows. They are needed to meet condition 2. Limits: they only record, never change what an existing assertion sees or when it runs; every existing test body and assertion stays byte-identical except the three approved recovery sites; and the 30 smoke tests pass before and after the helper change, before any T03 code. Record the helper diff in the journal. Then build T03 test first, as approved. End with the HANDOFF block." --session ses_e8b54de07ffeTEetpScvyz0Wuc
echo "$out" | sed -n '1,10p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "resume: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
v=$(python3 "$cli" verify M9-T03); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"; [ $rc -eq 0 ] || { echo "resume: stop, verify failed"; exit 1; }
git add -A && git commit -q -m "checkpoint M9-T03"
python3 "$G/audit.py" "$PWD" M9-T03 | grep -E "FAIL" | grep -v "^IP" && { echo "resume: stop, audit FAIL"; exit 1; }
echo "resume: M9-T03 DONE"
bash "$G/loop.sh" 2
echo "exit $?"
