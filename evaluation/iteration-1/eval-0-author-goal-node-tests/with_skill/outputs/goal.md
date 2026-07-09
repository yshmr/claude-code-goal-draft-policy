```
/goal Every test under tests/auth passes. Prove it by, in the most recent turn, running `npm run test:auth` and showing Jest's summary line reports 0 failed (all tests passing). Do not edit any file under tests/ — the source under src/ must be fixed instead. Stop after 15 turns, or if the same failure recurs twice — then summarize the blocker.
```

**Rationale:** Verification command is `npm run test:auth` (defined in package.json as `jest tests/auth`) — it targets exactly the authentication suite (`tests/auth/login.test.ts`), so it is scoped and faster than the full `npm test`. There is no CI config to override this choice. The `0 failed` signal is Jest's own summary output, which a chatty summary can't fake; the guardrail forbids editing `tests/` so Claude can't "pass" by weakening the tests. Note: for unattended turns, run this in `acceptEdits` (Auto) mode — otherwise each shell/edit approval prompt will pause the goal loop.
