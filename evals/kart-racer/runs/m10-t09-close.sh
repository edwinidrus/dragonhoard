#!/usr/bin/env bash
# M10-T09 close on the owner's override (2026-10-27): the builder records the judge verdict and marks DONE, then
# IP check, local checkpoint commit on branch m10-finish (pushed later by the owner), hidden audit with R1 limited
# to `npm test` (the smoke's frame floor is not met on this host; threshold unchanged), then the G10 checks.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
out=$(python3 "$cli" delegate --quota-patience 172800 --session ses_e81226a1cffeZ46J5wCbJC5WHl "External judge verdict for M10-T09, and an owner decision. Visuals accepted from dist/m10-t09/production/ and details/: road readable, T04's landmark island and T08's dragon unoccluded in both forward views, gold piles read gold, halos soft around the lanterns with no bloom; the halo is faint where the dusk sea behind a lantern is bright (feel owner-unverified). Judge A/B under equal load (runs/abba.sh, H = committed T08 c26806d in a worktree, W = your tree, order H W W H H W): H 127/132/120, W 125/139/138 four-model frames; median W 138 against H 127, so T09 costs nothing measurable; every run's only failure was the frame floor, except H run 5 (also the load-timing tests at smoke.spec.js:273 and :308). The host is too slow to meet the 300 floor with either tree. Owner decision (2026-10-27): accept M10-T09 on override without the frame acceptance, the same as M10-T08; the 300 floor and 0.90 ratio are not changed, and T09 is recorded as accepted on override, not as meeting them. Record the A/B numbers, the visual verdict and the override in the T09 journal (an '## Owner override' section with '- Ran:' and '- Outcome: DONE (owner override)') and in the T09 cost row, then mark M10-T09 DONE as the skill says (STATUS and PROGRESS rows with the override, a task.done event, digest, check). Leave G10 for the gate step. No code or test changes and no new smoke runs. Do not commit. End with the HANDOFF block.")
echo "$out" | sed -n '1,14p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "t09close: stop"; exit 1; }
npm test 2>&1 | grep -E "^# (tests|pass|fail)"
pat=$(cd "$G" && python3 -c "import audit; print(audit.IP_TERMS.pattern)")
hits=$(git grep --untracked -nIiE "$pat" -- . ':!node_modules' ':!dist' ':!implementation/logs' ':!implementation/DIGEST.md' ':!*.journal.md')
[ -z "$hits" ] || { echo "t09close: IP hits, not committed"; echo "$hits" | head -5; exit 1; }
[ "$(git branch --show-current)" = m10-finish ] || { echo "t09close: not on m10-finish"; exit 1; }
git add -A && git commit -q -m "checkpoint M10-T09" -m "Lantern halos and gold glints. Accepted on the owner's override without the frame acceptance (A/B: no measurable cost against T08; the host misses the 300 floor with either tree; threshold unchanged).

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019THy46FswbovBCP9Ud54HK" && git log --oneline -1
cd "$G" && python3 - <<'EOF'
# Owner override: R1 re-runs only `npm test`; the smoke's frame floor is not met on this host (threshold unchanged).
from pathlib import Path
import audit
orig = audit.dragonhoard.load_config
audit.dragonhoard.load_config = lambda p: {**orig(p), "checks": ["npm test"]}
game = Path("/home/edwinidrus/hobbys/dragonhoard_test")
r = audit.audit(game, "M10-T09", "HEAD~1")
audit.report(game, "M10-T09", "HEAD~1", r)
EOF
echo "t09close: M10-T09 committed locally; G10 checks next"
bash "$G/runs/g10-checks.sh"
