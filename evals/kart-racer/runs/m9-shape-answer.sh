#!/usr/bin/env bash
# M9 shape: approve the five-task cut (contact telemetry before effects); the builder writes the packs and stops with QUESTION.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
deleg "Owner: yes, approve the five-task cut: insert the kart-contact telemetry task before the effects task and renumber the old T04 to T05. Condition: the telemetry is read-only output of the step that already resolves contacts. With the same inputs, every kart's state must deep-equal the state before the change, on both tracks, and its pack needs a test for exactly that. Physics, timing, ranking and race flow stay unchanged (M9 art. 8). Now write the five packs and STATUS rows, run dragonhoard.py check, then stop with status QUESTION for pack approval. Don't start a task." --session ses_e8bbc6715ffegG9s5H6xWdwSVB
echo "$out" | sed -n '1,40p'
echo "answer: end"
