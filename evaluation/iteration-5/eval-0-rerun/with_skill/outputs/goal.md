Here's a `/goal` you can hand off with — paste this and Claude will keep looping on its own until the authentication tests pass, without needing your approval each turn:

```
/goal Every test in tests/auth passes. Prove it by, in the most recent turn,
running `npx jest tests/auth` and showing the summary line reports 2 passed,
2 total, 0 failed — or stop after 15 turns or if the same failure recurs
twice, then summarize the blocker. Do not modify or delete any file under
tests/ — show `git diff --stat` each turn to prove it. State the turn number
each turn.
```

Notes on how I built this:

- **Proof command**: I checked `package.json` — there's a `test:auth` script (`jest tests/auth`) and a plain `test` script (`jest`). I used the equivalent direct invocation `npx jest tests/auth` so the scope is pinned explicitly in the condition itself rather than relying on a script name staying unchanged.
- **Evidence signal**: `tests/auth/login.test.ts` currently has exactly 2 tests, so I pinned the exact expected count (`2 passed, 2 total, 0 failed`) — this stops a partial/filtered run or a single passing test from satisfying the goal.
- **Guardrail**: Claude could otherwise "pass" by editing or deleting the test file rather than fixing the auth code. The condition blocks that and requires `git diff --stat` each turn as visible proof, not just a promise.
- **Stop clause**: capped at 15 turns, with a stall check (same failure twice) so it doesn't burn turns on an unfixable issue, and it must summarize the blocker if it stops without success.

One thing to be aware of: since this goal runs shell commands (`npx jest`, `git diff`), Claude will still hit approval prompts for each tool call unless you're running in `acceptEdits` or `bypassPermissions` mode — worth switching to one of those if you truly want it to run unattended.
