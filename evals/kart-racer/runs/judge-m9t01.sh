#!/usr/bin/env bash
# M9-T01 judge verdict + owner-proxy pick (a), then verify/commit/audit T01 and loop T02..T05.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
deleg "Judge verdict (external judge, Opus), then the owner's pick.

Choice: the M9 audio engine behind the pure sequencer.
| Option | Verdict | Evidence verified | Cost | Risk |
| (a) native hand-written Web Audio | WORKS | re-ran spike-check.mjs: PASS, total 145899, delta 1831 < 30000, 0 contexts before the key, 1 after, 0 errors | no dependency, fits the pack's files (sequencer.js, engine.js, sequencer.test.js) | natural-completion cleanup not stress-tested; one-second noise loop; single echo tap |
| (b) ZzFX generator + native graph | WORKS | report read: delta 2274, npm test 312/312 | needs a vendored file and licence, so a scope amendment; it supplies no scheduling | synchronous PCM allocation per note, no cache; seam clicks on pitch glides |
| (c) Tone.js 15.1.22 | FAILS | re-ran: BUDGET FAIL, delta 50915 >= 30000 | 26 packages, manifest edits | disqualified by the budget |
Recommendation: (a). It is the smallest by far, adds no dependency or scope amendment, and is fully testable in Node through the fake context.
Warnings:
1. The spike's KeyN handler in main.js is spike-only. The pack forbids entry-point edits in T01; wiring belongs to T02.
2. Add a test that finished voices are released (onended), so the live-node count returns to zero after many scheduled notes and after clear/dispose. Hidden-tab recovery depends on it.
3. Keep the timer and clock out of the sequencer (M9 art. 3). The fake context in Node tests must be labelled fake, as in the spike.

Owner: (a). Build M9-T01 with (a) from the Build step, test first. Leave the three spike worktrees in /tmp/opencode alone (the auditor removes them). Delete the untracked dist/ folder in this checkout before the handoff; it is build output, not a deliverable. Record the pick and the 3 warnings in the journal. End with the HANDOFF block." --session ses_e8baafb8dffeyrqj15Sv8ILuGx
echo "$out" | sed -n '1,10p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "resume: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
v=$(python3 "$cli" verify M9-T01); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"; [ $rc -eq 0 ] || { echo "resume: stop, verify failed"; exit 1; }
git add -A && git commit -q -m "checkpoint M9-T01"
python3 "$G/audit.py" "$PWD" M9-T01 | grep -E "FAIL" | grep -v "^IP" && { echo "resume: stop, audit FAIL"; exit 1; }
echo "resume: M9-T01 DONE"
bash "$G/loop.sh" 4
