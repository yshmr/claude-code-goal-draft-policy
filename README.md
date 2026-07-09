# claude-code-goal-draft-policy

A [Claude Code](https://code.claude.com) **Skill** that helps you author, critique, and repair
`/goal` completion conditions — the conditions that drive Claude Code's autonomous
"keep working across turns until X is done" loop.

> **What is `/goal`?** `/goal <condition>` sets a completion condition; after each
> turn a small fast model checks whether it holds, and if not, Claude starts
> another turn on its own. It shipped in Claude Code **v2.1.139 (2026-05-11)**.
> Official docs: <https://code.claude.com/docs/en/goal>

## Why this exists

A vague condition either never completes (burning turns) or completes falsely
(Claude declares victory and the evaluator believes it). The load-bearing
constraint is that **the evaluator never runs tools — it only judges what Claude
has already surfaced as text in the conversation.** So a good condition must be
verifiable straight from the transcript.

This skill turns a rough request into a **ready-to-paste `/goal ...` line** built
from five elements:

1. **End state** — one measurable, true/false finish line
2. **Proof command** — a real command found by inspecting the repo (not guessed)
3. **Evidence signal** — the exact output that proves success (`0 failed`, `exit 0`, `no matches`, …)
4. **Guardrail** — what must not change on the way (e.g. don't edit test files)
5. **Stop clause** — a turn cap / no-progress trigger so an impossible goal can't run forever

It also **critiques and repairs** an existing goal ("why won't this complete?").

## Install

Copy the skill folder into your personal skills directory:

```bash
# macOS / Linux
cp -r goal-draft-policy ~/.claude/skills/

# Windows (PowerShell)
Copy-Item -Recurse goal-draft-policy $env:USERPROFILE\.claude\skills\
```

Then it triggers automatically when you ask for autonomous, verifiable-end-state
work, or invoke it directly with `/goal-draft-policy`. (Requires Claude Code with
Skills support; `/goal` itself needs v2.1.139+.)

## Provenance labels

Because the only official material on `/goal` is a single docs page (there is **no
official skill** for authoring conditions), `SKILL.md` separates fact from
synthesis and tags every section:

- **`[official]`** — stated in the docs (distilled in [`references/official-goal-reference.md`](goal-draft-policy/references/official-goal-reference.md))
- **`[method]`** — this skill's own synthesis on top of official facts
- **`[inference]`** — a deduction the docs do not confirm; hold loosely
- **`[tested]`** — checked by a small experiment (logged in [`references/evaluator-behavior-tests.md`](goal-draft-policy/references/evaluator-behavior-tests.md))

## Repository layout

```
goal-draft-policy/          the installable skill
  SKILL.md                  the authoring method (provenance-labeled)
  references/
    official-goal-reference.md    official /goal docs, distilled  [official]
    evaluator-behavior-tests.md   probe log behind the [tested] claims
  evals/evals.json          test cases

evaluation/                 how the skill was validated (transparency)
  iteration-1/              standard cases  — with-skill 100% vs no-skill 58%
  iteration-2/              trap cases      — with-skill 100% vs no-skill ~82%
  trigger-eval.json         20-query triggering set (with near-misses)
  desc-opt/trigger-results.md   triggering result + root-cause note
```

## Validation summary (and honest caveats)

The skill was measured, not just written:

- **Output quality** — spawned with-skill vs. no-skill runs on real fixtures. The
  skill scored **100%** across two iterations (including CI-vs-`package.json`
  disagreement, scope-inflation, and no-repo cases); the no-skill baseline
  reliably dropped the stop clause, latest-turn anchor, and guardrail — sometimes
  writing "do not stop until…", the exact runaway the tool is meant to prevent.
- **Triggering** — 3 independent judges scored the description **20/20** on a set
  with hard near-misses (`/loop`, Stop hooks, Agent SDK, OKRs, one-off runs).

Caveats, stated plainly: the triggering test is a **proxy** for the real
`available_skills` gate; the evaluator probes use a **reconstructed** evaluator
prompt with small sample sizes; and one iteration-2 baseline was partly
contaminated. Numbers are strong signals, not guarantees. (The official
`skill-creator` optimization loop could not produce numbers here due to a
Windows-portability bug — `select.select()` on a subprocess pipe; see the
root-cause note.)

## Disclaimer

Not affiliated with or endorsed by Anthropic. Built from public documentation and
the author's own experiments; the `[inference]`/`[tested]` parts are not official.
Verify against the [official docs](https://code.claude.com/docs/en/goal), which
win if they ever disagree.

## License

MIT — see [LICENSE](LICENSE).
