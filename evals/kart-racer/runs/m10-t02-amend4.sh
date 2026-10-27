#!/usr/bin/env bash
# M10-T02 BLOCKED a fourth time (per-vertex dome 247-259/300; dome-free 355): visuals accepted; any full-screen WebGL draw costs ~95 frames,
# so the gradient moves behind a transparent canvas (CSS or a small 2D canvas). Thresholds unchanged.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
eval "$(grep '^quiet()' "$G/loop.sh")"              # quiet(): wait for port 5173
deleg "Judge (external, Opus): third-amendment visuals accepted. The anti-sun view shows one smooth rose band over the blue-grey lower sky with no facets, the start view shows a large soft-edged sun with a warm halo, and the kart shadows are readable. This per-vertex look is now the reference look. Your ladder shows that a full-screen WebGL draw costs about 95 frames however trivial its fragment work is (dome-free 355 against 259-265). In the headless software renderer, every covered pixel of a draw is paid for, while a clear is nearly free.

Owner: a fourth bounded amendment inside M10-T02. The 300-frame floor and the 0.90 ratio stay unchanged.
1) Move the sky gradient out of WebGL. The race canvas becomes transparent where nothing is drawn (renderer alpha with a transparent clear), and the gradient is drawn behind it, so WebGL pays only a clear. The gradient must match the accepted reference look and follow the camera each frame (the horizon height from the camera pitch, and the sun-side to anti-sun blend from the camera yaw), all from the same pure, unit-tested colour function. Measure both forms:
   E1. CSS: a backdrop element behind the canvas, with layered CSS gradients driven by custom properties that are set each frame, and only when the camera has moved by more than a small step.
   E2. A small 2D canvas (around 160x90; measure the size) filled each frame from the pure colour function and CSS-scaled to full screen with smooth filtering. It is a 2D context, so the race keeps exactly one WebGL context.
   The sun disc and the stars stay in WebGL as small meshes, and the fog colour on Lantern stays the horizon colour. Take whichever of E1 and E2 reaches the floor with more headroom while matching the reference look.
2) For diagnosis only, not for delivery: measure the per-vertex dome with antialias off, so the M10 cost table records the size of that lever for later tasks.
3) Shadows: the real 512 Basic shadows stay, as accepted. Use B, B+C, and then D, in that order, only if the full npm run smoke still misses 300 with E.
4) Still not approved: any render-scale, pixel-ratio, antialias or tone-mapping change in the delivered build. If E with D also misses the floor, stop BLOCKED with the numbers.
5) Evidence: rerun your production-build check and save the four sky views, the nine fixed spots and the close shadow view, all as page screenshots that include the backdrop. Add the rows to the M10 cost table. The external judge views the screenshots.
Log one shape.adjusted event, keep M10-T02 IN_PROGRESS while you work, and end with the HANDOFF block. Leave both spike worktrees alone." --session ses_e8a2801faffedGL0BTFADtFXPx
echo "$out" | sed -n '1,10p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "amend4: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T02); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"; [ $rc -eq 0 ] || { echo "amend4: stop, verify failed"; exit 1; }
echo "amend4: M10-T02 verify PASS (not committed; judge views the evidence first)"
