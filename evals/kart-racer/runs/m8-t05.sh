#!/usr/bin/env bash
# M8-T05 after the JUDGE stop: judge pick (a), then the loop for T05 only (the racer name is pending the owner).
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
cli=/home/edwinidrus/hobbys/dragonhoard_trial_plugin_b/scripts/dragonhoard.py
cd /home/edwinidrus/hobbys/dragonhoard_test
echo "== M8-T05 judge"
python3 "$cli" delegate "Judge (external, Opus) and owner: (1) pick (a): bake each racer model once into a 128x128 image with one throwaway WebGLRenderer at menu build, then dispose it. It shows the real model, adds no lasting WebGL context (it stays at 1 once the menu is built once, as the pack requires), and is the smallest diff that meets the gate's 'model' wording. (b) holds 5 live contexts that are never disposed; (c) shows no model. Acceptance: the context count after three menu visits equals the count after one. (2) No Dingodile wording pass: the fault-F6 rename broke the plan's Distinctness rule and is reverted (commit 362e68e). The roster is Hyguana again, green 0x2f9e44, id hyguana; your journal note 1 no longer applies, so correct it in the journal. (3) Keep the three spike worktrees until G8, unmerged. Record the pick as option.chosen, then stop with the HANDOFF block; the build runs in a new session." --session ses_e900011f5ffelVUF5TrOVGrDJi | sed -n '1,12p'
echo "== M8 loop T05"
bash "$G/loop.sh" 1
