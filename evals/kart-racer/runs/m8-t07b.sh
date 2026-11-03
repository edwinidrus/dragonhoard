#!/usr/bin/env bash
# M8-T07 balance BLOCKED: owner-proxy retune (4 % kept), then T08 resumes once the baseline is green.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
finish() { # verify, commit, audit one task
  v=$(python3 "$cli" verify "$1"); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"; [ $rc -eq 0 ] || { echo "resume: stop, verify failed"; echo "$v" | head -20; exit 1; }
  git add -A && git commit -q -m "checkpoint $1"
  python3 "$G/audit.py" "$PWD" "$1" | grep -E "FAIL" | grep -v "^IP" && { echo "resume: stop, audit FAIL"; exit 1; }
  echo "resume: $1 DONE, verify PASS, audit recorded"
}
echo "== M8-T07 amendment"
deleg "Owner: the 4 % best-lap criterion stays. Your measurements check out (only maxSpeed moves a lap; racers.test.js:55-57 and menu.test.js:55-66 pin the approved numbers). Approved retune, a changed owner decision 5, with one change from your proposal: Hyguana maxSpeed 22 -> 20.2, and Pip maxSpeed 19 -> 19.3 (your safer variant: rivalJumps.test.js:111-119 keeps a 0.095 m/s margin; you measured Ember 2.73 % / Lantern 3.65 %). Do NOT loosen the pins to 'highest': update them to the new exact numbers, so they stay as strict. racers.test.js:55-57 expects 20.2 (|top - 20.2| <= 0.01) and still asserts it is above every other racer; menu.test.js keeps its five claim asserts, and Cinder's bars become exact: speed 7/9 ((20-19.3)/(20.2-19.3)), accel and handling still 1/3, each within 1e-9, with the test name updated. Add both test files to the pack's Files, update PLAN decision 6 and the roster table to 20.2 and 19.3, and record this as owner-approved in the pack, the journal and the event log. Then build, run balance.test.js, rivalJumps.test.js and the full checks, and mark M8-T07 DONE with the final spread table. End with the HANDOFF block." --session ses_e8d424ebcffeb5hKgcE6xE6Y15
echo "$out" | head -10
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "resume: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
finish M8-T07
echo "== M8-T08 resume"
deleg "Owner: M8-T07 is DONE and committed with the approved retune (Hyguana 20.2, Pip 19.3); npm test is green again. Your block is cleared: continue M8-T08 from your pack (frame-rate evidence with four models), then end with the HANDOFF block." --session ses_e8d2506e7ffeFXG1zxtfbcP8na
echo "$out" | head -10
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "resume: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
finish M8-T08
echo "resume: end"
