## Why it never finishes

`/goal` works by handing your condition plus the conversation-so-far to a small
fast model (Haiku) after every turn. That evaluator **never runs a tool** — it
only judges whatever text Claude has already printed. So a condition can stall
for two independent reasons here, and yours has both:

1. **"clean and fast" are subjective, not judgeable.** The evaluator needs a
   point where the condition becomes true-or-false — an exit code, a warning
   count, a benchmark number. "Clean" and "fast" have no such fixed point, so
   every turn Claude does *something* and the evaluator (correctly) can't
   confirm the condition holds, and says "no" again. That alone is enough to
   loop forever.

2. **There's no code here to begin with.** I checked the working directory
   (`evaluation/iteration-5/scratch-empty`) and it's empty — no repo, no
   source files, no lint config, no test runner, nothing to benchmark. Even if
   "clean and fast" were tightened to something measurable, there is currently
   no command Claude could run whose output would demonstrate it (no
   `eslint`, no `pytest`, no build). So the loop isn't just vague, it's
   pointed at nothing — Claude keeps "working" (writing code, presumably) but
   has no fixed target or verification command to show the evaluator, so it
   can never surface the proof that would let the goal clear.

## What I need before I can write a working condition

"Clean" has a conventional stand-in (0 lint warnings) once a linter exists,
but "fast" doesn't — there's no default speed target I can safely assume, and
there's no code yet to measure or optimize. Rather than draft a `/goal`
against a proxy I invented, tell me:

- **What should exist here?** (e.g., "write a CSV parser in Python," or point
  me at an existing project elsewhere if this folder was just the wrong
  target.)
- **What does "fast" mean for it?** e.g., a wall-clock budget on a specific
  benchmark ("parses a 100MB file in under 2s"), a Big-O requirement, or just
  "no obviously quadratic loops" — pick whichever you actually care about.
- **What does "clean" mean for it?** Usually the easiest to pin down: "0
  errors from `<linter>`" once you tell me the language (so I know which
  linter/formatter is idiomatic — ESLint, ruff, clippy, etc.).

## Once I know that, the condition will look like this

For example, if this turns out to be a Python module and "fast" means a
benchmark script:

```
/goal `ruff check .` reports 0 errors and running `python bench.py` prints an
elapsed time under 2.0s. Prove it by, in the most recent turn, running both
commands and showing their output — or stop after 15 turns or if the
benchmark time stops improving for 2 turns, then summarize the blocker. Do
not delete or skip any existing test to hit the target. State the turn number
each turn.
```

That's judgeable (0 errors, a printed number under a threshold), re-verified
every turn, and bounded — so it will actually clear instead of running
forever. Send me the two answers above (what to build/target, and what "fast"
means for it) and I'll fill in the exact commands.
