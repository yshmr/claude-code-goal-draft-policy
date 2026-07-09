# Evaluator behavior — small experiments

Claims in SKILL.md tagged **[tested]** are backed by the probes recorded here.
These are lightweight experiments, not authoritative benchmarks — read the caveats.

## How the probe works

The `/goal` evaluator is the configured small fast model (Haiku) judging
`condition + transcript` and returning yes/no + a reason (see
`official-goal-reference.md`). To probe its behavior we hand a Haiku instance the
same job: a completion condition plus a synthetic conversation transcript, asking
only for a yes/no decision and a one-line reason. No tools; pure judgment.

**Caveats (important):** the evaluator prompt used is a *reconstruction*, not
Anthropic's actual hidden prompt, so real `/goal` may differ. Sample sizes are
small and Haiku is non-deterministic. Treat results as strong hints, not proof.
Re-run and expand if a decision hinges on them.

## Experiment 1 — does stale evidence cause false completion?

**Question.** The worry (an [inference] at the time): because the evaluator sees
the whole history, a passing result printed in an early turn might get re-counted
after later code changes, falsely completing the goal. Is that real?

**Setup.** Condition: "All tests pass — `npm test` reports 0 failed." Transcript:
Turn 1 runs the suite and shows `0 failed`; Turn 2 refactors `login()` and does
**not** re-run the tests. Evaluate at the end of Turn 2. A false completion would
be a "yes".

**Result.** 4/4 samples returned **no**. Every reason independently noted that the
passing result predates the Turn 2 change and the current state is unverified,
e.g. "refactored code in Turn 2 without re-running the test suite". Companion
runs confirmed the evaluator also (correctly) said "no" when a later turn showed
`2 failed`, said "no" for an anchored condition with no fresh run, and said "yes"
only when the latest turn contained a fresh `0 failed`.

**Conclusion.** The stale-evidence false-completion did not reproduce. The
evaluator tracks recency on its own: it wants proof that post-dates the last
change. The practical consequence flips — the risk is not premature completion but
the **opposite**: if Claude changes code and doesn't re-verify in the current
turn, the evaluator keeps returning "no" and the loop stalls. So conditions should
push Claude to surface fresh proof every turn (the "in the most recent turn"
phrasing), which is why SKILL.md keeps that phrasing — as a directive to the
worker, not as insurance against a re-count bug.

**Not yet tested (open risks).** Scope inflation — an early run of a *subset*
(`npm test -- auth`, `0 failed`) later narrated as "all tests pass" without a full
run. That is a different failure mode (wrong scope, not stale timing) and may still
fool the evaluator; worth a future probe. Also untested: very long transcripts
where the fresh result is far from the end.
