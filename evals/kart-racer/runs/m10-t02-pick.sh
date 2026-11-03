#!/usr/bin/env bash
# M10-T02 judge verdict + owner-proxy pick (a) shader dome, then verify/commit/audit T02 and loop T03 (stops with JUDGE for the clouds pick).
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
eval "$(grep '^quiet()' "$G/loop.sh")"              # quiet(): wait for port 5173
deleg "Judge verdict (external judge, Opus), then the owner's pick.

Choice: the M10 sky dome (open option 4, sky half).
| Option | Verdict | Evidence verified | Cost | Risk |
| (a) ShaderMaterial gradient dome | WORKS | the judge viewed all four standardized PNGs and read sky.js and the scene.js diff: smooth gold, orange, rose, purple, violet gradient; a large sun disc (about 2 degrees) at 4.5 degrees elevation; scattered faint stars only high up; the anti-sun view shows a rose band over blue-grey shadow, as the reference describes; the dome follows the camera at render time | 1 draw, 561 vertices, +926 B gzip | star hash has an azimuth seam and denser cells near the zenith |
| (b) vertex-coloured sphere | WORKS, weaker | the judge viewed the same four PNGs: the sun disc is small; the stars sit on a visibly regular lattice; the anti-sun view keeps an orange horizon with a grey smudge across it, so it does not read as dusk shadow | 1-3 draws, 12513 vertices, +1927 B gzip | tessellation cost, interpolation artefacts |
Recommendation: (a). It reads closer to I-4 in every view, at half the gzip cost, a third of the draws and a twentieth of the geometry.
Warnings:
1. One sun vector: move the sun direction out of the GLSL literal into a uniform fed from one exported constant, and aim the directional light from the same constant (T03's warm cloud side will reuse it), so the disc and the light can never disagree. Assert its 3-6 degree elevation and the 45-degree star cutoff in test/logic/sky.test.js on pure values, with no WebGL in Node.
2. The dome belongs to the shared scene: create it once in createScene, never per race, and keep it out of the per-race scenery groups that the race-exit dispose checks cover. Keep fog off on the dome. On Lantern the fog colour is the dome's horizon colour, and the fog distances keep the next corner visible (G10 criterion).
3. Keep scene.test.js and mainWiring.test.js byte-identical: setSky still sets scene.background and also sets the dusk uniform.
4. Star density and the seam stay tuning values for the owner at G10; no texture in any case.

Owner: (a). Build M10-T02 with (a) from the Verify step, test first. Leave both spike worktrees alone: the auditor archived their evidence and removes them. Record the pick and the four warnings in the journal. End with the HANDOFF block." --session ses_e8a2801faffedGL0BTFADtFXPx
echo "$out" | sed -n '1,10p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "pick: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T02); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"; [ $rc -eq 0 ] || { echo "pick: stop, verify failed"; exit 1; }
git add -A && git commit -q -m "checkpoint M10-T02"
python3 "$G/audit.py" "$PWD" M10-T02 | grep -E "FAIL" | grep -v "^IP" && { echo "pick: stop, audit FAIL"; exit 1; }
echo "pick: M10-T02 DONE"
bash "$G/loop.sh" 1
echo "exit $?"
