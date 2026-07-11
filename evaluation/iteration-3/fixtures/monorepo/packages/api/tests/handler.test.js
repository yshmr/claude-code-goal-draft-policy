const { handle } = require("../src/handler");

test("handle returns 200", () => {
  expect(handle({ name: "x" }).status).toBe(200);
});
