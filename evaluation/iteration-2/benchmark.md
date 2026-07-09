# goal-draft-policy — iteration-2 benchmark (harder cases)

Targets the skill's untested claims: CI-vs-package.json disagreement,
scope-inflation hardening, and the no-repo artifact branch.

## Grading

### eval-3 ci-disagrees-with-package-json (clean comparison)
| # | assertion | with_skill | baseline |
|---|-----------|:---:|:---:|
| 1 | proof = CI canonical green (lint+typecheck+FULL jest), not `npm test` | ✅ | ✅ |
| 2 | notes `npm test` is only the unit subset | ✅ | ✅ |
| 3 | latest-turn anchor | ✅ | ❌ |
| 4 | guardrail (no editing tests / CI workflow) | ✅ | ✅ |
| 5 | stop clause | ✅ 20 turns + repeat | ❌ "keep working until…" |
| | **score** | **5/5** | **3/5** |

### eval-4 harden-against-scope-inflation
| # | assertion | with_skill | baseline |
|---|-----------|:---:|:---:|
| 1 | diagnoses unpinned command/scope → subset satisfies | ✅ | ✅ |
| 2 | pins exact full invocation, forbids filters | ✅ | ✅ |
| 3 | requires visible total count (subset detectable) | ✅ | ✅ |
| 4 | keeps latest-turn anchor + stop clause | ✅ | ✅ |
| | **score** | **4/4** | **4/4** |

### eval-5 no-repo-artifact-goal
| # | assertion | with_skill | baseline |
|---|-----------|:---:|:---:|
| 1 | artifact-based evidence, no invented test runner | ✅ | ✅ |
| 2 | fetches merged-PR list (`gh pr list --search merged`) | ✅ | ✅ |
| 3 | bullet-per-PR count comparison | ✅ | ✅ |
| 4 | re-fetch / latest-turn anchor | ✅ | ✅ |
| 5 | stop clause / failure handling | ✅ 15 turns + fail-stop | ⚠️ fail-stop, no turn cap |
| | **score** | **5/5** | **~4.5/5** |

## Totals

| config | pass rate | mean tokens | mean duration |
|--------|:---:|:---:|:---:|
| **with_skill** | **14/14 = 100%** | ~39.8k | ~43s |
| baseline | ~11.5/14 ≈ 82% | ~33.2k | ~64s |

## Analyst notes (honest)

- **The skill held at 100% even on the traps** — including the CI-vs-package.json
  mismatch and the scope-inflation dodge. Notably, the with_skill agent on eval-4
  explicitly cited "the 'subset narrated as all pass' loophole the skill warns
  about" — i.e. the residual-risk note added to SKILL.md after the earlier probe
  actually fired and was used. That validates that addition.
- **The gap narrowed vs iteration-1 (82% vs 58%) — partly a methodology flaw, own it.**
  For eval-4 and eval-5 the baseline *prompt* included the tool-blindness fact
  ("a small fast model … cannot run tools itself"), which handed the baseline the
  skill's single most important insight. Those two cells are therefore contaminated
  and shouldn't be read as clean wins/ties.
- **eval-3 is the clean comparison** (no leak into its baseline prompt) and there
  the skill won 5/5 vs 3/5 — the *same* failure mode as every iteration-1 authoring
  case: the baseline nails command discovery (even the CI trap) but drops the
  **latest-turn anchor and the stop clause**, and writes "keep working until…".
- **No skill defect surfaced.** The harder cases did not expose a gap in SKILL.md;
  they exercised its CI-authoritative rule, scope-pinning, and no-repo branch, all
  of which produced correct output. Recommendation: no content change needed.
- **Process fix for any future iteration:** keep the baseline prompt neutral — do
  not state the evaluator's tool-blindness in it, or the comparison is unfair.
