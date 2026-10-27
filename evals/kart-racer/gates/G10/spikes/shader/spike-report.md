Option: ShaderMaterial gradient sky dome (M10-T02 Explore only)
Verdict: WORKS
Criterion: `node spike-check.mjs` -> `PASS both tracks; console/page errors=0; runtime image/texture requests=0; dependencies/main/toneMapping unchanged`
Exact recorded run: `node spike-check.mjs > evidence/criterion.log 2>&1`; exit 0; full output in evidence/criterion.log.
Baseline: clean HEAD23eeedc built before source edits; criterion rebuilds pinned scene through Vite pre-load hook and asserts same total.
Canonical gzip: each emitted JS/HTML file's bytes piped separately to `gzip -9 -c` stdin (no filename header), sizes summed; no Vite gzip figures.
Canonical baseline: JS148251 + HTML369 =148620 B; prototype JS149176 + HTML370 =149546 B; delta JS+925 + HTML+1 =+926 B.
Original Node gzipSync level9 NONCANONICAL: baseline JS148877/HTML369/total149246; prototype JS149839/HTML370/total150209; delta+963 B. Node zlib differs from CLI gzip here.
Standardized draw calls: Lantern sun1, anti-sun1, zenith1, Ember day1; each explicitly asserted equal1, PNG signature checked and >2000 bytes.
Original draw calls: Lantern sun39, zenith7, anti-sun15, translated1, Ember day7; all asserted >0 and <=100. Not whole-track maximum.
Dome cost: one draw; radius450 within far500; 561 actual vertices, 960 actual indexed triangles; BackSide, depthWrite=false.
Implementation: linear THREE.Color uniforms, colorspace_fragment output; five-stop gradient, analytic +x sun at4.5deg, stars gated above45deg, blue-grey anti-sun and rose Belt of Venus.
Camera centring: render-time position copy before scene matrices; translated pose [900,400,-800] still renders dome (1 call).
Standard PNGs: evidence/standard-lantern-sun.png (91746 B), standard-lantern-antisun.png (94007 B), standard-lantern-zenith.png (104393 B), standard-ember-day.png (44858 B); original five PNGs retained.
Standard poses: position[0,400,0]; sun/day target[100,407.87,0]; anti-sun[-100,407.87,0]; zenith[1,500,0]. Only __hoard.view moves camera.
Built: src/render/sky.js — 56 lines new.
Built: src/render/scene.js — 75 lines total; +8/-1 integration.
Built: spike-check.mjs — 113 lines throwaway runnable criterion; evidence/{baseline.json,result.json,criterion.log,9 PNGs}; dist/ and dist-baseline/ generated.
Built: spike-report.md — normalized evidence report; no implementation changes during normalization.
Cost: zero new dependencies; ~64 source lines added; one sphere, one material, one render position copy and one track uniform update.
Preserved: DAY_SKY, DUSK_SKY, skyColor, setSky(track) helper call; createScene calls/pose; main.js/package.json/package-lock.json byte-identical to HEAD.
Assertions: both real built tracks reach racing; console/page errors=[]; HTTP image/texture request matches=[]; radius450, depthWrite=false, colorspace_fragment present; main/package/lock byte-identical; toneMapping token count unchanged. No new dependencies.
Visual-only: personally read standardized sun PNG: small pale-gold disk centred against smooth gold→orange→rose/purple gradient; HUD remains, ground absent. No automated pixel/color/sun-angle/star-height/Belt-of-Venus oracle; other standardized PNG appearances unverified this normalization.
Server: actual output `PORT 5181 free; strictPort=true`; own Vite preview closed in finally; no foreign process stopped.
Risks: finite mesh costs 561 vertices/960 triangles versus background clear; full-screen fragment hash/trig cost unbenchmarked, draw calls alone do not prove FPS.
Risks: spherical hash stars may alias or crowd near poles; fixed low-density pattern needs owner visual review. Existing Vite >500kB chunk warning remains.
Limitations: DOME ONLY; ground, shadows, fog and lighting intentionally unchanged for same comparison scope as vertex option; no gameplay/audio edits or full-suite claim.
Model: openai/gpt-6.1-sol#high.
Worktree: /home/edwinidrus/hobbys/dragonhoard_test-spike-m10-sky-shader
