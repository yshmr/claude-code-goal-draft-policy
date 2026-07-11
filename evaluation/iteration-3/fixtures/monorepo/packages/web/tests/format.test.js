import { expect, test } from "vitest";
import { formatPrice } from "../src/format.js";

test("formats cents", () => {
  expect(formatPrice(1234)).toBe("$12.34");
});
