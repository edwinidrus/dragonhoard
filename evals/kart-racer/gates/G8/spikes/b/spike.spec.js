import { test, expect } from '@playwright/test';

// Spike (b): four live <canvas> previews, one WebGLRenderer each. This decides WORKS/FAILS and
// prints the measurements the owner asked for.
test('spike (b): four live canvas racer previews', async ({ page }) => {
  const errors = [];
  page.on('console', (msg) => {
    if (msg.type() === 'error') errors.push(msg.text());
  });
  page.on('pageerror', (err) => errors.push(err.message));

  // Count WebGL contexts actually requested, page-wide.
  await page.addInitScript(() => {
    window.__glCount = 0;
    const original = HTMLCanvasElement.prototype.getContext;
    HTMLCanvasElement.prototype.getContext = function (type, ...rest) {
      if (type === 'webgl' || type === 'webgl2') window.__glCount += 1;
      return original.call(this, type, ...rest);
    };
  });

  await page.goto('/spike.html');
  await page.waitForFunction(() => window.__spike);

  const onLoad = await page.evaluate(() => window.__glCount);
  const buildMs = await page.evaluate(() => window.__spike.buildMs);

  await page.evaluate(() => window.__spike.show(0));
  await page.waitForTimeout(400);

  // 1. card structure (measured with the menu open: a hidden card has a 0px rect)
  const cards = await page.evaluate(() =>
    [...document.querySelectorAll('#racer-menu-cards [data-racer]')].map((card) => ({
      id: card.dataset.racer,
      name: card.querySelector('[data-name]')?.textContent ?? '',
      klass: card.querySelector('[data-class]')?.textContent ?? '',
      bars: [...card.querySelectorAll('[data-stat]')].map((bar) => ({
        stat: bar.dataset.stat,
        width: Math.round(bar.getBoundingClientRect().width),
      })),
      canvas: !!card.querySelector('canvas'),
    })),
  );

  // 2. the previews really show pixels, and are not all identical
  const shots = await page.evaluate(() =>
    [...document.querySelectorAll('#racer-menu-cards canvas')].map((canvas) => {
      const copy = document.createElement('canvas');
      copy.width = 32;
      copy.height = 32;
      const ctx = copy.getContext('2d');
      ctx.drawImage(canvas, 0, 0, 32, 32);
      const data = ctx.getImageData(0, 0, 32, 32).data;
      let nonBlank = 0;
      let hash = 0;
      for (let i = 0; i < data.length; i += 4) {
        const lum = data[i] + data[i + 1] + data[i + 2];
        if (lum > 12) nonBlank += 1;
        hash = (hash * 31 + lum) % 2147483647;
      }
      return { nonBlank, hash };
    }),
  );

  // 6. frame rate while the menu is visible
  const f0 = await page.evaluate(() => window.__spike.frames);
  await page.waitForTimeout(1000);
  const fps = (await page.evaluate(() => window.__spike.frames)) - f0;

  await page.screenshot({ path: 'test-results/spike-b.png' });

  // 4./5. enter and leave the racer menu twice
  await page.evaluate(() => {
    const s = window.__spike;
    s.hide();
    s.show(0);
    s.hide();
    s.show(1);
    s.hide();
  });
  const afterToggles = await page.evaluate(() => window.__glCount);
  const canvasCount = await page.evaluate(() => document.querySelectorAll('canvas').length);
  const rafRunning = await page.evaluate(() => window.__spike.rafRunning);

  console.log(`[b] cards=${cards.length}`);
  for (const card of cards) {
    console.log(
      `[b]   ${card.id} name="${card.name}" class="${card.klass}" bars=${card.bars
        .map((b) => `${b.stat}@${b.width}px`)
        .join(',')} canvas=${card.canvas}`,
    );
  }
  console.log(
    `[b] nonBlankPixels(32x32)=${shots.map((s) => s.nonBlank).join(',')} distinctHashes=${
      new Set(shots.map((s) => s.hash)).size
    }`,
  );
  console.log(`[b] errors=${JSON.stringify(errors)}`);
  console.log(`[b] glContexts onLoad=${onLoad} afterToggles=${afterToggles}`);
  console.log(`[b] canvasesInDom=${canvasCount} rafRunningAfterHide=${rafRunning}`);
  console.log(`[b] buildMs=${buildMs.toFixed(1)} fpsWhileVisible=${fps}`);

  expect(errors).toEqual([]);
  expect(cards).toHaveLength(4);
  for (const card of cards) {
    expect(card.name).not.toBe('');
    expect(card.klass).not.toBe('');
    expect(card.bars.map((b) => b.stat)).toEqual(['speed', 'accel', 'handling']);
    expect(card.bars.every((b) => b.width > 0)).toBe(true);
    expect(card.canvas).toBe(true);
  }
  expect(shots.every((s) => s.nonBlank > 100)).toBe(true);
  expect(new Set(shots.map((s) => s.hash)).size).toBeGreaterThan(1);
  expect(fps).toBeGreaterThan(5);
  expect(rafRunning).toBe(false);
  expect(canvasCount).toBe(4);
});
