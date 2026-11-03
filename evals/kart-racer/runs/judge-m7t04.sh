#!/usr/bin/env bash
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
cd /home/edwinidrus/hobbys/dragonhoard_test
out=$(python3 "$cli" delegate "Judge verdict (external judge, Opus), then the owner's pick.

Choice: how Lantern Reach declares its jump gaps and rail-less bridge so createTrack resolves exact s ranges, with Ember unchanged.
| Option | Verdict | Evidence verified | Cost | Risk |
| (a) per-piece flags | WORKS | re-ran: probe 8 pass / 0 fail, npm test 195/195, probe byte-identical to b | 66 ins / 3 del, 13 -> 19 pieces, 3 frozen solved lengths (40.0442571243573, 44.3584224185869, 65.6415775814131) | a corner edit silently moves the gaps, because the remaining null straight absorbs it; a jump can't sit on a solved straight |
| (b) lap-fraction ranges like pads | WORKS | re-ran: probe 8 pass / 0 fail, npm test 195/195; Lantern resolves jumps [50,60] minSpeed 14 and [370,380] minSpeed 12, bridge [560,590]; Ember resolves [] and [] | 41 ins / 0 del, 7 data lines, no piece touched | fractions must be recomputed if geometry changes; that's the same convention pads, checkpoints and grid already use, and the metre assertions catch drift |
Recommendation: (b) — smaller, no derived magic numbers, it matches the existing pad convention, and it can place a gap on a solved straight.
Warnings:
1. Keep the metre-level assertions (with a tolerance, since 0.045082*L gives 50.000125) in the real trackFeatures.test.js, so a later geometry change fails a test instead of moving a gap silently.
2. Jump 2 (minSpeed 12) has no pad 10-30 m before it. The spikes skipped the main-control check. M7-T05/T06 must prove that a kart at normal top speed out of the preceding corner clears jump 2 and a slow kart falls; record the speeds.
3. Ranges must not wrap past the lap line; keep the 'past the track length' guard.

Owner: (b). Build M7-T04 with (b) from the Build step, test first. Then remove both spike worktrees and their branches (git worktree remove --force <path>; git branch -D spike/t04-a spike/t04-b) and delete the untracked .probe/ folder, which is not part of the deliverable. Record the pick and the 3 warnings in the journal. End with the HANDOFF block." --session ses_e96421b4bffen0oqvfsAI42EJo)
echo "$out" | head -10
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "resume: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
v=$(python3 "$cli" verify M7-T04); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"; [ $rc -eq 0 ] || { echo "resume: stop, verify failed"; exit 1; }
git add -A && git commit -q -m "checkpoint M7-T04"
python3 "$G/audit.py" "$PWD" M7-T04 | grep -E "FAIL" && { echo "resume: stop, audit FAIL"; exit 1; }
echo "resume: M7-T04 DONE, verify PASS, audit PASS"
bash "$G/loop.sh" 7
