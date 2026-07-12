const { test } = require("node:test");
const assert = require("node:assert");
const { mean, max } = require("../src/stats.js");

test("mean of [2,4,6] is 4", () => {
  assert.strictEqual(mean([2, 4, 6]), 4);
});

test("mean of empty list is 0", () => {
  assert.strictEqual(mean([]), 0);
});

test("max of [3,9,1] is 9", () => {
  assert.strictEqual(max([3, 9, 1]), 9);
});
