#!/usr/bin/env bash
# M10-T02 BLOCKED again (251/300 after the cube bake): profile once, then adopt the highest-fidelity pre-approved shadow option that meets the unchanged floor.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
eval "$(grep '^quiet()' "$G/loop.sh")"              # quiet(): wait for port 5173
deleg "Judge (external, Opus) on your visual evidence: the 1024-face cube keeps the large sun and the gradient, and the 512 BasicShadowMap kart shadows are clean, with no acne. One defect: lantern-anti-sun.png shows a doubled rose band at the horizon, split by a thin blue-grey line, where the spike had a single rose band over the blue-grey shadow. Find the cause and fix it, test first where it can be tested in Node.

Owner: a second bounded amendment inside M10-T02. The 300-frame floor and the 0.90 ratio stay unchanged. Map size barely moved the count (512 Basic 252, 1024 Basic 248), so the remaining cost is not the map's resolution.
1) Profile first, in fixtures only, with the cube sky and 512 Basic, each in the same smoke-like four-model run: (i) as now; (ii) option A; (iii) A+B; (iv) A+B+C; (v) option D. For diagnosis only: (vi) no directional light at all, and (vii) a plain colour background instead of the cube. Record the frame table in the journal as the M10 cost table; later M10 tasks spend from it.
2) Pre-approved options, in order of fidelity:
   A. Remove the redundant per-frame CPU work: the extra scene.updateMatrixWorld before renderer.render, and the per-frame traverseVisible shadow-visibility walk (use the native shadow auto-update; a shadow pass on a sky-only review pose is harmless).
   B. Shadow-only casters: one merged low-poly caster per kart (body and wheels as a few boxes or one merged geometry), on a layer that only the shadow camera renders, so it adds no colour-pass draw. The visible kart parts stop casting. Karts and the road still receive.
   C. Only the road receives; karts stop receiving.
   D. Fallback only, as a scope note for the owner at G10: no shadow map. Instead, one code-generated soft contact shadow under each kart (a radial-gradient disc on the road, all four in one instanced mesh); the directional light still shades.
   Adopt the highest-fidelity option, or cumulative combination A, A+B, A+B+C, D, that reaches at least 300 frames in the full unchanged npm run smoke. Report every number.
3) Still not approved: any render-scale, pixel-ratio, antialias or tone-mapping change. If D also misses the floor, stop BLOCKED with the profile table.
4) Evidence: rerun your production-build check and save the four sky views, the nine fixed spots and one close shadow view. The external judge views them.
Log one shape.adjusted event, keep M10-T02 IN_PROGRESS while you work, and end with the HANDOFF block. Leave both spike worktrees alone." --session ses_e8a2801faffedGL0BTFADtFXPx
echo "$out" | sed -n '1,10p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "amend2: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T02); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"; [ $rc -eq 0 ] || { echo "amend2: stop, verify failed"; exit 1; }
echo "amend2: M10-T02 verify PASS (not committed; judge views the evidence first)"
