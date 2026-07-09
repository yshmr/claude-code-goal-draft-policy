# Your `/goal`

Paste this into Claude Code:

```
/goal Every check that CI runs passes locally, matching .github/workflows/ci.yml exactly. CI does NOT use `npm test` (that script only runs the unit subset). The gate is these three commands, all exiting 0 from a clean install: (1) `npm ci`, (2) `npm run lint`, (3) `npm run typecheck`, (4) `npx jest --ci` for the FULL suite (tests/unit AND tests/integration). Keep working — fix lint errors, type errors, and failing tests in src/ and tests/ — until all four commands pass in one clean run. Do not edit the CI workflow, loosen lint/tsconfig rules, or skip/delete tests to force green.
```

## Why it's written this way

I inspected the repo before drafting, and there's a mismatch that would trip up a naively-worded goal:

- **`package.json` defines `"test": "jest tests/unit"`** — so `npm test` only runs the **unit** subset.
- **`.github/workflows/ci.yml` does not call `npm test` at all.** It runs, in order:
  1. `npm ci`
  2. `npm run lint`
  3. `npm run typecheck`
  4. `npx jest --ci` — the **full** suite (both `tests/unit` **and** `tests/integration`)

  The workflow even has a comment spelling this out: *"`npm test` only runs the unit subset. Green on main requires the full suite plus type and lint checks."*

If the goal condition were phrased as "make `npm test` pass" (the obvious reading of "what CI checks"), Claude could declare victory while the integration tests, lint, or typecheck are still red on the actual CI runner. So the completion condition above is pinned to the **CI commands themselves**, not the `test` script.

## Notes

- The `--- ` guardrails ("do not edit the CI workflow, loosen rules, or skip tests") keep Claude from gaming the condition — e.g. making CI green by deleting the check rather than fixing the code.
- If you'd rather verify against real CI instead of a local reproduction, you can swap the condition to something like: *"the latest CI run on this branch is green (`gh run list`/`gh run view` shows all jobs passed)."* The local version above is faster to iterate on and doesn't require pushing.
- Right now the source looks trivially correct, so the loop may just confirm green on the first pass — that's fine; the value is that it checks the *right* four things, not just `npm test`.
