#!/usr/bin/env bash
# M10-T02 amendment 4 passed the floor (350) but the judge rejects the CSS backdrop's look (named defects); fix E1 or use E3, a precomputed panorama copied per frame.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
eval "$(grep '^quiet()' "$G/loop.sh")"              # quiet(): wait for port 5173
deleg "Judge (external, Opus): rejected. The fourth-amendment backdrop passes the floor but does not match the accepted reference look (the third-amendment per-vertex screenshots). The judge viewed the archived page screenshots in /tmp/opencode/m10-t02-fourth-final-evidence/production/ and names four defects:
1. m10-start.png, the race camera: the whole sky is a flat dark violet, with only the WebGL sun halo. The reference had a gold/orange horizon, rose, purple, then violet at the zenith.
2. m10-hairpin.png: the gradient shows as a floating band, boxed in by flat zenith-violet areas on the left and at the top, with a visible soft-edged rectangle. The layers do not cover the view as the colour function does.
3. lantern-anti-sun.png: below the horizon is a flat tan. The reference showed blue-grey below the rose band on the anti-sun side.
4. m10-ember-start.png: the day sky is a flat, medium, saturated blue, about (74,120,200), not DAY_SKY 0x8fc7e8 and the day gradient. This looks like linear working-space values written to CSS without sRGB conversion (for example r,g,b used directly, where getHexString or getStyle with the sRGB colour space is needed).
The look criterion is the colour function itself, as the per-vertex dome showed it, viewed from every fixed spot and every sky pose.

Owner: a fifth bounded amendment inside M10-T02. The 300-frame floor and the 0.90 ratio stay unchanged.
1) Either fix E1 so that all four defects are gone, or build E3: once per setSky, compute the colour function into an offscreen 2D canvas panorama covering 360 degrees of yaw by the needed pitch range (measure the size, for example 1024x256). Then, each frame the camera rotation moves, copy only the visible slice with drawImage into the small visible backdrop canvas, which CSS scales to full screen. That gives exact colours with no per-pixel work per frame, and the race keeps exactly one WebGL context. Take whichever matches the reference look at every fixed spot and sky pose and keeps the floor in both the full npm run smoke and your chase-camera yaw sweep.
2) Add a Node test that compares the backdrop's colours with the pure colour function at sample directions, including Ember and the sRGB output, so defect 4 cannot come back.
3) Still not approved: any render-scale, pixel-ratio, antialias or tone-mapping change in the delivered build (the antialias-off diagnostic of +182 stays recorded only). The shadow ladder B, B+C, D applies only if the floor is missed.
4) Evidence: rerun the production-build check and save the four sky views, the nine fixed spots and the close shadow view, as page screenshots, into a folder that Playwright does not wipe. Add the rows to the M10 cost table. The external judge views them.
Log one shape.adjusted event, set M10-T02 to IN_PROGRESS while you work, and end with the HANDOFF block. Leave both spike worktrees alone." --session ses_e8a2801faffedGL0BTFADtFXPx
echo "$out" | sed -n '1,10p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "amend5: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T02); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"; [ $rc -eq 0 ] || { echo "amend5: stop, verify failed"; exit 1; }
echo "amend5: M10-T02 verify PASS (not committed; judge views the evidence first)"
