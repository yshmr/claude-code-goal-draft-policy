## Why it never finishes

`/goal` puts Claude into an autonomous loop: after every turn, a small fast model reads your condition plus the conversation and decides yes/no. Crucially, **that evaluator cannot run any tools** — it only judges what's already visible as text in the transcript. That means a condition has to satisfy three things or it will loop forever (or complete falsely):

1. **A measurable end state** — some observable fact that is either true or false.
2. **A proof command** — something Claude actually runs to demonstrate it.
3. **A concrete evidence signal** — specific output text the evaluator can check for.

`make the code clean and fast` fails all three:

- **"Clean" and "fast" are subjective.** There's no line in a transcript where "messy" objectively becomes "clean," or where the evaluator can tell "fast" from "not fast." Claude can always find one more thing to tidy, so the evaluator (correctly) keeps saying "not done yet."
- **No proof command is named.** Nothing tells Claude what to run to demonstrate cleanliness or speed (a linter? a benchmark? a line count?), so there's nothing consistent for the evaluator to look for turn over turn.
- **No stop clause.** Even if Claude eventually declared victory, there's no cap telling it (or the evaluator) when to give up if the goal turns out to be unreachable in these terms. This is exactly why it "just keeps running."

Also worth noting: this folder is currently empty, with no project files. If you intended to point `/goal` at a specific codebase, there's nothing here for a proof command to check yet — that alone would also stall the loop.

## How to rewrite it

Turn "clean and fast" into numbers/booleans, name a real command, and add a bound. Since there's no code in this folder to inspect yet, here's the pattern to use once you point it at an actual project — fill in the bracketed parts for your repo:

```
/goal Every file under src/ is <your line-count budget, e.g. ≤300 lines> and
`<your lint command, e.g. npm run lint>` reports 0 problems, and
`<your benchmark/test command>` completes with exit code 0. Prove it by, in the
most recent turn, running these commands and showing their output — or stop
after 15 turns or if the same failure recurs twice, then summarize the
blocker. Do not change public exports/behavior while refactoring — show
`git diff --stat` each turn to prove it. State the turn number each turn.
```

Steps to adapt this for your real project:

1. **Replace "clean"** with something countable: 0 lint warnings (`eslint`, `ruff`, etc.), a line-length budget per file, or a specific `git diff --stat` scope.
2. **Replace "fast"** with something you can actually measure and reproduce every turn: a benchmark script's output, a specific runtime threshold, or a bundle-size number — not a vague feeling. If you don't have a benchmark, either write one first or drop "fast" from the goal and handle performance separately.
3. **Name the real command** from your repo — check `package.json` scripts, `pyproject.toml`/`Makefile`, `Cargo.toml`, or your CI config for what "green" actually means in this project. A condition naming a command that doesn't exist will never complete.
4. **Add a stop clause joined to the condition** (not a separate sentence) — e.g. `, or stop after 15 turns` — so the loop has a hard bound even if the target proves unreachable.
5. **Add a guardrail** so cleanup doesn't silently break things — e.g. "keep all tests passing" or "don't change public APIs," backed by visible proof like a diff stat or test summary.

Once you have an actual project in this directory, tell me what language/tooling it uses and I can write you an exact, ready-to-paste `/goal` line with the real commands filled in.
