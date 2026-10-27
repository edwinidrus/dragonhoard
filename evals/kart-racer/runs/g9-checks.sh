#!/usr/bin/env bash
# G9 auditor checks: the gate commands, the REA pass, then the kit drivers on both tracks for every racer.
set -uo pipefail
G=/home/edwinidrus/hobbys/dragonhoard_planing/evals/kart-racer
game=/home/edwinidrus/hobbys/dragonhoard_test
out=$G/gates/G9${SUB:+/$SUB}   # SUB=after-fixes keeps the first run
mkdir -p "$out"
D=/home/edwinidrus/hoard-play
cd "$game"
echo "== head $(git log -1 --oneline)"
echo "== npm test"; npm test 2>&1 | grep -E "^# (tests|pass|fail)"
echo "== npm run smoke"; npm run smoke 2>&1 | grep -E "passed|failed|flaky" | tail -3
echo "== build"; npx vite build --outDir "$D" --emptyOutDir 2>&1 | tail -2
echo "== budget"; node -e 'const fs=require("fs"),p=require("path"),z=require("zlib");const w=d=>fs.readdirSync(d,{withFileTypes:true}).flatMap(e=>e.isDirectory()?w(p.join(d,e.name)):[p.join(d,e.name)]);const f=w(process.argv[1]).sort().map(x=>({file:p.relative(process.argv[1],x),gzip:z.gzipSync(fs.readFileSync(x),{level:9}).length}));const t=f.reduce((n,x)=>n+x.gzip,0);console.log(JSON.stringify({files:f,total:t,baseline:144068,delta:t-144068,pass:t-144068<30000}))' "$D" | tee "$out/budget.json"
echo "$(git log -1 --format=%h) M9 music and sound (G9 candidate)" > "$D/BUILD.txt"
cd "$G/../.."
echo "== REA"; python3 "$G/gate.py" "$D" "$out" --static --wait-ms 4500 2>&1 | tail -8
cd "$G"
echo "== race ember"; FULL=1 timeout 600 node lap.mjs "$D" "$game" 3 400 > "$out/race-ember.json"; cut -c1-400 "$out/race-ember.json"
echo "== race lantern"; TRACK=lantern TRACE=1 FULL=1 SHOTDIR="$out" timeout 600 node lap.mjs "$D" "$game" 3 400 > "$out/race-lantern.json"; cut -c1-400 "$out/race-lantern.json"
for r in hyguana pip wren; do for t in ember lantern; do echo "== race $t $r"; RACER=$r TRACK=$t FULL=1 timeout 600 node lap.mjs "$D" "$game" 3 400 > "$out/race-$t-$r.json"; cut -c1-300 "$out/race-$t-$r.json"; done; done
echo "== falls"; for t in lantern ember; do timeout 300 node fallcheck.mjs "$game" $t > "$out/fall-$t.json"; cut -c1-300 "$out/fall-$t.json"; done
echo "== collision"; timeout 300 node collcheck.mjs "$game" 120 > "$out/collision.json"; cat "$out/collision.json"
for i in 1 2 3 4; do echo "== ember item $i"; EMBER=1 timeout 300 node lap.mjs "$D" "$game" 1 150 > "$out/ember-$i.json"; python3 -c "import json; d=json.load(open('$out/ember-$i.json')); print(json.dumps(d.get('ember'))[:400], d['pageErrors'])"; done
echo "== g9 checks end"
