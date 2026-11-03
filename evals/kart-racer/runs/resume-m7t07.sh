#!/usr/bin/env bash
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
cd /home/edwinidrus/hobbys/dragonhoard_test
out=$(python3 "$cli" delegate "Owner: amendment (a) approved. Your root cause checks out: both gaps sit on straights where the corner limit is Infinity, take-off speeds run 16.74-18.93 m/s against minSpeed 14/12, and the floor changed 0 control steps on either track. Make M7-T07 test-only: no change to src/logic/rival.js or race.js, and no bridge lane bias. Replace acceptance 5 with exactly: \"0 rival falls on Lantern in the full race; every take-off speed at or above minSpeed with its margin recorded; every rival airborne at least once; the direct-control assertions are kept as a regression guard.\" Drop Build step 3 (bridge lane bias) and note why: 0 falls and 0 rival wall contacts with containment skipped on the bridge. Record it as an owner-approved amendment in the pack, the journal and the event log. Write test/logic/rivalJumps.test.js test first, with each kart recorded at its own finishing step (L07). Add two known risks to the journal for G7 and M8, no code for them: (1) an ember-slowed rival (about 0.62 of its speed, about 11 m/s) is below both minSpeeds and will fall if it's hit just before a gap; (2) M8's per-racer stats must re-check take-off speeds against minSpeed. Then npm test and npm run smoke, mark M7-T07 DONE. End with the HANDOFF block." --session ses_e961988bfffeL5mNmN53LF75h0)
echo "$out" | head -10
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "resume: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
v=$(python3 "$cli" verify M7-T07); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"; [ $rc -eq 0 ] || { echo "resume: stop, verify failed"; exit 1; }
git add -A && git commit -q -m "checkpoint M7-T07"
python3 "$G/audit.py" "$PWD" M7-T07 | grep -E "FAIL" && { echo "resume: stop, audit FAIL"; exit 1; }
echo "resume: M7-T07 DONE, verify PASS, audit PASS"
bash "$G/loop.sh" 4
