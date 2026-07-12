I checked `.github/workflows/ci.yml` — CI runs three separate commands, not just `npm test`:

```
npm run lint
npm run typecheck
npx jest --ci      # full suite: tests/unit AND tests/integration
```

The workflow file even has a comment warning about this: `npm test` (defined in `package.json`) only runs `jest tests/unit`, so it's a strict subset of what CI actually checks. A goal that just says "until tests pass" would silently miss lint, type errors, and the integration tests. Here's a `/goal` that matches CI exactly:

```
/goal Keep working autonomously until all three of these commands succeed with a clean/zero exit status, run from the repo root: `npm run lint`, `npm run typecheck`, and `npx jest --ci`. Note that `npm test` is NOT sufficient — it only runs tests/unit, while CI (.github/workflows/ci.yml) also requires tests/integration via `npx jest --ci`. After making any fix, re-run all three commands from scratch (don't assume a fix to one didn't affect another). Do not stop to ask for confirmation between iterations. Only stop when all three pass in the same run, or if you've made a genuine attempt and hit a blocker you can't resolve yourself (e.g. a failing test that reveals ambiguous/missing product requirements) — in that case, stop and explain the blocker rather than guessing.
```

A couple of things worth knowing before you run it:

- I didn't run the commands myself, so I don't know the current failure state (lint errors, type errors, or which tests are red) — the goal is written to discover and fix all of that, whatever it turns out to be.
- If you'd rather Claude stop and report instead of attempting fixes on ambiguous test failures, say so and I can tighten the "blocker" clause; as written it gives Claude latitude to keep trying reasonable fixes.
