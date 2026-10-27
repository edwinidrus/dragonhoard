# G10 review: M10 render code (external judge, Opus 5.5, 2026-10-27)

Scope: `git diff e3ce140 (G9) .. working tree (M10-T09)` over `src/` — `main.js`, `render/{scene,sky,clouds,
farIslands,dragon,fallVisual,hazards,roadDressing,trackMesh,scenery,sceneryData,glow}.js`. Read for
correctness, resource lifetime (gate criterion 5), the one-WebGL-context rule and per-frame cost.

**Result: 0 bugs, 3 risks, 1 question. No fix task needed.**

## Checked and fine

- One `WebGLRenderer` for the page; the sky gradient is a 128×72 PNG behind a transparent canvas, so no second
  context or document canvas (`sky.js`). The previous blob URL is revoked when a new one is set.
- Replacement disposal: `startRace` removes and disposes the track mesh, scenery, clouds (`clouds.dispose()`
  also releases the instance buffers) and far islands next to each remove. The page-owned dragon is moved back
  to the scene before its island group is disposed, so its cached geometry survives (`main.js:122-129`).
- Generated textures: the start-arch banner (`trackMesh.js:189`) and the T09 halo map (`scenery.js`) are
  released by a `dispose` listener on their material; `disposeTree` owns the material. The halo
  `InstancedMesh` buffers are released the same way.
- Gold split (owner amendment): rocks and tops keep the original merged Lambert batch; the 380-triangle hash in
  `roadIslands.test.js` still holds across the two batches.
- Fall visual is presentation only: `fallVisual` reads `entry.fall` and never writes it; `src/logic` unchanged
  since G9.
- Review hooks are inert: `__hoard.view` only moves the camera; `drawCalls` only reads `renderer.info`.

## Risks (kept, recorded)

1. **Race-start cost.** `cloudPlan` calls `minRoadDistance` (720 `pointAt` samples) for every puff candidate,
   up to 40 candidates per puff, on every Lantern start. It is one-off per race, not per frame, but it adds to
   the start pause the T08 journal measured. Upgrade path: cache the plan per track id.
2. **Shared gold pulse.** All four gold piles glint together (one material). Documented with a `ponytail:`
   comment; per-pile variation would need instance attributes.
3. **Faint halo on a bright background.** Additive halos at opacity 0.32 barely show where the dusk sea behind a
   lantern is bright (`dist/m10-t09/details/lantern-halo.png`). Objective criterion met; the feel is
   owner-unverified.

## Question for the owner

- Leaving a race for the menu keeps the last race's world (track, scenery, clouds, islands, dragon) in the scene
  until the next race replaces it. This is the lifecycle M7 accepted ("dispose next to its remove" at
  replacement). Gate criterion 5 says "replacing/leaving"; the judge reads it as satisfied by disposal at
  replacement, since nothing is removed on leaving. Say if you want the menu to drop the world instead.

Minor, not a finding: `createScene().dispose()` does not revoke the last backdrop blob URL; it runs only on a
real page unload, where the browser frees it anyway.
