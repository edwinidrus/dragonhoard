#!/usr/bin/env bash
# G10 owner-override pass recorded by the builder (Sol), then a local commit on m10-finish (the owner pushes later).
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
out=$(python3 "$cli" delegate --quota-patience 172800 "Owner: G10 passed on the owner's override (2026-10-27); record it, do not build anything. Evidence from the external judge on e67d23d (runs/g10-checks.sh, files in the eval kit's gates/G10/): npm test 467/467; npm run smoke 34 passed and 1 failed, the four-model frame floor, which this host misses with T08 and T09 alike (judge A/B: T08 127/132/120, T09 125/139/138 four-model frames) — criterion 4 is NOT met and is accepted only by the owner's override, the 300 floor and 0.90 ratio unchanged; REA page-errors, console-errors and missing-files PASS, 8 distinct frames; no image file under src/ or public/ and 0 image requests; git diff --stat e3ce140 -- src/logic empty; gzip CLI -9 total 171,459 bytes, +22,839 against T01's 148,620; draw calls per fixed spot from dist/m10-t09/production/evidence.json at most 97 (start), with repeated scenery merged or instanced; one live WebGL context and every generated texture and buffer released (T09 lifetime evidence); all four racers finish 3 laps on both tracks; falls pass on both tracks; collisions identical to G9 (414 contact pair-steps, min gap 1.391 m). The kit autopilot drifted past the half-width on Lantern for 3 of 4 racers (max lateral 6.3-7.6 m against 6) and the Ember item hit 0 of 4: the autopilot polled about 8 times a second on this slow host against 12.5 at G9, and src/logic is unchanged, so these are driver noise, recorded, not game changes. The external judge viewed the T04-T09 production screenshots (criteria 1, 2, 7 by owner-proxy; halo and glint feel owner-unverified). Criterion 3's byte-identical-tests wording has one owner-approved exception: the final test of test/logic/roadIslands.test.js (M10-T09 amendment, hash kept, assertions 13 to 25). The judge's G10 code review found 0 bugs, 3 risks and 1 question, no fix task. Record G10 as PASSED (owner override) in GATE.md (tick each criterion with its evidence, mark criterion 4 as not met and accepted on override), in STATUS's Gates row and in the event log with that note, run digest and check, and end with the HANDOFF block. Do not commit.")
echo "$out" | sed -n '1,10p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "g10: stop, record not DONE"; exit 1; }
pat=$(cd "$G" && python3 -c "import audit; print(audit.IP_TERMS.pattern)")
hits=$(git grep --untracked -nIiE "$pat" -- . ':!node_modules' ':!dist' ':!implementation/logs' ':!implementation/DIGEST.md' ':!*.journal.md')
[ -z "$hits" ] || { echo "g10: IP hits, not committed"; echo "$hits" | head -5; exit 1; }
[ "$(git branch --show-current)" = m10-finish ] || { echo "g10: not on m10-finish"; exit 1; }
git add -A && git commit -q -m "checkpoint G10 passed" -m "Gate G10 (Lantern Reach in full) passed on the owner's override: the four-model frame floor is not met on this host (threshold unchanged); every other criterion is backed by evidence.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019THy46FswbovBCP9Ud54HK" && git log --oneline -3
python3 "$cli" check; python3 "$cli" next
