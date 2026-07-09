# goal-draft-policy — iteration-1 benchmark

Baseline = same task, same model, **no skill**. with_skill = the agent reads
SKILL.md + references first.

## Assertions & grading

### eval-0 author-goal-node-tests
| # | assertion | with_skill | baseline |
|---|-----------|:---:|:---:|
| 1 | proof command discovered from repo (test:auth / npm test) | ✅ `npm run test:auth` | ✅ `npm run test:auth` |
| 2 | latest-turn / fresh-evidence anchor | ✅ "in the most recent turn" | ❌ none |
| 3 | evidence signal (0 failed / exit 0) | ✅ 0 failed | ✅ exit 0 |
| 4 | guardrail (don't edit test files) | ✅ | ❌ none |
| 5 | stop clause (turn cap / bound) | ✅ 15 turns + repeat-failure | ❌ none |
| 6 | ready-to-paste `/goal` line | ✅ | ✅ |
| | **score** | **6/6** | **3/6** |

### eval-1 repair-vague-goal
| # | assertion | with_skill | baseline |
|---|-----------|:---:|:---:|
| 1 | diagnoses subjective / unverifiable-from-transcript | ✅ | ✅ |
| 2 | diagnoses missing bound / unbounded | ✅ | ✅ |
| 3 | states evaluator can't run tools (judges transcript) | ✅ | ❌ weak |
| 4 | repaired goal is measurable (lint/test/threshold) | ✅ | ✅ |
| 5 | repaired goal has a stop clause | ✅ 20 turns | ❌ "do not stop until…" |
| 6 | repaired goal has latest-turn anchor / proof cmd | ✅ | ❌ none |
| | **score** | **6/6** | **3/6** |

### eval-2 author-goal-python-migration
| # | assertion | with_skill | baseline |
|---|-----------|:---:|:---:|
| 1 | exhaustive end state (no query_raw call sites) | ✅ | ✅ |
| 2 | proof via grep/rg count (0 matches) | ✅ | ✅ |
| 3 | real test command from pyproject (pytest) | ✅ `pytest -q` | ✅ `pytest -q` |
| 4 | latest-turn anchor | ✅ | ❌ none |
| 5 | guardrail (tests / db.query signature / keep def) | ✅ | ⚠️ excludes def only |
| 6 | stop clause (turn cap / no-progress) | ✅ | ❌ "do not stop early" |
| 7 | rg pattern excludes the definition | ✅ `\.query_raw\(` | ✅ excludes def |
| | **score** | **7/7** | **5/7** |

## Totals

| config | pass rate | mean tokens | mean duration |
|--------|:---:|:---:|:---:|
| **with_skill** | **19/19 = 100%** | ~39.6k | ~46s |
| baseline (no skill) | 11/19 = 58% | ~32.9k | ~64s |

Per-run timing (tokens / ms):
- eval-0 with 40662 / 44873 · baseline 33705 / 81081
- eval-1 with 38046 / 36739 · baseline 31893 / 50891
- eval-2 with 39991 / 57424 · baseline 33181 / 60097

## Analyst notes

- **Where the skill adds value is narrow but consistent.** A strong base model
  already discovers the right command (test:auth, pytest) and writes an exhaustive
  end state — assertions 1/3/7 pass with or without the skill, so those aren't
  discriminating here. The skill's lift is concentrated in **three things the
  baseline reliably omits: the latest-turn anchor, an explicit test-editing
  guardrail, and a stop clause.**
- **Most striking: the baseline reproduces the exact bug the user complained about.**
  In eval-1 and eval-2 the no-skill version wrote "do not stop until…" — an
  *unbounded* condition — even in eval-1 where the whole complaint was "it never
  finishes." The skill never does this. This is the strongest evidence the skill
  is worth having.
- **Token overhead ~+20%** (reading SKILL.md + references) but **duration was
  lower** with the skill (clear procedure → faster convergence). Duration N=1 per
  cell is noisy; treat as indicative only.
- **The eval set may be too easy.** Baseline scored 58%, not near-zero, because
  the base model is already good at command discovery. A harder iteration-2 should
  target the skill's untested claims: (a) the scope-inflation trap (subset run
  narrated as "all pass"), (b) a repo where CI config disagrees with package.json
  scripts, (c) a truly no-repo/artifact-only goal.
