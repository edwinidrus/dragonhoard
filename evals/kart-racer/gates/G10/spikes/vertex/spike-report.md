Option: Vertex-coloured sphere sky dome; no custom gradient shader
Verdict: WORKS
Criterion: `node spike-check.mjs` -> `PASS` (exit 0; real built page, both tracks, consolePageErrors:0, runtimeImageRequests:0)
Exact recorded command: `set -o pipefail; node spike-check.mjs 2>&1 | tee evidence/criterion-output.txt`
Model: openai/gpt-6.1-sol#high
Baseline: clean HEAD23eeedc built before source edits; criterion rebuilds pinned clean scene and asserts original measurement reproduced.
CANONICAL gzip: execFileSync('gzip',['-9','-c'],{input:fileBytes}), each JS/HTML separately via stdin, no filename header; baseline JS148251 + HTML369 =148620 B (asserted).
CANONICAL variant: JS150176 + HTML371 =150547 B; delta +1927 B. NONCANONICAL Node zlib: baseline149246, variant151265, delta2019 B, retained only for provenance.
Standard dome-only draw calls: Lantern sun3, anti-sun2, zenith2, Ember day1 (all asserted >0 and <=3). Original poses:74/2/13/42 (all >0 and <=100).
Geometry: 128x96 sphere, 12513 vertices/24320 triangles; primitive sun48 triangles at +x4.5deg; one batch180 stars, elevations >45deg.
Built: src/render/sky.js — 67 lines new; MeshBasicMaterial(vertexColors:true), linear THREE.Color(hex), gradient/Belt of Venus, day toggle.
Built: src/render/scene.js — 76 lines total; +9/-1 lines, camera-centred radius450 before render, BackSide/depthWrite:false.
Built: spike-check.mjs — 118 lines, runnable build/canonical+Node gzip/strict-port/browser/PNG/assert criterion; implementation unchanged by normalization.
Built: spike-report.md — 24 lines; evidence/{baseline.json,result.json,criterion-output.txt,*-dist/,*.png}; dist/ production build; node_modules symlink.
Screenshots: evidence/lantern-sun-horizon.png; evidence/lantern-zenith-stars.png (camera y400 proves recentering).
Screenshots: evidence/lantern-anti-sun.png; evidence/ember-day.png; all PNG signatures checked, 1280x720, review poses via __hoard.view only.
Standard poses: position[0,400,0] throughout; sun target[100,407.87,0], anti[-100,407.87,0], zenith[1,500,0], Ember day[100,407.87,0].
Standard PNGs: evidence/{lantern-standard-sun-horizon,lantern-standard-anti-sun,lantern-standard-zenith-stars,ember-standard-day}.png (102256/148933/80731/22927 B).
Assertions: both track menu/start routes; zero console/page errors; zero image/texture-extension requests; 8 PNG signatures; draw bounds; BasicMaterial/vertexColors/BackSide/depthWrite/radius450/color attribute; sun3–6deg; every star >45deg; pinned background/helper and unchanged main/dependency manifests.
Visual-only: manually read standardized sun PNG: small pale disc visible on orange/gold field below rose/purple upper sky; no world geometry visible, HUD remains. Other standardized PNGs not manually inspected; colour accuracy, Belt aesthetics, star visibility and centring not pixel-asserted.
Cost: zero new dependencies; ~76 implementation lines; dome/sun/points =3 dusk draw objects,1 day object. Installed Three0.186.1/Vite8.3.4/Playwright1.64.1 reused.
Tradeoff: tessellation samples colour at 2.8125deg azimuth/1.875deg elevation, then linearly interpolates triangles; not continuous per-fragment gradient.
Tradeoff: lower tessellation would reduce vertex work but weaken narrow horizon/Belt transitions; no coarse-resolution or FPS comparison run, so no performance claim.
Risks: untextured square stars; subtle interpolation/8-bit banding possible. Narrow angular features require enough tessellation; sun costs extra primitive draw.
Risks: original calls include moving world geometry; standardized calls isolate sky objects, including points draw even when stars clip outside view. Existing >500kB Vite warning remains; no screenshot pixel-diff/FPS/full-suite run.
Scope: DOME ONLY; no shadows/fog/lighting/ground removal, no assets/addons/toneMapping/logic/audio edits; existing green ground remains visibly unrelated to new sky.
Preserved: DAY_SKY/DUSK_SKY/skyColor, pinned setSky(track) call/background assignment, createScene calls/pose. Strict5182 checked free; only owned preview closed in finally.
Worktree: /home/edwinidrus/hobbys/dragonhoard_test-spike-m10-sky-vertex (uncommitted throwaway; existing tests untouched)
