# Gate verification (independent of the builder)

REA runs from the audit side only, via `npx -y rea-agents@latest`. It is not installed into the
builder's agent config. Probed 2026-10-19 with Node 22.22.2 and Playwright Chromium 1234.

## Per gate

```bash
cd ~/hobbys/dragonhoard_planing
python3 evals/kart-racer/gate.py <served dir> gates/G<n> --static   # REA scenario + static analysis
```

`<served dir>` is the game root for a no-build stack, or the build output (e.g. `dist/` after
`npm run build`) for a bundler. If the game's countdown is longer than 4 s, raise `--wait-ms`.

| Check | Source | FAIL when |
|---|---|---|
| page-errors | REA `capture-browser-scenario`, event family `page-errors` | any uncaught page error |
| console-errors | REA, event family `console`, level `error` | any, except the browser's own `/favicon.ico` probe |
| missing-files | the gate's own `http.server` log | any 404 other than `/favicon.ico` |
| steps | REA step status | any scenario step not `completed` |
| frames-change | REA per-step screenshot SHA-256 | fewer than 2 distinct screenshots (nothing renders or changes) |
| rea-static | REA `analyze-javascript-application` | the analysis fails; its graph is kept for comparison with the GATE.md claims |

Then the **auditor's own Playwright pass**, written at the first gate against the real page
(REA `press` is a tap, not a hold):
- hold ArrowUp for 2 s and check that the kart moves (screenshot diff or exposed state);
- 30 s of mixed input with no page errors.

Then **compare with the GATE.md claims**. Every claimed criterion is either backed by evidence
(REA output, Playwright output, or the owner's play-test) or recorded as unverified.

## Calibration (2026-10-19, `gate.py --self-check`)

- `calibration/clean`: page-errors PASS, console-errors PASS (favicon 404 only),
  frames-change PASS (2 distinct; the tap moved the square from x=20 to x=30).
- `calibration/broken` (throws `undefinedKartPhysics` at frame 30): REA reported
  `page-error: undefinedKartPhysics is not defined`, and frames froze at 29 → FAIL.

## Known limitations

- `press` sends a tap; there is no key-hold action. Hold-to-accelerate is covered by Playwright
  instead.
- Static analysis keeps APIs and modules (`requestAnimationFrame`, `addEventListener`,
  `getContext`, file graph) but not string literals such as `"keydown"`.
- Canvas content is opaque to DOM capture. Frame changes come from screenshot hashes, and HUD
  text from the DOM only if the game draws its HUD in HTML.

## Auditor Playwright (`play.mjs`, written at G0)

`node play.mjs <served dir> <game repo> [holdMs]` loads Playwright from the game repo's own `node_modules`, serves the build, and reports page/console errors, `window.__hoard.frame` advance, the screenshot change after holding ArrowUp, and any exposed state.

- Calibration: `calibration/broken` → `pageErrors: ["undefinedKartPhysics is not defined"]`.
- G0: 0 errors; frame 88→201.
- Builds are made outside the repo: `npx vite build --outDir <scratch>/gNdist --emptyOutDir`.
- `gate.py` frames-change is **n/a for static scenes** (G0). From G1 on, the scene moves, so it applies.
