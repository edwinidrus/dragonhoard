import { chromium } from '@playwright/test';
import { writeFile } from 'node:fs/promises';

const BASE = 'http://localhost:5173';
const OUT = 'test-results';

async function pick(page, name) {
  await page.goto(BASE + '/');
  await page.waitForFunction(() => window.__hoard?.screen === 'menu');
  const selected = page.locator('#menu-choices [data-selected="true"]');
  for (let i = 0; i < 8 && (await selected.textContent()) !== name; i++) await page.keyboard.press('ArrowRight');
  if ((await selected.textContent()) !== name) throw new Error('could not select ' + name);
  await page.keyboard.press('Enter');
  await page.waitForFunction(() => window.__hoard?.phase === 'countdown');
}

// Pixel diff outside the HUD panel (top-left) and the centred countdown, in the page itself.
async function diffOutsideHud(page, a, b) {
  return page.evaluate(
    async ([a64, b64]) => {
      const load = (s) =>
        new Promise((resolve) => {
          const img = new Image();
          img.onload = () => resolve(img);
          img.src = 'data:image/png;base64,' + s;
        });
      const [ia, ib] = await Promise.all([load(a64), load(b64)]);
      const c = document.createElement('canvas');
      c.width = ia.width;
      c.height = ia.height;
      const g = c.getContext('2d');
      g.drawImage(ia, 0, 0);
      const da = g.getImageData(0, 0, c.width, c.height).data;
      g.clearRect(0, 0, c.width, c.height);
      g.drawImage(ib, 0, 0);
      const db = g.getImageData(0, 0, c.width, c.height).data;
      const masked = (x, y) => (x < 300 && y < 200) || (Math.abs(x - c.width / 2) < 180 && Math.abs(y - c.height / 2) < 120);
      let count = 0;
      let box = null;
      for (let y = 0; y < c.height; y++) {
        for (let x = 0; x < c.width; x++) {
          if (masked(x, y)) continue;
          const i = 4 * (y * c.width + x);
          if (Math.abs(da[i] - db[i]) + Math.abs(da[i + 1] - db[i + 1]) + Math.abs(da[i + 2] - db[i + 2]) > 24) {
            count++;
            box = box ? [Math.min(box[0], x), Math.min(box[1], y), Math.max(box[2], x), Math.max(box[3], y)] : [x, y, x, y];
          }
        }
      }
      return { count, box, width: c.width, height: c.height };
    },
    [a.toString('base64'), b.toString('base64')],
  );
}

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
const errors = [];
page.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
page.on('pageerror', (e) => errors.push(e.message));

await pick(page, 'Lantern Reach');
await page.waitForTimeout(300);
const kartsA = await page.evaluate(() => window.__hoard.karts);
const lanternA = await page.screenshot({ path: `${OUT}/m7t11-lantern-scenery.png` });
await page.waitForTimeout(1000);
const kartsB = await page.evaluate(() => window.__hoard.karts);
const lanternB = await page.screenshot({ path: `${OUT}/m7t11-lantern-scenery-1s.png` });
const lanternDiff = await diffOutsideHud(page, lanternA, lanternB);
const kartsHeld = JSON.stringify(kartsA) === JSON.stringify(kartsB);

await page.waitForFunction(() => window.__hoard?.phase === 'racing');
await page.keyboard.down('ArrowUp');
await page.waitForTimeout(4000);
await page.screenshot({ path: `${OUT}/m7t11-lantern-drive-1.png` });
await page.waitForTimeout(4000);
await page.screenshot({ path: `${OUT}/m7t11-lantern-drive-2.png` });
await page.keyboard.up('ArrowUp');

await pick(page, 'Ember Circuit');
await page.waitForTimeout(300);
const emberA = await page.screenshot({ path: `${OUT}/m7t11-ember.png` });
await page.waitForTimeout(1000);
const emberB = await page.screenshot({ path: `${OUT}/m7t11-ember-1s.png` });
const emberDiff = await diffOutsideHud(page, emberA, emberB);

const out = { kartsHeld, lanternDiff, emberDiff, errors };
console.log(JSON.stringify(out, null, 2));
await writeFile(`${OUT}/m7t11-shots.json`, JSON.stringify(out, null, 2));
await browser.close();
