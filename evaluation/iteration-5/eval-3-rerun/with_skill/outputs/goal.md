I checked `.github/workflows/ci.yml` — that's the authoritative "what green means" for this repo, and it runs three checks: lint, typecheck, then the **full** Jest suite. Note the trap in the repo: `npm test` only runs `tests/unit` (per the comment in the workflow); CI actually uses `npx jest --ci`, which also picks up `tests/integration`. I pinned the goal to that full command so a unit-only run can't satisfy it. The suite currently has 2 tests total (1 unit + 1 integration), so I required that count explicitly.

Here's the goal, ready to paste:

```
/goal All three CI checks from .github/workflows/ci.yml are green: lint, typecheck,
and the full Jest suite. Prove it in the most recent turn by running, in order:
(1) `npm run lint` and showing 0 problems/errors, (2) `npm run typecheck` and
showing it exits 0 with no TypeScript errors, (3) `npx jest --ci` (the full
suite — NOT `npm test`, which only runs tests/unit) and showing the summary
reports all tests passing with 2 total. Re-run and show all three checks
together in the final turn, even if some passed in an earlier turn — or stop
after 15 turns or if the same failure recurs twice, then summarize the
blocker. Do not modify or delete any file under tests/, and do not weaken
lint or typecheck config (e.g. no new eslint-disable or tsconfig loosening)
to force a pass — show `git diff --stat` each turn to prove the change stays
within src/. State the turn number each turn.
```

Why it's built this way:
- **Command**: taken straight from the CI workflow (lint → typecheck → `npx jest --ci`), not from `npm test`, which is a subset trap in this repo.
- **Evidence**: each check's real success signal (0 problems, exit 0, passing summary) plus the known total test count (2) so a partial run can't pass silently.
- **Guardrail**: blocks weakening tests or lint/typecheck config to fake green, and requires `git diff --stat` each turn so the constraint is checkable, not just narrated.
- **Stop clause**: turn cap + stall detector, joined to the condition with "or" (a free-standing sentence doesn't reliably stop the loop), with a required blocker summary.
- One thing to flag: since `/goal` runs shell commands autonomously, auto-approval needs to be on (`acceptEdits`/`bypassPermissions`) or it'll stall on permission prompts.
