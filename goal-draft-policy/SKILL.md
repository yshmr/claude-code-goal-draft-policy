---
name: goal-draft-policy
description: >-
  Author, critique, or repair a Claude Code `/goal` completion condition — the
  autonomous loop where Claude keeps working across turns until a condition is
  met. Use this whenever the user wants to set a goal, "let Claude run until X is
  done", write or fix a `/goal` condition, run a long autonomous task with a
  verifiable end state, or asks why their goal isn't completing (or is completing
  too early). Trigger even if the user doesn't say the word "goal" — e.g. "keep
  going until all tests pass without me approving each step", "make Claude finish
  this migration on its own", "have it loop until the build is clean". Produces a
  ready-to-paste `/goal ...` line, not prose.
---

# Crafting effective `/goal` conditions

## Ground truth: the official docs

This skill is grounded in Claude Code's official `/goal` documentation, distilled
in **`references/official-goal-reference.md`** (source:
<https://code.claude.com/docs/en/goal>). Read that file first when you need exact
behavior — version requirement (v2.1.139+), how the evaluator works, the `/goal` /
`/goal clear` / status subcommands, resume behavior, and when `/goal` is
unavailable. Everything below is the *authoring method* built on top of those
facts; if the two ever disagree, the reference (and a fresh fetch of the URL) wins.

The official guidance for a good condition names three things: **one measurable
end state**, **a stated check** (how Claude proves it), and **constraints that
matter**. The 5-element structure in this skill is those three, operationalized —
it splits "stated check" into the *command* and the *evidence signal* so the
transcript-only evaluator has something concrete to read, and adds an explicit
stop clause because the docs recommend bounding a goal with a turn/time clause.

### Provenance labels

There is **no official Anthropic skill** for authoring `/goal` conditions — the
only official material is the documentation above. So this skill mixes documented
facts with a synthesized method. Each section is tagged so you know how much to
trust it:

- **[official]** — stated in the docs / `references/official-goal-reference.md`.
  Safe to rely on.
- **[method]** — this skill's synthesis, built on official facts but not itself
  official. Sound practice, but a convention, not a rule from Anthropic.
- **[inference]** — a plausible deduction from official facts that the docs do
  **not** confirm. Use it, but hold it loosely; if behavior contradicts it,
  believe the behavior.
- **[tested]** — a claim checked by a small experiment in
  `references/evaluator-behavior-tests.md`. Stronger than [inference] but not
  official; the probe uses a reconstructed evaluator and small samples, so it's a
  strong hint, not proof.

## What this skill is for

`/goal <condition>` puts Claude in an autonomous loop: after each turn a small
fast evaluator model (Haiku by default) reads the condition plus the whole
conversation and decides yes/no. "No" starts another turn; "yes" clears the goal.

Your job is to turn a rough intent ("keep going until the tests pass") into a
condition that the evaluator can judge **correctly and only when actually true**.
A vague condition either never completes (burning turns) or completes falsely
(Claude claims victory and the evaluator believes it). Both waste the user's
time and money, so the phrasing genuinely matters.

## The one constraint that drives everything

**The evaluator does not run tools** — **[official]**. It cannot run tests, read
files, or check git; it only judges what has already been surfaced as text in the
conversation. Three consequences follow:

1. **Verifiable from the transcript** — **[official]**. The docs state the check
   must be something "Claude's own output can demonstrate". The proof has to land
   on screen — a command's output, a grep count, an exit code. If a human couldn't
   confirm the condition by reading the transcript, neither can the evaluator.
2. **Surface fresh evidence every turn** — **[tested]**. We probed the obvious
   worry — that a success printed in an early turn gets re-counted and
   false-completes the goal — and it did **not** happen: given tests that passed
   before a later un-verified change, the evaluator returned "no" in 4/4 samples,
   each time noting the passing result predates the change (see
   `references/evaluator-behavior-tests.md`). The evaluator tracks recency itself.
   The real consequence is the mirror image: after any change, if Claude doesn't
   re-run the check in the current turn, the evaluator (correctly) refuses to
   complete and the loop stalls. So write the proof as something Claude re-produces
   each turn ("in the most recent turn, run X …") — a directive to keep fresh
   evidence flowing, not insurance against a re-count bug.
3. **No subjective criteria** — **[official]**. The docs warn against conditions
   with "no point where 'messy' objectively becomes 'clean'". Replace "works",
   "clean", "looks good", "fast" with an operational definition: an exit code, a
   count, a specific string in the output.

## The 5-element structure — [method]

This structure is this skill's own framework (see the provenance note): it expands
the official three-part guidance so a transcript-only evaluator has something
concrete to read. Assemble every condition from these parts. Not all are always
needed, but end state + proof + evidence are mandatory — they are what makes it
judgeable.

| # | Element | Question it answers | Example fragment |
|---|---------|---------------------|------------------|
| 1 | **End state** | What is true when done? | "every test in `tests/auth` passes" |
| 2 | **Proof action** | What command must Claude run? | "run `pytest tests/auth -q`" |
| 3 | **Evidence signal** | What must appear in the output? | "the final line shows `0 failed`" |
| 4 | **Guardrail** | What must not change on the way? | "do not modify or delete any file under `tests/` — show `git diff --stat` each turn to prove it" |
| 5 | **Stop clause** | When to give up? | "stop after 15 turns, or if the same error repeats twice — then summarize what's blocking" |

Elements 1–3 make it *judgeable*, 4 protects *quality*, 5 protects against
*runaway* when the goal is impossible. Always include a stop clause: the
evaluator has no other brake.

## How the conversion works — [method]

Converting a rough request into a condition is a **mapping**: each slot has a
derivation rule you apply to the user's words plus the repository. The `Workflow`
section below is the execution checklist; this section is the reasoning behind
each slot, so you produce the same quality every time instead of paraphrasing the
user's sentence. Apply the rules in order.

### Per-slot derivation rules

- **① End state ← the user's intent, promoted to an observable state.** Take the
  verb/object of the request and restate it as something true-or-false. "fix
  auth" describes an action, not a finish line — promote it to "every test in
  `tests/auth` passes". If a subjective word appears ("clean", "small", "fast"),
  replace it *here* with a number or boolean — but only when a conventional
  default the user would recognize exists (clean→"0 lint warnings",
  small→"each file ≤ 300 lines"). If there is no such canonical metric
  ("readable", "nicer", "understandable to non-engineers"), your reply IS the
  question: ask which single criterion decides success, and do not draft the
  `/goal` until the user answers. Shipping a proxy you picked with an "adjust
  if this is wrong" note is still guessing (see branching below).

- **② Proof command ← inspect the repo for a command that actually exists.** This
  is the load-bearing step: a condition naming a command the project lacks never
  completes. Resolve it from the repo, not from habit (the `Workflow` step 2 lists
  where to look — package scripts, `pyproject`/`Makefile`, `Cargo`/Go, and CI
  config as the canonical "what green means"). Choose the command whose output
  carries a **stable, greppable signal every turn**.

- **③ Evidence signal ← the concrete output that command emits on success.** Read
  it off the command type using the table below. Prefer a signal that a chatty
  summary can't fake — an actual pasted command tail over "I confirmed it passes".
  **Probed:** the evaluator showed some vocabulary slack — a genuinely green
  Vitest run completed a condition demanding the literal `0 failed` in 4/4
  samples even though Vitest never prints that string. Don't lean on the slack:
  name the runner's real summary format so completion never depends on the
  evaluator's generosity.

  | Command type | Success signal to require in the transcript |
  |--------------|---------------------------------------------|
  | Test runner (pytest/jest/go test/…) | the summary line shows `0 failed` (or the passing count); when the full-suite size is known, also require the total (e.g. `87 total`) so a subset run can't satisfy it |
  | Build / typecheck | `exit code 0` and zero errors in the output |
  | Linter | `0 problems` / `0 errors` |
  | grep / rg (absence check) | a printed count of `0` (e.g. pipe the match list through `wc -l`) — bare `rg` prints nothing on zero matches, and empty output is weak evidence |
  | git cleanliness | `git status --short` prints nothing |
  | Queue / backlog | the listing command prints an empty list |

- **④ Guardrail ← what the task type implies must not change.** Infer from
  context even when unstated: test-modifying tasks → "don't edit test files" (so
  Claude can't "pass" by weakening tests); refactors → "public exports unchanged";
  migrations → "don't touch unrelated modules or dependencies". **Make the
  guardrail checkable by default — [tested]:** the evaluator enforces a guardrail
  only when evidence is on screen. In probes it caught a violation that Claude
  narrated (4/4 refusals), a compliant run with no compliance evidence still
  completed (4/4) — and a *silent* violation is invisible by construction. So
  require the evidence: "each turn show `git diff --stat`; it touches only
  `src/x/`" turns the guardrail from a promise into something the evaluator can
  actually check. A follow-up probe confirmed the mechanism: with the diff
  required, a `git diff --stat` listing a `tests/` file was refused 4/4 even
  while the narration claimed compliance, and 4/4 when the narration said
  nothing — the evaluator reads the evidence, not the claim.

- **⑤ Stop clause ← a default bound plus a no-progress trigger.** Always add a
  turn cap; add a stall detector when the task can get stuck ("same failure twice",
  "test count doesn't improve for 2 turns"), and tell Claude to summarize the
  blocker on stop so the user learns why. **Write the clause as an OR-branch of
  the condition, never a free-standing sentence — [tested]:** as its own sentence
  ("… show 0 failed. Stop after 5 turns.") the cap completed nothing (0/4 even
  with turn numbers and a blocker summary on screen); joined as ", or stop after
  5 turns" the same transcript completed 4/4, and the evaluator honored the
  cap even with no stated turn numbers (3/4) — still, have the condition require
  stating "turn k of N" each turn: cheap insurance against the one-in-four
  refusal, now part of the template. Note the mechanics of "then summarize the
  blocker": in probes the evaluator withheld completion until the summary
  actually appeared (4/4 refusals without it), so expect one final summarizing
  turn after the cap — that is the clause doing its job. The no-progress
  trigger fires too — [tested]: with an identical failure on screen three
  turns running, ", or if the same test failure recurs twice" completed the
  goal even with no self-announcement (3/4, 4/4 when announced), and did not
  fire while the failures were still changing (0/4 completions there) —
  announce the repetition anyway to keep the evidence unambiguous.
  Time-based caps need an on-screen clock — [tested]: "or stop after 2 hours"
  completed 4/4 when the transcript stated the start time, per-turn clock
  times, and that the cap was exceeded, but 0/4 with no time information at
  all (nothing timestamps a transcript by itself). If the user insists on a
  wall-clock bound, require Claude to print the elapsed time each turn;
  otherwise convert it to a turn cap.

### The latest-turn anchor — [tested]

After filling ② and ③, phrase them as **"in the most recent turn, run X and show
…"**. We first added this to stop an old success from being re-counted, but a probe
(`references/evaluator-behavior-tests.md`) showed the evaluator already guards
against that — it wants proof that post-dates the last change. So the anchor's real
job is the reverse: it keeps Claude *producing* fresh proof every turn, so the loop
terminates instead of stalling on "you changed code but didn't re-verify". Keep it
— it's cheap and it aligns Claude with what the evaluator actually demands. The
feared subset gap did **not** reproduce in a probe (0/4 completions for a filtered
run narrated as "all pass", whether or not the condition pinned the command — see
`references/evaluator-behavior-tests.md`), but the sample is small and the defense
is cheap: still pin the scope in ①, name the exact unfiltered command in ②, and
when the suite size is known, require the visible total in ③.

### Worked trace

Input (raw user sentence):
> "utils.ts got too big — split it up and keep each file small."

| Step | Rule applied | Result |
|------|--------------|--------|
| ① | promote "small" to a number — a line budget is a conventional default, so assuming one is allowed (a word with no such default must be asked instead; see branching) | "each `.ts` under `src/` ≤ 300 lines" |
| ② | no external command needed; a line-count listing is self-evident | show a `wc -l`-style listing of over-budget files |
| ③ | success = nothing over budget | the listing is empty |
| ④ | splitting easily breaks the public API | "keep `src/index.ts` exports unchanged" |
| ⑤ | default turn cap | "stop after 20 turns" |
| anchor | inject latest-turn clause | "each turn, show …" |

Output (ready to paste):
```
/goal No .ts file under src/ exceeds 300 lines. Prove it each turn by showing a
line-count listing of files over the budget (empty when done) — or stop after
20 turns. Keep the exports in src/index.ts unchanged. State the turn number
each turn.
```

### Branching when the input is ambiguous

- **① won't reduce to something measurable** ("make it nicer") → deliver the
  question, not a `/goal`: ask the user for the one metric that decides success
  (offering 2–3 measurable candidate criteria to choose from is fine) and write
  the condition only after they answer. Don't invent a proxy — a fully drafted
  `/goal` on a self-picked proxy plus "adjust if needed" violates this rule.
- **② has several candidate commands** (multiple test scripts) → treat CI config
  as authoritative; if none, pick the most comprehensive and note the choice in
  your presented result so the user can correct it.
- **No repo / empty or fresh folder** → there is no command to run, so switch ③ to
  an artifact-based signal: a file exists, or its content contains a specific
  string Claude prints back. Everything else in the mapping is unchanged.

## Copy-paste template — [method]

```
/goal <end state>. Prove it by, in the most recent turn, running <command> and
showing its output contains <exact signal> — or stop after <N> turns or if
<no-progress signal>, then summarize the blocker. Constraints: <what must not
change>. State the turn number each turn.
```

## Workflow — [method]

When the user asks for a goal, don't just wrap their sentence in `/goal`. Do this:

1. **Extract the real end state.** Ask (or infer) what "done" concretely means.
   If it's fuzzy ("clean up the module"), pin it to something measurable (a line
   budget, no lint warnings, a passing test) before writing anything. If no
   conventional metric exists for the user's word, stop at this step: reply with
   the one question that decides success instead of a `/goal` (①'s branching
   rule).

2. **Find the real verification command by inspecting the repo.** Don't guess
   `npm test` — look. This is where the skill earns its keep, because a condition
   that names a command the project doesn't have will never complete. Check, in
   rough priority order:
   - `package.json` → `scripts` (test/build/lint/typecheck), and the lockfile to
     know the runner (npm/pnpm/yarn/bun)
   - Python: `pyproject.toml` / `pytest.ini` / `tox.ini` / `noxfile.py`, `Makefile`
   - Rust `Cargo.toml` (`cargo test`, `cargo build`, `cargo clippy`), Go
     (`go test ./...`, `go build ./...`), Gradle/Maven, `Makefile`, `justfile`
   - CI config (`.github/workflows`, `.gitlab-ci.yml`) — the canonical "what green
     means" for this repo, often the best source of the exact command
   - For "no matches" style goals, prefer a `grep -rn`/`rg` count the user can see
   - Verify the *tools* the proof relies on actually exist in the environment
     (`rg`, `gh`, `jq`, `wc`, …); if one is missing, fall back to an available
     equivalent (`grep -rc`, `git log`, a shell loop) — a proof command that
     cannot run never completes
   Pick the command that produces a **stable, greppable signal** every turn
   (exit code, a summary line, a match count).

3. **Choose the evidence signal precisely.** Tie it to that command's real
   output: `exit code 0`, `0 failed`, `0 problems`, `no matches`,
   `git status --short` empty. Prefer signals that can't be faked by a chatty
   summary — an actual pasted command tail beats "I confirmed it passes".

4. **Add guardrails from context.** Anything the user would be upset to see
   changed: test files, public API/exports, generated code, unrelated modules,
   dependencies. Where useful, make the guardrail itself checkable
   ("show `git diff --stat`; it touches only `src/parser/`").

5. **Add a stop clause.** A turn cap (`stop after N turns`) and/or a no-progress
   trigger (`if the same failure recurs twice`, `if no test count improves for
   2 turns`). Then instruct Claude to summarize the blocker so the user learns
   why it stopped, and to state the turn number each turn ("turn k of N") so the
   cap is trivially countable.

6. **Present the result** as a single fenced `/goal ...` block, ready to paste,
   followed by 1–2 lines naming which verification command you chose and why. If
   auto-approval matters (goals that run shell commands stop on approval prompts
   unless the user is in `acceptEdits`/`bypassPermissions`), mention it briefly.
   The condition can be up to **4,000 characters** — long enough to inline a small
   acceptance checklist as multiple AND'd clauses when the task warrants it.
   AND'd checklists held up in probes (0/4 completions with one check missing —
   [tested]), but the evaluator wanted every check visible in the current turn:
   checks spread across earlier no-edit turns were refused (1/4 completions).
   For checklist goals, tell Claude to re-run the full checklist in the final
   turn.
   The condition may be written in the user's language — a probe showed the
   evaluator judged Japanese conditions correctly, including recency ([tested],
   see `references/evaluator-behavior-tests.md`) — but keep command names, paths,
   and output signals verbatim (e.g. `87 passed, 87 total`), since those must
   match the transcript exactly.

