#!/usr/bin/env bash
# M10-T02 BLOCKED on the 300-frame floor (175): owner-proxy approves the smallest render-only amendment
# (bake the picked shader dome into a cube background, tune the shadow map from its start value), thresholds unchanged.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
eval "$(grep '^quiet()' "$G/loop.sh")"              # quiet(): wait for port 5173
deleg "Owner: approve a bounded render-performance amendment inside M10-T02. The 300-frame floor and the 0.90 ratio stay unchanged. Your diagnostics put most of the cost in the dome's per-pixel maths, which runs every frame, and the rest in the shadow pass.
1) Sky: keep option (a), the same gradient shader, but evaluate it once per setSky instead of every frame. Render the dome material once into a scene-owned cube render target (a CubeCamera), at a face size you measure (start at 512 and go up only if the sun disc or the stars break up), and show it as scene.background. Reuse that one target across tracks and dispose of it with the scene. This is generated in code at runtime, with no image or texture file. Drop the star twinkle (the seconds uniform and updateSky): I-4 asks for faint static stars only. The per-frame dome mesh goes away.
2) Shadows: mapSize 2048 is the reference's start value, not a requirement. Measure 1024 and 512 with the tight player-following frustum, and BasicShadowMap against PCF. Keep the smallest map that still shows a clean kart shadow on the road. Only karts cast shadows; karts and the road receive them, as now.
3) Not approved: any render-scale, pixel-ratio, antialias or tone-mapping change. If 1 and 2 together still miss the floor, stop BLOCKED again with the measured numbers.
4) Evidence: rerun your production-build check and save the four sky views plus the nine fixed spots; the external judge views them. The sun disc, the stars above 45 degrees and the rose band over the blue-grey anti-sun shadow must still show.
Set M10-T02 back to IN_PROGRESS, log one shape.adjusted event for the amendment, build it test first, run the full checks, and end with the HANDOFF block. Leave both spike worktrees alone." --session ses_e8a2801faffedGL0BTFADtFXPx
echo "$out" | sed -n '1,10p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "amend: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T02); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"; [ $rc -eq 0 ] || { echo "amend: stop, verify failed"; exit 1; }
git add -A && git commit -q -m "checkpoint M10-T02"
python3 "$G/audit.py" "$PWD" M10-T02 | grep -E "FAIL" | grep -v "^IP" && { echo "amend: stop, audit FAIL"; exit 1; }
echo "amend: M10-T02 DONE"
