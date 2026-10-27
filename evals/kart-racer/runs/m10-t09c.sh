#!/usr/bin/env bash
# M10-T09 owner answer to the second BLOCKED stop (same session): bounded edit of one pinned test, then finish, verify, no commit (the judge views the screenshots and measures the
# frame rule by A/B on a quiet host first). Sol only (owner, 2026-10-26); a Plus limit is waited out (48 h patience).
# The trial was reopened by the owner on 2026-10-27 to finish T09 and G10; commits stay local until the owner pushes.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(grep '^quiet()' "$G/loop.sh")"
out=$(python3 "$cli" delegate --quota-patience 172800 --session ses_e81226a1cffeZ46J5wCbJC5WHl "Owner answer to your second M10-T09 BLOCKED (owner amendment by the external judge, 2026-10-27, rule: smallest amendment that keeps scope). Approved as you proposed, with these limits: (1) You may change only the final test in test/logic/roadIslands.test.js (the 'legacy static rocks and gold' test, lines 326-352); nothing else in that file or any other existing test. Record the file in the pack's amendment note and in the journal. (2) The test must stay at least as strict: assert exactly two opaque stock Lambert batches (the rock batch and the gold batch, by name) plus the one halo InstancedMesh with eight instances, additive blending and depthWrite false; the rock batch keeps emissive 0; the original 380-triangle count and the same SHA-256 constant 459532106a2c7538ae0e5c72d646b676f3a51c0c48d2176f829f698299e3eaf9 still hold over the rock and gold position/normal/colour stream reconstructed in the original order. Do not regenerate the hash, and do not reduce the number of assertions (verify counts them). (3) Node path: follow the generated-banner precedent in src/render/trackMesh.js (a guarded canvas, and material.addEventListener('dispose', () => texture.dispose()) for the halo texture). npm test must pass exactly as package.json runs it, with no --import adapter; a fake canvas may appear only inside a test file, labelled as such, the way roadDressing.test.js does. Then finish the task as the pack and my first note say: focused and full npm test, the unchanged smoke with all numbers recorded under the load exception, production evidence in dist/m10-t09/production/ and details/, the T09 cost row, records, digest and check. No commit. End with the HANDOFF block.")
echo "$out" | sed -n '1,14p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "t09c: stop"; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T09); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"
[ $rc -eq 0 ] || { echo "t09c: verify FAIL (smoke frame floor expected on a loaded host; the judge checks the rest)"; exit 1; }
echo "t09c: M10-T09 verify PASS (not committed; the judge views the evidence and measures A/B first)"
