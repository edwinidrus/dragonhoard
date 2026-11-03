#!/usr/bin/env bash
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer; game=/home/edwinidrus/hobbys/dragonhoard_test; out=$G/gates/G7; D=/home/edwinidrus/hoard-play
cd "$G"
echo "== lantern trace"; TRACK=lantern TRACE=1 FULL=1 timeout 600 node lap.mjs "$D" "$game" 3 400 > "$out/race-lantern-trace.json"; cut -c1-300 "$out/race-lantern-trace.json"
for i in 1 2 3 4; do echo "== ember item $i"; EMBER=1 timeout 300 node lap.mjs "$D" "$game" 1 150 > "$out/ember-$i.json"; python3 -c "import json; d=json.load(open('$out/ember-$i.json')); print(json.dumps(d.get('ember'))[:400], d['pageErrors'])"; done
echo "== g7 browser2 end"
