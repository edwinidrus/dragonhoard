import test from 'node:test';
import assert from 'node:assert/strict';
import { vec, add, sub, scale, dot, cross, length, normalize, rotate, fromAngle } from '../../src/logic/vec2.js';

const near = (a, b, eps = 1e-12) =>
  assert.ok(Math.abs(a.x - b.x) < eps && Math.abs(a.y - b.y) < eps, `${JSON.stringify(a)} is not near ${JSON.stringify(b)}`);

test('vec builds {x, y}', () => {
  assert.deepEqual(vec(1, 2), { x: 1, y: 2 });
});

test('add, sub, scale', () => {
  assert.deepEqual(add(vec(1, 2), vec(3, 5)), { x: 4, y: 7 });
  assert.deepEqual(sub(vec(1, 2), vec(3, 5)), { x: -2, y: -3 });
  assert.deepEqual(scale(vec(1, -2), 3), { x: 3, y: -6 });
});

test('dot, and cross as the z of the 3D cross', () => {
  assert.equal(dot(vec(1, 2), vec(3, 4)), 11);
  assert.equal(cross(vec(1, 0), vec(0, 1)), 1);
  assert.equal(cross(vec(0, 1), vec(1, 0)), -1);
});

test('length and normalize; zero vector stays zero', () => {
  assert.equal(length(vec(3, 4)), 5);
  near(normalize(vec(3, 4)), vec(0.6, 0.8));
  assert.deepEqual(normalize(vec(0, 0)), { x: 0, y: 0 });
});

test('rotate is counter-clockwise', () => {
  near(rotate(vec(1, 0), Math.PI / 2), vec(0, 1));
  near(rotate(vec(0, 1), Math.PI / 2), vec(-1, 0));
});

test('fromAngle gives a unit vector', () => {
  near(fromAngle(0), vec(1, 0));
  near(fromAngle(Math.PI / 2), vec(0, 1));
  assert.ok(Math.abs(length(fromAngle(1.234)) - 1) < 1e-12);
});

test('inputs are never mutated; vector results are new objects', () => {
  // Frozen inputs make any write throw in module (strict) code.
  const a = Object.freeze(vec(1, 2));
  const b = Object.freeze(vec(3, 4));
  const zero = Object.freeze(vec(0, 0));
  for (const r of [add(a, b), sub(a, b), scale(a, 2), normalize(a), rotate(a, 1)]) assert.notEqual(r, a);
  assert.notEqual(normalize(zero), zero);
  dot(a, b);
  cross(a, b);
  length(a);
  assert.deepEqual(a, { x: 1, y: 2 });
  assert.deepEqual(b, { x: 3, y: 4 });
});
