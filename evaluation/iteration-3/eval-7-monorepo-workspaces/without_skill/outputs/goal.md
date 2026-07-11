I inspected the monorepo first: it's an npm-workspaces repo (`workspaces: ["packages/*"]`) with two packages — `@acme/api` (`packages/api`, test script `jest`) and `@acme/web` (`packages/web`, test script `vitest run`). The root `package.json` has no aggregate `test` script, and there's no `node_modules` yet, so dependencies need installing before anything can run. I used npm's `--workspaces` flag to run both packages' test scripts from one command, since that's the most reliable way to get a single, greppable signal covering every package.

Here's the goal:

```
/goal Every package's test suite in this monorepo passes: @acme/api (packages/api, jest) and @acme/web (packages/web, vitest). Prove it by, in the most recent turn, running `npm install --workspaces` (if not already done) followed by `npm test --workspaces --if-present` from the repo root, and showing the output contains, for @acme/api, a Jest summary line with "0 failed" (e.g. "Tests: N passed, N total"), and for @acme/web, a Vitest summary showing "0 failed" (e.g. "Test Files  N passed", "Tests  N passed") — with the overall command exiting 0 — or stop after 15 turns or if the same test failure recurs twice, then summarize what's blocking. Do not delete, skip, or weaken any test file under packages/*/tests, and do not remove packages from the root "workspaces" field to dodge a failing one — show `git diff --stat` each turn to confirm only non-test source files changed.
```

Notes on the choices:
- **Proof command**: `npm test --workspaces --if-present` runs each workspace's own `test` script (jest for api, vitest for web) in one shot and prints both results in the same output — this is the "run everything" command since there's no root aggregate script. `--if-present` avoids failing on a workspace that later adds no test script.
- **Evidence signal**: pinned to each runner's actual summary line (Jest vs. Vitest have different formats), so a subset run or a chatty "all good" claim without pasted output won't satisfy it.
- **Guardrail**: blocks the easy "make it pass" shortcuts — deleting/skipping tests, or quietly dropping a failing package out of `workspaces`.
- **Stop clause**: bounded at 15 turns with a stall detector (repeated identical failure), and requires a blocker summary if it stops early, so you're not left guessing why.

One practical note: since goals that run shell commands pause on approval prompts unless you're in `acceptEdits` or `bypassPermissions` mode, make sure one of those is set before starting the goal, or Claude will stop at the first `npm install`/`npm test` prompt instead of looping autonomously.
