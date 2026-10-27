import test from 'node:test';
import assert from 'node:assert/strict';
import { STEP, createFixedStep } from '../../src/logic/loop.js';

test('STEP is 1/60 s', () => {
  assert.equal(STEP, 1 / 60);
});

test('advance(STEP) 60 times runs 60 steps', () => {
  const loop = createFixedStep();
  let total = 0;
  for (let i = 0; i < 60; i++) total += loop.advance(STEP);
  assert.equal(total, 60);
});

test('short frames accumulate', () => {
  const loop = createFixedStep();
  assert.equal(loop.advance(STEP / 2), 0);
  assert.equal(loop.advance(STEP / 2), 1);
});

test('a long frame is capped at maxSteps and the leftover is dropped', () => {
  const loop = createFixedStep();
  assert.equal(loop.advance(1), 5);
  assert.equal(loop.advance(0), 0);
  // Without the drop, 55 steps of debt would still be queued.
  assert.equal(loop.advance(STEP), 1);
});

test('non-positive or NaN seconds run nothing and leave the accumulator alone', () => {
  const loop = createFixedStep();
  assert.equal(loop.advance(-1), 0);
  assert.equal(loop.advance(0), 0);
  assert.equal(loop.advance(NaN), 0);
  assert.equal(loop.advance(STEP), 1);
});

test('custom step and maxSteps', () => {
  assert.equal(createFixedStep({ step: 0.1, maxSteps: 2 }).advance(0.25), 2);
});
