#!/usr/bin/env bash
# G8 owner-proxy pass recorded by the builder, then shape M9 (the builder stops with QUESTION or JUDGE if a choice is open).
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
echo "== G8 record"
deleg "Owner: G8 passed (owner-proxy). Automated evidence on 60c7c5b: npm test 309/309, smoke 19 passed, all four racers finish 3 laps on both tracks in the real build, falls, jumps and collisions as at G7, the four-model frame test keeps the 300-frame floor with a same-run ratio of 0.945, 0 console errors, review fixes M8-T09..T17 done. Hands-on feel items (racer menu feel, recognisability and idle animations from the chase camera, weight feel in bumps, headed ~60 fps smoothness) are owner-unverified for now; the owner may still play it and reopen findings. Record G8 as PASSED in GATE.md (tick the review-closure items with their evidence), STATUS and the event log with exactly that note, keep the skills unchanged, and end with the HANDOFF block."
echo "$out" | sed -n '1,8p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "g8: stop, record not DONE"; echo "$out" | sed -n '2,40p'; exit 1; }
git add -A && git commit -q -m "checkpoint G8 passed"
echo "== shape M9"
deleg "Use the dragonhoard-shape skill for M9. If the tasks no longer fit, propose the change and stop with status QUESTION before writing packs. Every sound stays synthesised and original (M9 art. 1): no melody, rhythm or sound effect taken from an existing game or song. Record the pre-M9 gzip build baseline in T01's evidence. Direction the owner was shown as a starting point (original, change freely if the plan needs it): F major, menu calm; Ember theme about 152 BPM and brassy, Lantern theme about 160 BPM and bell-like with a short echo; final lap +8 % tempo with the cowbell; light swing. Write the packs and STATUS rows, run dragonhoard.py check, then stop with status QUESTION for owner approval. Don't start a task."
echo "$out" | sed -n '1,40p'
echo "shape: end"
