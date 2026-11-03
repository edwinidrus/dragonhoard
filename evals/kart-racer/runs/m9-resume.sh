#!/usr/bin/env bash
# Resume M9 after the session closed at M9-T02 (committed 790b53e, audited by hand): the loop runs T03..T05.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cd /home/edwinidrus/hobbys/dragonhoard_test
bash "$G/loop.sh" 3
echo "exit $?"
