#!/usr/bin/env bash
# M10-T03 judge verdict + owner-proxy pick (a) instanced clusters with the sea painted by the backdrop; build, verify, no commit (the judge views first).
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
eval "$(grep '^quiet()' "$G/loop.sh")"              # quiet(): wait for port 5173
deleg "Judge verdict (external judge, Opus), then the owner's pick.

Choice: M10 clouds (open option 4, clouds half) and the far sea.
| Option | Verdict | Evidence verified | Frames (four-model, smoke-style) | Risk |
| (a) instanced low-poly clusters | WORKS | the judge viewed m10-start and m10-sea: the faceted puffs read as clouds and match the game's low-poly style | WebGL sea 229-235 (fails); backdrop sea 329 | in m10-sea one near puff fills about a third of the view and reads as a boulder |
| (b) billboard planes, soft texture | FAILS the look | the judge viewed the same views: the puffs render as glowing rings and bokeh orbs, not clouds (the ring/halo artefact in the criteria) | WebGL sea 234 (fails); backdrop sea 341 | the artefact is inherent to a soft alpha disc on a bright dusk horizon |
| sea as a WebGL mesh | FAILS the floor | both spikes | about 235 | a full-screen draw, as in the M10 cost table |
| sea painted by the T02 backdrop below the horizon | WORKS | both spikes | 329-341 | flat tonal bands in the spikes |
Recommendation: (a), with the far sea painted by the backdrop colour function below the horizon.
Warnings:
1. Sea look (your question 3: yes, it must be better than flat bands): in the pure colour function, below the horizon, make the sea brighter and warmer toward the sun's azimuth and cool and blue-grey toward the anti-sun side, with a few soft low-frequency billow bands from deterministic code noise. No texture. Unit-test in Node that at the same depression angle the sun side is warmer and brighter than the anti-sun side, and keep the existing sRGB comparison test.
2. Puffs: each puff is a cluster of 3-5 low-poly spheres, all instanced (one or two draws in all), in two drifting layers at two distances, as I-4 item 1 asks. Keep a minimum distance from the camera path and outside the road corridor, so that no puff covers more than about a tenth of the view from any fixed spot. The drift is render-loop only.
3. Budget: the unchanged full npm run smoke four-model sample must reach at least 300 frames with the ratio at least 0.90. If it misses, first reduce the puff count and then the sphere detail, and report each number.
4. Falls: the render-only sink stays as decided (owner decision 6). Save one screenshot of a falling kart dropping toward the sea, with no logic change.
5. Ember gets no clouds and no sea; only Lantern does.
6. Owner naming rule: the instanced spike's code and report used a 5-letter geometry word for its angle-and-radius grid that is on the owner's protected-name list. In code, comments, tests, journals and docs, call it a radial grid or a ring grid. Replace that word in the M10-T03 journal line where it already appears.

Owner: (a), with the backdrop-painted sea and the six warnings. Build M10-T03 from the Verify step, test first. Leave both cloud spike worktrees alone: the auditor archived their evidence and removes them. Save the production screenshots (nine fixed spots, m10-sea and the fall view) into a folder that Playwright does not wipe, and add the T03 row to the M10 cost table. End with the HANDOFF block." --session ses_e89725e65ffeaY3gCYBWVK6Jj0
echo "$out" | sed -n '1,12p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "t03: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T03); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"
[ $rc -eq 0 ] || { echo "t03: verify FAIL (check alone for load flake before acting)"; exit 1; }
echo "t03: M10-T03 verify PASS (not committed; the judge views the evidence first)"
