Here's a `/goal` for this — paste it to start the autonomous loop:

```
/goal Every package in this Go module (example.com/acme-tool) builds and its tests
pass. Prove it by, in the most recent turn, running `go test ./...` from the module
root and showing the output lists every package (internal/server, pkg/parser) as
`ok` with no `FAIL` line and no `[build failed]` — or stop after 15 turns or if the
same failure recurs twice, then summarize the blocker. Do not modify or delete any
`_test.go` file, and do not remove or skip any test case, to make failures go away
— show `git diff --stat` each turn to prove test files are untouched. State the
turn number each turn.
```

Why this shape:

- **Command**: `go test ./...` is the right proof command — I inspected the repo
  and it's a standard two-package module (`go.mod` → `example.com/acme-tool`,
  packages `internal/server` and `pkg/parser`), with no `Makefile` or CI config
  overriding the test invocation, so there's no ambiguity about which command
  "tests pass" means.
- **Evidence signal**: requiring both packages named as `ok` (not just "no FAIL
  anywhere") pins the scope so a subset run or a run from the wrong directory
  can't satisfy the condition.
- **Guardrail**: bars editing/deleting `_test.go` files or dropping test cases,
  with `git diff --stat` required each turn as visible proof — otherwise Claude
  could "pass" by weakening or deleting a failing test instead of fixing the code.
- **Stop clause**: a 15-turn cap plus a repeated-failure stall detector, joined
  to the main condition with "or" (not a separate sentence) so the evaluator
  actually treats it as a valid way to end the loop, with a blocker summary
  required so you learn what's stuck if it stops early.

One thing to flag: `go test ./...` is a shell command, so if this session isn't
running in `acceptEdits` or `bypassPermissions` mode, you'll still get a
permission prompt on the first run each turn. Switch modes if you want it to run
fully unattended.
