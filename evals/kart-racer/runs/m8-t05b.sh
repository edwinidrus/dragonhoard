#!/usr/bin/env bash
# M8-T05 after the restart-guard BLOCKED stop: amendment (a), stricter, then T06-T08.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
cd /home/edwinidrus/hobbys/dragonhoard_test
echo "== M8-T05 amendment"
out=$(python3 "$cli" delegate "Owner: amendment (a) approved, made stricter. Checked: mainWiring.test.js:31 pins restart() to createRace(track) and main.js:114 matches it, so (b) would lose the racer pick on every restart. Add test/logic/mainWiring.test.js to the pack's Files and change only that regex so it REQUIRES the racer: createRace\\s*\\(\\s*track\\s*,\\s*\\{\\s*racer\\s*:\\s*racerId\\s*\\}\\s*\\) in place of createRace\\s*\\(\\s*track\\s*\\), with no optional group. The guard then still proves restart builds a fresh race from the same track, and also that it keeps the racer. restart() passes { racer: racerId } and rebuilds meshes from the new flow. Record the amendment as owner-approved in the pack, the journal and the event log, then build, test and mark M8-T05 DONE. End with the HANDOFF block." --session ses_e8df0dce6ffeA0CwlWF8VONNtj)
echo "$out" | head -10
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "resume: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
v=$(python3 "$cli" verify M8-T05); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"; [ $rc -eq 0 ] || { echo "resume: stop, verify failed"; echo "$v" | head -20; exit 1; }
git add -A && git commit -q -m "checkpoint M8-T05"
python3 "$G/audit.py" "$PWD" M8-T05 | grep -E "FAIL" && { echo "resume: stop, audit FAIL"; exit 1; }
echo "resume: M8-T05 DONE, verify PASS, audit PASS"
echo "== M8 loop T06-T08"
bash "$G/loop.sh" 3
