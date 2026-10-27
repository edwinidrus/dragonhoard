#!/usr/bin/env bash
# G9 review fixes: owner-proxy approval of the six packs, then the loop runs M9-T06..T11.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
here=$G; game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"   # deleg(): Sol with the DeepSeek fallback
deleg "Owner: 1) yes, approve the six packs M9-T06..T11 in order T06 -> T11. 2) yes, split (d) into T09 (theme-scoped clearing) and T10 (airborne screech). 3) yes, T06 may add the two controller checks to test/logic/themes.test.js. 4) yes, LOOK_AHEAD 0.3 s; the gap-threshold alternative is rejected, because a caught-up gap would start all its notes at once after T07 (a burst). Add one condition to T08: its test also shows that M and a theme change still cancel every queued note inside the longer 0.3 s window (art. 5, no late note after mute). 5) yes, T11 may strengthen the cowbell assertion in test/logic/sfx.test.js:288-326. Log one shape.adjusted event and stop; don't start a task." --session ses_e8ae71acdffeXVs2f8Zsqo1LQ8
echo "$out" | sed -n '1,8p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "fixes: stop, approval not DONE"; echo "$out" | sed -n '2,40p'; exit 1; }
git add -A && git commit -q -m "checkpoint G9 review fix tasks M9-T06..T11 approved"
bash "$G/loop.sh" 6
echo "exit $?"
