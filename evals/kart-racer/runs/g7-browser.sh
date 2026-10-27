#!/usr/bin/env bash
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer; game=/home/edwinidrus/hobbys/dragonhoard_test; out=$G/gates/G7; D=/home/edwinidrus/hoard-play
cd "$G"
echo "== race ember"; FULL=1 timeout 600 node lap.mjs "$D" "$game" 3 400 > "$out/race-ember.json"; cut -c1-600 "$out/race-ember.json"
echo "== race lantern"; TRACK=lantern FULL=1 SHOTDIR="$out" timeout 600 node lap.mjs "$D" "$game" 3 400 > "$out/race-lantern.json"; cut -c1-600 "$out/race-lantern.json"
echo "== ember"; SHOT="$out/ember.png" timeout 300 node ember.mjs "$D" "$game" > "$out/ember.json"; cat "$out/ember.json"
echo "== g7 browser end"
