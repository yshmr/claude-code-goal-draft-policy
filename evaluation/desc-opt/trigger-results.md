# Description triggering — result

The official `skill-creator` optimization loop (`run_loop.py`) could not run in
this environment. **Root cause: a Windows-portability bug in
`skill-creator/scripts/run_eval.py:108`**, which calls
`select.select([process.stdout], [], [], 1.0)` on the `claude -p` subprocess's
stdout **pipe**. On Unix `select()` accepts pipes; on Windows the `select` module
accepts only sockets, so a pipe raises `OSError: [WinError 10038]` (WSAENOTSOCK).
run_eval catches this per query and counts it as "not triggered", so every query
failed and the loop reported recall 0% — an artifact of the tooling, not the
description. It is NOT an auth/nesting problem (`claude -p "PONG"` works directly),
not the background sandbox, and not the parallelism; those were ruled out. (Two
earlier, separate hurdles — a cp932 decode error and a missing output dir — were
fixed with PYTHONUTF8=1 and mkdir before this fundamental blocker surfaced.)

Instead the current description was evaluated with a
controlled proxy: three independent judge subagents (session model) were shown the
description as the only available skill and asked to trigger / not-trigger on each
of 20 queries.

## Eval set
10 should-trigger (authoring/critiquing/repairing a `/goal` condition, including
three without the word "goal") + 10 should-not-trigger near-misses (`/loop`
scheduling, Stop hook, Agent SDK, OKRs, career goal, one-off "run now", `/goal`
explanation questions). See `../trigger-eval.json`.

## Result
All three judges unanimously scored **20/20 correct**: every should-trigger → yes,
every should-not-trigger → no. Precision 100%, recall 100%, accuracy 100%.

## Decision
**Keep the current description unchanged.** It already discriminates perfectly on
this set, including the hard near-misses. Rewriting a description that scores 100%
risks overfitting / regressing it.

## Caveats
- This is a proxy for the real `available_skills` triggering gate; the judges were
  given an explicit trigger/no-trigger instruction, which is easier than the
  ambient real-world gate. 100% here is a strong positive signal, not a guarantee.
- 20 queries is small; unanimous 100% may also mean the near-misses could be harder.
- Labeling `/goal` *explanation* questions (19, 20) as should-not-trigger is a
  deliberate design choice (this skill authors conditions; it doesn't exist to
  explain internals) — defensible but arguable.
