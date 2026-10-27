#!/usr/bin/env bash
# M9-T07: the loop stopped after verify attempt 2 failed in npm run smoke (it ran 10 s after the builder's own run, under load); alone smoke 33/33 twice.
# The auditor re-ran verify clean (PASS); commit, audit, then the loop runs T08..T11.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cd /home/edwinidrus/hobbys/dragonhoard_test
git add -A && git commit -q -m "checkpoint M9-T07"
python3 "$G/audit.py" "$PWD" M9-T07 | grep -E "FAIL" | grep -v "^IP" && { echo "resume: stop, audit FAIL"; exit 1; }
echo "resume: M9-T07 DONE"
bash "$G/loop.sh" 4
echo "exit $?"
