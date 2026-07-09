import { route } from "../../src/router";

test("unknown path returns 404 (integration)", () => {
  expect(route("/nope")).toBe(404);
});
