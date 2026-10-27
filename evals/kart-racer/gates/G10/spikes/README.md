# M10-T02 sky spike archive

Copied from the throwaway worktrees `dragonhoard_test-spike-m10-sky-{shader,vertex}` (base `23eeedc`) before removal. Per option: `spike-report.md`, `spike-check.mjs`, `sky.js`, `src.diff` and `evidence/` (screenshots and results). The vertex spike's bundled baseline build is left out: it is build output, and minified three.js trips the audit's name regex on a substring.

Judge verdict (external judge, Opus): (a) shader gradient dome. Owner-proxy pick (a); warnings in `scorecard.md` (2026-10-26 M10-T02 row).

## M10-T03 clouds spikes (base `de6750a`)

`clouds-instanced/` and `clouds-billboard/`: screenshots, `result.json`, `spike-report.md` and `clouds.js` copied from `dist/m10-t03-spikes/` and the worktrees. The instanced spike used a generic geometry word for its angle-and-radius grid that is on the audit's protected-name list; the archive replaces it with "radial". Judge pick (a), instanced low-poly clusters, with the sea painted by the backdrop.
