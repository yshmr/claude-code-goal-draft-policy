I inspected the repo first. It's an npm workspaces monorepo (`package.json` at the root has `"workspaces": ["packages/*"]`, no yarn/pnpm lockfile), with two packages that each have their own test runner and no root-level aggregate script:

- `packages/api` → `jest` (`packages/api/package.json` → `"test": "jest"`)
- `packages/web` → `vitest run` (`packages/web/package.json` → `"test": "vitest run"`)

The root `package.json` only defines a `dev` script — there's no root `test` script and no CI config (`.github/workflows`, etc.) to crib the canonical command from. The right command for "every package's tests" here is npm's own workspace fan-out: `npm test --workspaces --if-present`, which runs each package's own `test` script (skipping any workspace that lacks one) and prints both runners' summaries in one invocation.

Here's the goal, ready to paste:

```
/goal Every package in this workspace has its tests passing: `packages/api`
(jest) and `packages/web` (vitest). Prove it by, in the most recent turn,
running `npm test --workspaces --if-present` from the repo root and showing,
for each workspace, a summary line where the passed count equals the total
count and no failed count appears (e.g. jest's "Tests: N passed, N total",
vitest's "Tests  N passed (N)") — both @acme/api and @acme/web must appear in
that same run's output, not a filtered or single-package run. Do not delete or
skip a package's tests and do not remove any entry from the root
`workspaces` array to dodge a failure — show `git diff --stat` each turn to
confirm only source files under `packages/*/src` changed. Stop after 15 turns
or if the same test failure recurs twice, then summarize what's still
blocking.
```

Why this command: there's no root `test` script and no CI workflow to copy from, so I picked npm's workspace fan-out (`--workspaces --if-present`) rather than guessing a script that doesn't exist — it's the one invocation that actually exercises both `jest` and `vitest` in a single turn. The evidence signal is phrased as "passed count equals total, no failed count" rather than a literal "0 failed" string, because on an all-green run neither Jest nor Vitest actually prints the words "0 failed" — they just report the passed/total tallies. Both package names are required in the same turn's output specifically to block a subset run (e.g. only `api`'s tests) from satisfying the condition.

One practical note: since the proof command runs a real shell command, if this session isn't in `acceptEdits`/`bypassPermissions` mode you'll get a permission prompt on the first `npm test` call — approve it once and the rest of the autonomous loop can proceed unattended.
