const { test } = require("node:test");
const assert = require("node:assert");

test("internal health endpoint responds 200", async () => {
  const res = await fetch("http://health.internal.invalid/healthz", {
    signal: AbortSignal.timeout(3000),
  });
  assert.strictEqual(res.status, 200);
});
