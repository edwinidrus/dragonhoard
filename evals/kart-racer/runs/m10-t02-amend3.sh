#!/usr/bin/env bash
# M10-T02 BLOCKED a third time (247/300): the cost table shows any per-pixel sky costs ~100 frames. Judge revises the
# technique to a per-vertex gradient with the same palette and visual standards; shadows stay real; thresholds unchanged.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
eval "$(grep '^quiet()' "$G/loop.sh")"              # quiet(): wait for port 5173
deleg "Judge (external, Opus): the anti-sun view now shows a single rose band over the blue-grey shadow (fixed), and m10-shadow-close.png shows soft, readable kart shadows. Your cost table decides the next step: a plain background gives 355 frames against 255 with the cube, and A, B and C each move it by 6 or fewer. The cost is per-pixel sky work, which the first judging could not see (the spikes did not measure production FPS). The judge therefore revises the technique, not the look: evaluate the same palette and the same colour function per vertex instead of per pixel. All the visual standards from the judge's review still apply: a large, about 2-degree sun disc at SUN_DIRECTION, faint scattered stars only above 45 degrees, and a single rose band over the blue-grey anti-sun shadow.

Owner: a third bounded amendment inside M10-T02. It replaces the cube bake. The 300-frame floor and the 0.90 ratio stay unchanged.
1) Sky: a camera-centred dome whose colour is computed per vertex, either in the vertex shader of a ShaderMaterial or as vertex colours on a MeshBasicMaterial. Take whichever measures cheaper. Use enough rings near the horizon that the belt shows no facets. The fragment stage only outputs the interpolated colour. Draw the sun as its own small disc mesh at SUN_DIRECTION, with a soft edge made from geometry or vertex alpha, never a texture. Draw the stars as one Points object at seeded random directions above 45 degrees, faint and static. Keep fog off on all three, and remove the cube target and its bake. Keep the palette, the sun vector and the anti-sun values as the pure, unit-tested source.
2) Shadows: keep the current real shadows (512 Basic; karts cast; karts and the road receive). Only if the full npm run smoke still misses 300: add B and C from the second amendment, and then, only if it still misses, use D. If D misses too, stop BLOCKED with the numbers.
3) Still not approved: any render-scale, pixel-ratio, antialias or tone-mapping change.
4) Evidence: rerun your production-build check and save the four sky views, the nine fixed spots and the close shadow view. Add the new row to the M10 cost table. The external judge views the screenshots.
Log one shape.adjusted event, keep M10-T02 IN_PROGRESS while you work, and end with the HANDOFF block. Leave both spike worktrees alone." --session ses_e8a2801faffedGL0BTFADtFXPx
echo "$out" | sed -n '1,10p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "amend3: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T02); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"; [ $rc -eq 0 ] || { echo "amend3: stop, verify failed"; exit 1; }
echo "amend3: M10-T02 verify PASS (not committed; judge views the evidence first)"