## Critique / repair mode — [method]

If the user hands you an existing goal string ("why won't this complete?" / "fix
this goal"), diagnose it against the constraint and the 5 elements. Check for:

- **Unjudgeable from transcript** — needs the evaluator to run something itself,
  or references file state Claude never prints. → add an explicit proof command.
- **No fresh-proof directive** — nothing makes Claude re-run the check after each
  change. Per the probe (`references/evaluator-behavior-tests.md`) the evaluator
  already discounts successes that predate the last change, so the real failure
  is a stalled loop ("changed code, never re-verified"), not a re-counted stale
  win. → require the proof "in the most recent turn" and pin the scope.
- **Scope-gameable** — the proof command/scope isn't pinned, so a filtered or
  subset run satisfies the letter of the condition. → pin the exact unfiltered
  invocation and, when the suite size is known, require the visible total count.
- **Subjective terms** — "clean", "properly", "works". → operationalize.
- **Missing stop clause** — can loop forever if impossible. → add a bound.
- **Stop clause detached from the condition** — written as a free-standing
  sentence ("… 0 failed. Stop after 15 turns."), which the evaluator does not
  treat as a way to complete the goal, so the loop outlives its cap — [tested].
  → join it to the main condition with ", or stop after N turns".
- **Wall-clock stop clause** — "stop after 2 hours": the transcript has no
  clock, so the clause is judgeable only if Claude prints elapsed time each
  turn — [tested]. → convert to a turn cap, or require an elapsed-time line
  each turn.
- **Wrong/imaginary command** — names a script the repo lacks. → replace with the
  real one (inspect the repo).
- **Self-report loophole** — completes on Claude *saying* it's done. → require the
  actual command output to appear.

Output the repaired `/goal ...` line plus a short bullet list of what you changed
and why, so the user learns the pattern rather than just getting a fix.

## Worked examples — [method]

The use-case *categories* (migration, backlog, splitting a large file) are drawn
from the official docs; the exact condition strings below are this skill's.

**Test-driven**
```
/goal Every test under tests/auth passes. Prove it by, in the most recent turn,
running `pytest tests/auth -q` and showing the summary line reports 0 failed —
or stop after 15 turns or if the same failure recurs twice, then summarize the
blocker. Do not modify or delete any file under tests/ — show `git diff --stat`
each turn to prove it. State the turn number each turn.
```

**Build + typecheck**
```
/goal `npm run build` completes with exit code 0 and no TypeScript errors, shown
in the most recent turn's output — or stop after 10 turns. Do not modify files
under src/generated/. State the turn number each turn.
```

**Exhaustive API migration**
```
/goal No call sites of oldApi( remain in src/. Prove it in the most recent turn
by running `rg -n "oldApi\(" src/ | wc -l` and showing it prints 0, plus
`npm test` (exit 0) — or stop after 25 turns or if the printed count doesn't
drop for 2 turns, then report what's left. Keep the public exports in
src/index.ts unchanged. State the turn number each turn.
```

**Backlog / queue drain**
```
/goal Every issue labeled goal-batch is closed, each with a fix. Each turn run
`gh issue list --label goal-batch --state open --json number --jq length` and
show the printed count; done when it prints 0 — or stop after 30 turns. Do not
close an issue without a merged fix (commit or PR) that addresses it — closing
without a fix does not count. State the turn number each turn.
```

**File-size refactor**
```
/goal No .ts file under src/ exceeds 300 lines. Prove it each turn by showing a
line-count listing of files over the budget (empty when done) — or stop after
20 turns. Keep the exports in src/index.ts unchanged. State the turn number
each turn.
```

## Anti-patterns (reject or rewrite these) — [method]

- `/goal make the code better` — no end state, no proof, no stop. Unjudgeable.
- `/goal until it works in production` — not observable in the transcript.
- `/goal when the tests pass` — no proof command named and no fresh-proof
  directive: nothing makes Claude re-run the tests after each change (the loop
  stalls on unverified state), and the scope is unpinned — a subset run narrated
  as "tests pass" could satisfy it.
- `/goal fix all the bugs` — unbounded and subjective; will loop or false-complete.

Rewrite each into the 5-element form before handing it back.
