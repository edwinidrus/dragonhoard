#!/usr/bin/env bash
# M10 shape: owner-proxy approval of the nine packs, then the loop runs T01 and T02 (T02 stops with JUDGE for the sky pick).
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
# dist/ is the gate's own vite build output: the owner ignores it so no checkpoint picks it up.
grep -qx 'dist/' .gitignore || echo 'dist/' >> .gitignore
deleg "Owner: 1) yes, approve the nine-pack cut T01-T09 as written, with the PLAN owner-decision defaults 4-9 (Ember keeps its day palette; flat yellow chevrons plus an edge lip with no height change; a render-only fall sink; seven Lantern plus two Ember spots; the 300-frame floor and 0.90 ratio unchanged; no image or texture file). 2) yes, the sequential chain T01 -> T09. 3) yes, T02 and T03 each spike both options in isolation and stop with status JUDGE for the pick before building. Two clarifications, decided now before any number is measured: (a) T01's review pose and draw-call probe in src/main.js and src/render/scene.js are allowed as observation-only hooks that are inert unless the review spec sets them; they change no gameplay and no loop order, so they are not a flow change. (b) At G10 a draw-call count above the 100 target is accepted only when it is measured per spot, all repeated scenery is instanced or merged, and the four-model Lantern measure keeps the 300-frame floor and the 0.90 ratio. Write these two into PLAN owner decisions and the T01 pack, log one shape.adjusted event, and stop; don't start a task. The owner added dist/ to .gitignore." --session ses_e8a6a04fcffeXiiMpt5weaEknG
echo "$out" | sed -n '1,8p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "m10: stop, approval not DONE"; echo "$out" | sed -n '2,40p'; exit 1; }
git add -A && git commit -q -m "checkpoint M10 packs approved"
bash "$G/loop.sh" 2
echo "exit $?"
