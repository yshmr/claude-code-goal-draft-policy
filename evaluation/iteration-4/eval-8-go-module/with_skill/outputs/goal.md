```
/goal Every package in this Go module's tests pass. Prove it by, in the most
recent turn, running `go test ./...` from the module root and showing it
exits 0 with an `ok` line for each of the module's packages
(example.com/acme-tool/internal/server and example.com/acme-tool/pkg/parser)
and no `FAIL` line anywhere in the output — or stop after 15 turns or if the
same test failure recurs twice, then summarize the blocker. Do not modify any
`_test.go` file to make tests pass — show `git diff --stat` each turn and
confirm it touches no `*_test.go` file. State the turn number each turn.
```

I inspected the module first: `go.mod` declares `example.com/acme-tool` (Go
1.22), with exactly two packages that have tests — `internal/server`
(`TestGreeting`) and `pkg/parser` (`TestParse`). There's no Makefile or CI
config, so the canonical "what green means" here is the standard, unfiltered
`go test ./...` from the repo root — that's the proof command.

Why the evidence signal is phrased this way: `go test` doesn't print a single
"0 failed" line the way pytest/jest do — success looks like one `ok` line per
package and failure adds a `FAIL` line, so the condition pins both: an `ok`
line naming each of the two known packages (so a partial/filtered run can't
satisfy it) and the absence of any `FAIL` line anywhere in the output.

Guardrail: since "make tests pass" is trivially gameable by weakening the
tests themselves, the condition requires proof (`git diff --stat`) that no
`_test.go` file was touched, not just a promise.

Stop clause: a 15-turn cap OR-attached to the main condition (a free-standing
sentence wouldn't be honored as a completion path), plus a stall trigger if
the same failure repeats twice, with a required blocker summary so you learn
why it stopped if it never gets there.

One thing to know: `/goal` loops through unattended turns, but if this session
isn't in auto-approve mode, shell commands like `go test` will still stop on
permission prompts each turn — turn on auto-approval (or accept-edits/bypass
mode) if you want it to run all the way to completion without you clicking
through.
