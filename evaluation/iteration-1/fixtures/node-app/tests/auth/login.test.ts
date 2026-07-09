import { login } from "../../src/auth/login";

test("returns a token on valid credentials", () => {
  expect(login("alice", "pw")).toMatch(/^tok_/);
});

test("returns null on empty credentials", () => {
  expect(login("", "")).toBeNull();
});
