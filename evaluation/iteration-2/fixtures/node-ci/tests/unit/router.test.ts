import { route } from "../../src/router";

test("routes known path", () => {
  expect(route("/health")).toBe(200);
});
