Short answer: this is a well-formed goal and it will almost certainly complete correctly — it hits all five elements (end state, proof command, evidence signal, guardrail, stop clause) and joins the stop clause into the condition properly. I checked it against the actual repo and found no wording bug, but there are two practical things worth knowing before you set it.

## What I verified in the repo

- `package.json` really does define `"test:auth": "jest tests/auth"` — the proof command exists and is scoped to the right directory. Good.
- `tests/auth/login.test.ts` has exactly 2 tests, and `src/auth/login.ts` implements `login()` in a way that satisfies both (`tok_${user}` matches `/^tok_/`; empty creds return `null`). So the end state is actually reachable — this isn't a goal chasing a bug that doesn't exist.
- Jest's real summary block does print a line in the form `Tests:       2 passed, 2 total`, so the evidence signal you wrote is the actual string Jest emits, not an invented one. No scope-gaming risk either, since there's only one test file in `tests/auth` with exactly 2 tests — a partial/filtered run can't fake this total.
- The guardrail is written correctly per the "make it checkable" pattern: it asks for `git diff --stat` on screen every turn rather than trusting a claim of non-modification.
- The stop clause is joined with `, or stop after 15 turns or if...` (not a free-standing sentence), which is the form that reliably terminates the loop, and it ends in "summarize the blocker" and "state the turn number," both of which matter for the evaluator to actually honor the cap.

## Two things to fix or know before you set it

1. **`node_modules` isn't installed** — I ran `npm run test:auth` and it fails immediately with "'jest' is not recognized" because `package-lock.json` has an empty `packages` list and nothing is installed. This isn't a flaw in your condition's wording — Claude will just need to run `npm install` first, which is allowed (it doesn't touch anything under `tests/`). But it will eat a turn or two of your 15-turn budget on environment setup before it ever gets to a real test run, and it depends on npm registry access being available in the environment. If turns are tight, bump the cap slightly or mention upfront that install may be needed.

2. **This folder is not its own git repo — it's a subdirectory inside your larger `claude-goal-draft-policy` repo.** Plain `git diff --stat` run from here doesn't scope itself to the current directory; it reports tracked changes across the *whole* monorepo. In practice this is low-risk (untracked files, like the sibling `iteration-4/` folder, don't show up in `diff --stat` at all — only modified tracked files would), but if anything else in the repo has an uncommitted tracked change, the guardrail evidence gets noisy and harder for the evaluator (and you) to read cleanly. I'd tighten the guardrail line to pin the scope explicitly, e.g.:

   > show `git diff --stat -- tests/` each turn to prove it

   or, if Claude might not stay cd'd into `node-app`, use the full relative path from repo root (`evaluation/iteration-1/fixtures/node-app/tests/`). This is a small robustness improvement, not a correctness bug — the goal would likely still complete without it.

## Verdict

Set it as-is if you're comfortable with those two caveats — it should complete in a handful of turns (mostly spent on `npm install` + one clean `test:auth` run). If you want the belt-and-suspenders version, here's the same goal with the guardrail scoped:

```
/goal Every test under tests/auth passes. Prove it by, in the most recent turn, running `npm run test:auth` and showing the Jest summary reports `Tests: 2 passed, 2 total` — or stop after 15 turns or if the same failure recurs twice, then summarize the blocker. Do not modify or delete any file under tests/ — show `git diff --stat -- tests/` each turn to prove it. State the turn number each turn.
```

Only change from your draft: `git diff --stat` → `git diff --stat -- tests/`, so the guardrail evidence stays scoped even though this folder lives inside a larger repo.
