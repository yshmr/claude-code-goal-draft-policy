Your goal has two separate holes, and the smoke-test problem is only one of them. Here's the repaired version:

```
/goal All tests pass. Prove it by, in the most recent turn, running the bare
command `npm test` with no additional arguments or flags (no
--testPathPattern, -t, --testNamePattern, or any other filter) and pasting the
full output. The output must include a Jest summary block showing
"Test Suites: N passed, N total" and "Tests: M passed, M total" with 0 failed
in both lines — a run that filters to a subset of suites does not satisfy this,
even if it reports 0 failed — or stop after 15 turns or if the same failure
repeats twice, then summarize what's blocking. Do not edit or delete any file
under any `__tests__`/`test`/`spec` directory, and do not add/change any
`testPathPattern`, `testPathIgnorePatterns`, or `testMatch` entry in
package.json or jest.config.* to narrow what runs — show `git diff --stat`
each turn to prove test config and test files are untouched.
```

**What was wrong with the original, and why each fix closes the gap:**

1. **Scope was never pinned — this is the actual loophole.** "run `npm test`" sounds specific, but nothing forbade appending flags, and Jest happily accepts `-- --testPathPattern=smoke` as extra CLI args passed straight into the runner. The evaluator only reads the transcript; if it sees "ran npm test, 0 failed," it has no way to know that command only touched one file unless the *scope itself* is asserted as part of the condition. Fix: explicitly ban filter flags, and require the Jest summary's `total` counts (which reflect the whole suite, not just what ran) rather than just `0 failed` — a subset run also shows `0 failed` but its `total` will visibly be smaller than the real suite, and that discrepancy is now something the evaluator is told to check for.

2. **The stop clause was a free-standing sentence.** "Stop after 15 turns" as its own sentence, detached from the main condition, is not treated by the evaluator as a way to *complete* the goal — it's just prose. Fix: joined it into the condition with "... or stop after 15 turns or if the same failure repeats twice, then summarize what's blocking," so it's actually an OR-branch the evaluator can act on.

3. **No guardrail against gaming via config, not just via CLI flags.** Once the CLI-flag route is blocked, the next easiest way to shrink scope is quietly narrowing `testPathPattern`/`testMatch` in `jest.config.*` or `package.json` so plain `npm test` itself only picks up the smoke tests. Fix: added a guardrail forbidding those edits, backed by a required `git diff --stat` each turn so the claim is checkable, not just promised.

4. **"0 failed" alone is gameable by definition — it's true of an empty test run too.** Requiring the `total` count alongside `0 failed` means a shrunk run is visibly different from a full one, closing the "technically zero failures" loophole regardless of how the shrinkage happened.

One thing worth doing yourself: if you know the real total test count today (e.g., "312 total"), hardcode that exact number into the condition instead of just requiring "N total" — that removes any ambiguity about what the right total even is, and makes the check airtight rather than merely internally-consistent.
