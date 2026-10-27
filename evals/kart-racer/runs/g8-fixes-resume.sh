#!/usr/bin/env bash
# Resume after the owner's pause at M8-T09 (partial T09 diff uncommitted): finish T09 in its session, then the loop runs T10..T17.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
deleg "Continue where you stopped." --session ses_e8c8ffa16ffec2Pep9aRAl7yVa
echo "$out" | head -10
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "resume: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
v=$(python3 "$cli" verify M8-T09); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"; [ $rc -eq 0 ] || { echo "resume: stop, verify failed"; exit 1; }
git add -A && git commit -q -m "checkpoint M8-T09"
python3 "$G/audit.py" "$PWD" M8-T09 | grep -E "FAIL" | grep -v "^IP" && { echo "resume: stop, audit FAIL"; exit 1; }
echo "resume: M8-T09 DONE"
bash "$G/loop.sh" 8
