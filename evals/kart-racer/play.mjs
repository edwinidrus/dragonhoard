// Auditor's own Playwright pass (independent of the builder's smoke test).
//   node play.mjs <served dir> <game repo> [holdMs=2000] [port=8790]
// Serves the build, records page/console errors, checks the frame counter advances
// (window.__hoard.frame if the game exposes it), holds ArrowUp, then compares
// screenshots and any exposed player state. Prints one JSON line.
import { createRequire } from 'node:module';
import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';

const [serveDir, gameRepo, holdMs = '2000', port = '8790'] = process.argv.slice(2);
const { chromium } = createRequire(`${gameRepo}/package.json`)('playwright');
const server = spawn('python3', ['-m', 'http.server', port, '--bind', '127.0.0.1', '-d', serveDir], { stdio: 'ignore' });
await new Promise((r) => setTimeout(r, 800));

const result = { pageErrors: [], consoleErrors: [] };
const browser = await chromium.launch();
try {
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  page.on('pageerror', (e) => result.pageErrors.push(e.message));
  page.on('console', (m) => m.type() === 'error' && !m.text().includes('favicon') && result.consoleErrors.push(m.text()));
  await page.goto(`http://127.0.0.1:${port}/`);
  await page.waitForTimeout(1500);
  const state = () => page.evaluate(() => JSON.parse(JSON.stringify(window.__hoard ?? null)));
  const shot = async () => createHash('sha256').update(await page.screenshot()).digest('hex').slice(0, 12);
  const s0 = await state(); const img0 = await shot();
  await page.locator('canvas').first().click();
  await page.keyboard.down('ArrowUp');
  await page.waitForTimeout(Number(holdMs));
  await page.keyboard.up('ArrowUp');
  const s1 = await state(); const img1 = await shot();
  result.exposed = s0 !== null;
  result.frameAdvanced = typeof s0?.frame === 'number' ? s1.frame > s0.frame : 'not exposed';
  result.frames = [s0?.frame, s1?.frame];
  result.screenshotChangedAfterHold = img0 !== img1;
  result.stateBefore = s0; result.stateAfter = s1;
} finally {
  await browser.close();
  server.kill();
}
console.log(JSON.stringify(result));
