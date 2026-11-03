import { test, expect } from '@playwright/test';

test('racer menu preview: baked data URL per racer', async ({ page }) => {
  const errors = [];
  const pageErrors = [];
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', (e) => pageErrors.push(e.message));

  await page.addInitScript(() => {
    window.__glCount = 0;
    const orig = HTMLCanvasElement.prototype.getContext;
    HTMLCanvasElement.prototype.getContext = function (type, ...rest) {
      if (type === 'webgl' || type === 'webgl2' || type === 'experimental-webgl') window.__glCount += 1;
      return orig.call(this, type, ...rest);
    };
  });

  await page.goto('/spike.html');
  const glOnLoad = await page.evaluate(() => window.__glCount);

  await page.evaluate(() => window.__spike.show(0));
  const built = await page.evaluate(() => ({
    buildMs: window.__spike.buildMs,
    glAfterBuild: window.__spike.glAfterBuild,
    glCount: window.__glCount,
  }));
  const selectedAfterShow0 = await page.evaluate(() => document.querySelector('[data-selected="true"]')?.dataset.racer ?? null);

  await page.screenshot({ path: 'test-results/spike-a.png' });
  await page.evaluate(() => { window.__spike.hide(); window.__spike.show(1); window.__spike.hide(); });
  const glAfterCycles = await page.evaluate(() => window.__glCount);
  const canvasesAfter = await page.evaluate(() => document.querySelectorAll('canvas').length);

  // Blank-bake guard: count non-transparent pixels of each baked preview.
  const px = await page.evaluate(async () => {
    const out = [];
    for (const img of document.querySelectorAll('#racer-menu-cards img.preview')) {
      await img.decode();
      const c = document.createElement('canvas');
      c.width = img.naturalWidth;
      c.height = img.naturalHeight;
      const ctx = c.getContext('2d');
      ctx.drawImage(img, 0, 0);
      const d = ctx.getImageData(0, 0, c.width, c.height).data;
      let opaque = 0;
      for (let i = 3; i < d.length; i += 4) if (d[i] > 8) opaque += 1;
      out.push({ opaque, total: d.length / 4 });
    }
    return out;
  });

  const cards = await page.evaluate(() =>
    [...document.querySelectorAll('#racer-menu-cards .card')].map((card) => {
      const img = card.querySelector('img.preview');
      return {
        racer: card.dataset.racer,
        name: card.querySelector('.name')?.textContent,
        klass: card.querySelector('.class')?.textContent,
        bars: [...card.querySelectorAll('[data-stat]')].map((b) => b.dataset.stat).join(','),
        src: img?.getAttribute('src') ?? null,
        naturalWidth: img?.naturalWidth ?? 0,
      };
    }),
  );
  const selected = await page.evaluate(() => document.querySelector('[data-selected="true"]')?.dataset.racer ?? null);
  // Rebuild once: the same lazy build path, to see whether a second build adds a second GL context.
  const rebuild = await page.evaluate(() => { window.__spike.rebuild(); return window.__glCount; });

  const urls = cards.map((c) => c.src);
  const checks = {
    fourCards: cards.length === 4,
    eachComplete:
      cards.every((c) => c.name && c.klass && c.bars === 'speed,accel,handling' && c.src) &&
      new Set(cards.map((c) => c.racer)).size === 4,
    srcIsDataUrl: cards.every((c) => c.src.startsWith('data:image')),
    naturalWidthPositive: cards.every((c) => c.naturalWidth > 0),
    urlsPairwiseDifferent: new Set(urls).size === 4,
    previewsHaveOpaquePixels: px.every((p) => p.opaque > 0),
    noConsoleErrors: errors.length === 0,
    noPageErrors: pageErrors.length === 0,
    selectedMarksCard: selectedAfterShow0 === 'cinder' && selected === 'redacted-f6-iddile',
  };

  console.log('MEASUREMENTS ' + JSON.stringify({
    cards: cards.map((c) => ({ racer: c.racer, name: c.name, klass: c.klass, bars: c.bars, naturalWidth: c.naturalWidth, srcHead: c.src.slice(0, 24) })),
    checks,
    consoleErrors: errors,
    pageErrors,
    glContexts: { onLoad: glOnLoad, afterBuild: built.glAfterBuild, afterEnterLeaveCycles: glAfterCycles, afterRebuild: rebuild },
    opaquePixels: px.map((p) => p.opaque),
    buildMs: Math.round(built.buildMs),
    canvasesInDom: canvasesAfter,
    selected,
    selectedAfterShow0,
    screenshot: 'test-results/spike-a.png',
  }, null, 2));

  const failed = Object.entries(checks).filter(([, ok]) => !ok).map(([k]) => k);
  console.log(`DECISION: ${failed.length === 0 ? 'PASS' : 'FAIL'} ${failed.join(' ')}`);
  expect(failed).toEqual([]);
});
