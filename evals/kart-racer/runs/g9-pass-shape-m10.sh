#!/usr/bin/env bash
# G9 owner-proxy pass recorded by the builder, then shape M10 (I-4); the builder stops with QUESTION or JUDGE if a choice is open.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
echo "== G9 record"
deleg "Owner: G9 passed (owner-proxy). Automated evidence on 0cd0b31: npm test 384/384, smoke 33 passed, gzip build delta 5106 bytes (< 30000), 0 page and console errors, all four racers finish 3 laps on both tracks in the real build, falls and kart collisions identical to G8 and the first G9 run, review fixes M9-T06..T11 done for all ten REVIEW-G9 findings (bar-0 phrase restart and mute clearing everything kept as designed). Listening items (first-key unlock, how the menu, track and results themes sound, final-lap tempo and cowbell, countdown, lap and finish stingers, engine, drift, boost, hit and fall effects, mute, tab-switch recovery) are owner-unverified for now; the owner may still play it and reopen findings. Record G9 as PASSED in GATE.md (tick the review-closure items with their evidence), STATUS and the event log with exactly that note, keep the skills unchanged, and end with the HANDOFF block."
echo "$out" | sed -n '1,8p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "g9: stop, record not DONE"; echo "$out" | sed -n '2,40p'; exit 1; }
git add -A && git commit -q -m "checkpoint G9 passed"
echo "== shape M10"
deleg "Use the dragonhoard-shape skill for M10 (IMPROVEMENT_PLAN.md I-4, Lantern Reach in full). If the tasks no longer fit, propose the change and stop with status QUESTION before writing packs. It is render-only: no change under src/logic/, no gameplay, physics, lap or rival change, and Ember Circuit gains only the shared sky and lighting. Read docs/m10/REFERENCE.md and the two sketches as planning material only; the game loads no image or texture file, so anything texture-like is generated in code. Every shape, including the sleeping dragon landmark, is an original design built from primitives. Record the pre-M10 evidence in T01: the gzip build size, draw calls and the M8-T08 frame measure on Lantern Reach with four racers, so later tasks compare against it. Open option 4 (sky dome and clouds) is decided by exploring, not by guessing. Write the packs and STATUS rows, run dragonhoard.py check, then stop with status QUESTION for owner approval. Don't start a task."
echo "$out" | sed -n '1,40p'
echo "shape: end"
