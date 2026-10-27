#!/usr/bin/env bash
# M10-T03 resume: DeepSeek stopped at 05:31Z on the OpenRouter key's credit cap (HTTP 402), not a rate limit; the
# old run then retried every 15 min. Sol's Plus limit (hit 03:33Z) resets at 08:33Z, so wait, switch back, continue.
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
game=/home/edwinidrus/hobbys/dragonhoard_test
cd "$game"
eval "$(sed -n '/^PRIMARY=/,/^}$/p' "$G/loop.sh")"
eval "$(grep '^quiet()' "$G/loop.sh")"
until [ "$(date +%s)" -ge "$(date -d '2026-10-26 08:36Z' +%s)" ]; do sleep 30; done
set_builder "$PRIMARY"; rm -f "$G/runs/.builder-fallback-since"
python3 "$cli" log - option.chosen "OpenRouter key credit cap reached (402) during M10-T03; builder back to $PRIMARY after its 5 h reset (setup sol-plus+ds)" >/dev/null
echo "t03: builder back to $PRIMARY at $(date -u +%H:%MZ)"
out=$(python3 "$cli" delegate "The builder model changed: the previous model stopped on a provider credit error partway through M10-T03. Check the working tree and the M10-T03 journal, then continue M10-T03 where it stopped, keeping the judge verdict, the owner's pick (a) and all six warnings above. End with the HANDOFF block." --session ses_e89725e65ffeaY3gCYBWVK6Jj0 --quota-patience 3600)
echo "$out" | sed -n '1,12p'
[ "$(echo "$out" | sed -n 's/^status: *//p' | tail -1)" = DONE ] || { echo "t03: stop"; echo "$out" | sed -n '2,40p'; exit 1; }
quiet; v=$(python3 "$cli" verify M10-T03); rc=$?; echo "$v" | grep -E "^FAIL|^verify:"
[ $rc -eq 0 ] || { echo "t03: verify FAIL (check alone for load flake before acting)"; exit 1; }
echo "t03: M10-T03 verify PASS (not committed; the judge views the evidence first)"
