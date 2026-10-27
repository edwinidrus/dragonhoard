#!/usr/bin/env bash
# M9-T04: the loop stopped after verify attempt 2 failed on a port collision (the builder's own verify run still held 5173).
# The auditor stopped that run and re-ran verify clean (PASS); commit, audit, then the loop runs T05.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cd /home/edwinidrus/hobbys/dragonhoard_test
git add -A && git commit -q -m "checkpoint M9-T04"
python3 "$G/audit.py" "$PWD" M9-T04 | grep -E "FAIL" | grep -v "^IP" && { echo "resume: stop, audit FAIL"; exit 1; }
echo "resume: M9-T04 DONE"
bash "$G/loop.sh" 1
echo "exit $?"
