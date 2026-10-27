import { test, expect } from '@playwright/test';
import { RACERS } from '../../src/logic/racers.js';

const rgb = (c) => `rgb(${(c >> 16) & 255}, ${(c >> 8) & 255}, ${c & 255})`;

test('option (c): styled silhouette menu', async ({ page }) => {
  const errors = [];
  const pageErrors = [];
  page.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
  page.on('pageerror', (e) => pageErrors.push(e.message));
  await page.addInitScript(() => {
    window.__glCount = 0;
    const getContext = HTMLCanvasElement.prototype.getContext;
    HTMLCanvasElement.prototype.getContext = function (kind, ...rest) {
      if (kind === 'webgl' || kind === 'webgl2') window.__glCount += 1;
      return getContext.call(this, kind, ...rest);
    };
  });

  await page.goto('/spike.html');
  const glOnLoad = await page.evaluate(() => window.__glCount);
  const buildMs = await page.evaluate(() => window.__buildMs);

  await page.evaluate(() => window.__spike.show(0));
  const cards = page.locator('#racer-menu-cards > .card');
  await expect(cards).toHaveCount(4);

  const rendered = await cards.evaluateAll((els) =>
    els.map((el) => ({
      id: el.dataset.racer,
      selected: el.dataset.selected === 'true',
      name: el.querySelector('.name')?.textContent,
      klass: el.querySelector('.klass')?.textContent,
      bars: el.querySelectorAll('.bar[data-stat]').length,
      stats: [...el.querySelectorAll('.bar[data-stat]')].map((b) => b.dataset.stat),
      preview: !!el.querySelector('[data-preview="silhouette"]'),
      colour: getComputedStyle(el.querySelector('[data-preview="silhouette"]')).color,
    })),
  );

  console.log('CARDS', JSON.stringify(rendered, null, 1));
  console.log('COLOURS', rendered.map((c) => c.colour).join(' | '));

  for (const card of rendered) {
    const racer = RACERS.find((r) => r.id === card.id);
    expect(racer, `card id in roster: ${card.id}`).toBeTruthy();
    expect(card.name).toBe(racer.name);
    expect(card.klass).toBe(racer.klass);
    expect(card.bars).toBe(3);
    expect(card.stats.sort()).toEqual(['accel', 'handling', 'speed']);
    expect(card.preview).toBe(true);
    expect(card.colour).toBe(rgb(racer.color));
  }
  expect(rendered.filter((c) => c.selected).length).toBe(1);
  expect(new Set(rendered.map((c) => c.colour)).size).toBe(4);

  await page.evaluate(() => {
    window.__spike.hide();
    window.__spike.show(1);
    window.__spike.hide();
    window.__spike.show(0);
    window.__spike.hide();
  });
  const glAfter = await page.evaluate(() => window.__glCount);
  const canvases = await page.evaluate(() => document.querySelectorAll('canvas').length);

  await page.evaluate(() => window.__spike.show(2));
  await page.screenshot({ path: 'test-results/spike-c.png' });

  console.log('glOnLoad', glOnLoad, 'glAfterShowHide', glAfter, 'canvases', canvases, 'buildMs', buildMs);
  console.log('consoleErrors', JSON.stringify(errors), 'pageErrors', JSON.stringify(pageErrors));
  expect(errors).toEqual([]);
  expect(pageErrors).toEqual([]);
});
