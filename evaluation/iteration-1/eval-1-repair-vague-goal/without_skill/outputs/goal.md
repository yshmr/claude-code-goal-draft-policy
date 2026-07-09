# Why `/goal make the code clean and fast` never finishes

## The core problem

`/goal` keeps Claude working turn after turn until a completion condition is
met, and after each turn a small, fast model checks: "Is the condition true
yet?" For that loop to ever stop, the condition has to be something the checker
can look at and answer **yes/no with certainty**.

"Make the code clean and fast" fails that test for three reasons:

1. **It's subjective, not verifiable.** "Clean" and "fast" have no fixed
   definition. There is no artifact the checker can inspect to prove the goal
   is reached. Faced with "is the code clean and fast?", a checker either
   always says "no" (you can always refactor a bit more or shave another
   millisecond) or answers inconsistently. Neither ever produces a stable
   "yes," so the loop runs forever.

2. **There's no terminal state.** These are open-ended quality dimensions, not
   a finish line. Unlike "tests pass" or "the file exists," there's no point
   at which cleaning or optimizing is objectively *done*. Every turn, Claude
   can find one more thing to improve, so it does — indefinitely.

3. **The scope is unbounded.** "The code" doesn't say which code, and there's
   no baseline or threshold. Even "faster" is meaningless without "faster than
   what, measured how."

In short: the goal describes a *direction to push in*, but `/goal` needs a
*condition that becomes true and stays true*. A good goal condition is a
checkpoint the loop can reach, not an ideal it can only approach.

## How to rewrite it

Turn each vague quality into a concrete, machine-checkable exit condition —
something with a command to run, a number to hit, or a file to produce. Anchor
"fast" to a measurement and a baseline; anchor "clean" to a linter/formatter or
a specific list of changes.

### Rewritten goal (drop-in)

```
/goal `npm run lint` and `npm test` both exit 0 with no warnings, and the
benchmark `npm run bench` reports the hot path at or under 200ms (currently
~850ms). Do not stop until all three hold.
```

Swap in whatever your project actually uses (`ruff`/`pytest`,
`cargo clippy`/`cargo test`, `eslint`, a specific benchmark script, etc.).

### If you don't have those tools wired up, be explicit instead

```
/goal Refactor src/report.py so that: (1) no function exceeds 40 lines,
(2) there are no duplicated blocks flagged by `ruff` and `ruff format` leaves
the file unchanged, and (3) `python bench_report.py` prints a runtime under
2.0s. Stop when all three are satisfied.
```

## The pattern to remember

A good `/goal` condition is:

- **Binary** — the checker can answer yes/no, not "sort of."
- **Observable** — tied to a command's exit code, a test result, a printed
  number, or a file's existence/contents.
- **Bounded** — names the specific files/scope and, for anything about speed
  or size, a concrete threshold plus the current baseline.

Rule of thumb: if *you* couldn't glance at the terminal output and say
"done — yes or no," the fast checker can't either, and the loop won't stop.
Keep the aspirational stuff ("clean," "fast") as your *intent*, but express the
*condition* as the measurable evidence that the intent was achieved.
