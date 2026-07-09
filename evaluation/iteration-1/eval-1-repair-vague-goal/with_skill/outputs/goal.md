# Why `/goal make the code clean and fast` never finishes

After every turn, a small evaluator model re-reads your condition plus the whole
conversation and answers yes/no — and it **cannot run tools**. It only judges
what is already visible as text in the transcript. Your condition gives it
nothing it can ever score as "yes," so it returns "no" forever and the loop
burns turns indefinitely.

Concretely, it breaks all three mandatory requirements:

- **No measurable end state.** "Clean" and "fast" are subjective — there is no
  point where messy objectively becomes clean or slow becomes fast. The
  evaluator can't decide it's true, so it never will.
- **No proof action / evidence signal.** No command is named and no output is
  required, so there's nothing on screen for the evaluator to read as success.
- **No stop clause.** Even when it can't complete, nothing bounds the loop — so
  it just keeps going, which is exactly what you saw.

The fix is to replace each vague word with an operational definition (a number,
an exit code, a specific string), name the command that proves it, require that
command's output to appear each turn, and add a turn cap.

## Repaired `/goal` line (ready to paste)

```
/goal The code passes lint and type checks with zero problems, all tests pass, and no benchmarked hot path is slower than its baseline. Prove it by, in the most recent turn, running the project's lint/format check (0 problems), its type check (exit code 0), its test suite (summary line shows 0 failed), and the benchmark command (each result at or below its recorded baseline) — and showing each command's output. Constraints: do not edit or delete tests to make them pass, and do not change public exports. Stop after 20 turns, or if the same failure recurs twice — then summarize what's blocking.
```

Swap the generic commands above for the ones this repo actually defines
(check `package.json` scripts, `pyproject.toml`/`Makefile`, `Cargo.toml`, or the
CI config for the canonical "green" commands and the real benchmark). "Fast"
only becomes judgeable if a benchmark with recorded baselines exists — if it
doesn't, either add one first or drop the speed clause and pursue performance
outside the loop, because the evaluator can't score "fast" without numbers to
compare.

Note: goals that run shell commands will pause on approval prompts unless you're
in `acceptEdits` or `bypassPermissions` mode.
