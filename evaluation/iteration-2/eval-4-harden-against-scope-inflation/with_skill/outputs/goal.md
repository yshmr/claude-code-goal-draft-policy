# Hardened goal: prevent scope gaming on `npm test`

## Diagnosis

Your goal already has the right bones — an end state, a proof action (`npm test`),
an evidence signal (`0 failed`), and a stop clause. It fails on **one axis the
evaluator can't defend on its own: scope.**

The evaluator only reads the transcript; it never runs anything. So if Claude runs
`npm test -- --testPathPattern=smoke`, sees `0 failed`, and narrates "all tests
pass", the transcript literally contains a passing run and the phrase "all tests
pass". `0 failed` is true — of the smoke subset. Nothing on screen contradicts the
claim, so the evaluator completes. This is the exact "subset narrated as all pass"
loophole the skill flags.

Two root causes:

1. **The end state doesn't pin scope.** "All tests pass" is treated as satisfied by
   any passing test run. It must name *the full suite* explicitly.
2. **The evidence signal is scope-blind.** `0 failed` says nothing about *how many*
   ran. A 12-test smoke run and a 900-test full run both print `0 failed`.

## Fixes applied

- **Pin scope in the end state** — "the full test suite" and require the *exact*
  invocation `npm test` with **no path filter, pattern flag, or file argument**.
- **Make scope visible in the evidence** — require the printed command line AND the
  total counts (`Tests: N total`, `Test Suites: M total`), so a shrunken subset is
  self-evident on screen. A filtered run shows the filter and a smaller total.
- **Guardrail the gaming vectors** — no `--testPathPattern` / `-t` / path args, no
  `.only` / `.skip` / `xit` / `describe.skip`, and no edits to test files or Jest
  config (so the suite can't be quietly narrowed instead of fixed).
- **Keep your 15-turn stop clause**, plus a stall trigger and a blocker summary.

## Ready to paste

```
/goal The FULL test suite passes — not a subset. Prove it by, in the most recent turn, running the whole suite with exactly `npm test` (no path argument, no --testPathPattern, no -t, no file filter) and pasting its output. The output must show the invoked command line (so any filter is visible), a summary reporting 0 failed, and the totals `Test Suites: M total` and `Tests: N total` reflecting the whole repo — a shrunken count means the suite was narrowed, which does not count as done. Constraints: do not add any test-path/pattern filter; do not edit files under test directories or the Jest/test config; do not use .only, .skip, xit, or describe.skip to hide tests. Stop after 15 turns, or if the passing count stops improving for 2 turns — then summarize what's still failing and why.
```

Note on the command: I assumed the whole suite runs as a bare `npm test` (the
Jest/npm default). If your repo's full-suite command differs — e.g. `npm run
test:all`, `npm test -- --ci`, or a `Makefile`/CI target — swap it in and, if you
know the real suite size, replace `M total` / `N total` with the expected numbers
so a subset can't match. The CI test step is the authoritative "what green means."

One operational reminder: goals that run shell commands pause on approval prompts
unless you're in `acceptEdits` or `bypassPermissions` mode.
