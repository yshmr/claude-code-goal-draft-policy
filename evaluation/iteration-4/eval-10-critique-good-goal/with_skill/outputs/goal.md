Good news on the condition itself: this is a well-formed goal. It hits all five elements — a measurable end state, a real proof command, a pinned evidence signal, a checkable guardrail, and a stop clause correctly joined with "or" so it actually terminates the loop. I checked it against the repo and want to flag one thing before you set it.

**The condition text is fine as written — no edits needed:**
- `npm run test:auth` is a real script (`package.json`: `"test:auth": "jest tests/auth"`) — not an imaginary command.
- `tests/auth` contains exactly one file, `login.test.ts`, with exactly 2 `test(...)` blocks — so `Tests: 2 passed, 2 total` is the correct total, not a guess. Good instinct pinning the count: it stops a partial/filtered run from satisfying the goal.
- The stop clause is attached to the main condition with "or" (not a trailing sentence), which is what actually makes a turn cap or stall detector honored — many /goal drafts get this wrong.
- The guardrail requires `git diff --stat` as visible evidence each turn, not just a promise not to touch `tests/` — that's what makes it enforceable by a transcript-only evaluator.
- "State the turn number each turn" is present, which the cap needs to be trivially countable.

**One real blocker, not in the wording but in the repo's current state:** I installed dependencies and ran `npm run test:auth` against this fixture as it stands today, and it currently fails — but not because the auth logic is wrong. There is no Jest config, no `jest` field in `package.json`, no `babel.config`, and no `ts-jest`/`@babel/preset-typescript` in devDependencies. Plain Jest can't parse the TypeScript `import` syntax in `login.test.ts` and errors out with `SyntaxError: Cannot use import statement outside a module` before running anything (`Tests: 0 total`, not a failure of the 2 tests). I confirmed the fix: installing `ts-jest`/`@types/jest` and adding a `jest.config.js` with `preset: "ts-jest"` makes both tests pass, and Jest's real summary line is `Tests:       2 passed, 2 total` (extra alignment spaces, but the substring you named appears verbatim) — so the evidence signal is correctly worded and will show up once the tooling is fixed. I reverted these installs afterward; the fixture is untouched.

This isn't a flaw in the `/goal` text — it doesn't restrict Claude from touching `package.json`, `package-lock.json`, or adding a `jest.config.js`, only files *under* `tests/`, so fixing the Jest/TypeScript setup is legitimate work toward the end state, not a guardrail violation. It just means turn 1 won't show a pass — expect Claude to spend a turn or two adding the missing Jest/TS transform before the first green run. With a 15-turn cap that's comfortable headroom, so I'd leave the goal as-is.

**Ready to paste, unchanged:**
```
/goal Every test under tests/auth passes. Prove it by, in the most recent turn, running `npm run test:auth` and showing the Jest summary reports `Tests: 2 passed, 2 total` — or stop after 15 turns or if the same failure recurs twice, then summarize the blocker. Do not modify or delete any file under tests/ — show `git diff --stat` each turn to prove it. State the turn number each turn.
```
