I inspected the repo (`acme-auth-service`) before writing this. Key findings:

- The real auth test command is `npm run test:auth` (defined in `package.json` as `jest tests/auth`), covering `tests/auth/login.test.ts` (2 tests, exercising `src/auth/login.ts`).
- Right now that command actually fails — not because the login logic is wrong, but because there's no Jest transform configured for TypeScript (`SyntaxError: Cannot use import statement outside a module`). There's no `jest.config.*`, no `tsconfig.json`, and no `ts-jest`/`babel` dependency installed. So "get the tests passing" also means getting the TS toolchain wired up, not just fixing `login.ts`.
- There are 2 tests total in that file, so I pinned the total count into the evidence signal to stop a partial/filtered run from counting as done.

Here's the goal, ready to paste:

```
/goal Every test in tests/auth passes. Prove it by, in the most recent turn, running
`npm run test:auth` and showing the Jest summary line reports `2 passed, 2 total`
and `0 failed` — or stop after 15 turns or if the same failure recurs twice, then
summarize the blocker. Do not modify or weaken any test in tests/auth (no deleting
assertions, no changing expected values, no skipping tests) — show `git diff --stat`
each turn to prove tests/auth is untouched. Config/toolchain files (jest.config,
tsconfig.json, package.json, new devDependencies) may be added or changed as needed
to make the existing tests run. State the turn number each turn.
```

Why this shape:
- **Command**: `npm run test:auth` is the actual script in `package.json` — not a guessed `npm test` (which would run the whole suite, not just auth).
- **Evidence signal**: pinned to `2 passed, 2 total` (the real count in `tests/auth/login.test.ts`) plus `0 failed`, so Claude can't satisfy the goal by running a subset or by a chatty "tests pass now" claim with no output.
- **Guardrail**: since the failure is currently a missing TS/Jest transform, Claude will need to touch config files (`jest.config`, `tsconfig.json`, dependencies) — that's expected and allowed. What's *not* allowed is editing the test file itself to dodge the real bug, so I explicitly protected `tests/auth` and required a `git diff --stat` each turn as evidence.
- **Stop clause**: bounded at 15 turns with a stall detector (repeated identical failure), and Claude must summarize what's blocking it if it stops without success.

One thing to flag: `/goal` loops still pause on tool-approval prompts unless you're running in `acceptEdits` or `bypassPermissions` mode — since this goal needs Claude to run `npm install`/edit config files/run tests repeatedly, you'll want one of those modes on, or it'll still stop and wait for you each time it wants to run a shell command.
