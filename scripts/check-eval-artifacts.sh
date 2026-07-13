#!/usr/bin/env bash
# check-eval-artifacts.sh
#
# Pure validator (no provider, offline): every 2026-07-or-later evaluation record
# must declare its provenance — subject/judge model, run date, and skill version
# (commit) — the discipline the project committed to for reproducibility. Older,
# model-unrecorded iterations (iteration-1, iteration-2 first run) are legacy and
# exempt (see evaluation/README.md).
#
# This does NOT re-score or re-run anything; it only checks that the required
# provenance fields are present as text in the record.
#
# Exit 0 = all recorded artifacts declare provenance; 1 = a field is missing.

set -u
cd "$(git rev-parse --show-toplevel)" || { echo "not a git repo" >&2; exit 2; }

# Records that must carry provenance. Add new 2026-07+ record roots here.
RECORDS=(
  "evaluation/iteration-3/benchmark.md"
  "evaluation/iteration-4/benchmark.md"
  "evaluation/iteration-5/benchmark.md"
  "evaluation/iteration-2-rerun/benchmark.md"
  "evaluation/e2e-2026-07/run-a-log.md"
  "evaluation/e2e-2026-07/run-b-log.md"
  "evaluation/e2e-2026-07/verdict.md"
  "evaluation/desc-opt/trigger-results-2026-07.md"
)

# Each field is an ERE; the record must match at least one.
model_re='claude-(sonnet|opus|haiku|fable)-[0-9]|sonnet|Haiku|subject model|judge'
date_re='2026-[0-9]{2}-[0-9]{2}'
skill_re='commit|[0-9a-f]{7}|skill version|Skill version'

fail=0
checked=0
for f in "${RECORDS[@]}"; do
  if [ ! -f "$f" ]; then
    echo "  [FAIL] listed record missing: $f"
    fail=1
    continue
  fi
  checked=$((checked + 1))
  missing=""
  grep -qE "$model_re" "$f" || missing="$missing model"
  grep -qE "$date_re"  "$f" || missing="$missing date"
  grep -qE "$skill_re" "$f" || missing="$missing skill-version"
  if [ -n "$missing" ]; then
    echo "  [FAIL] $f missing provenance:$missing"
    fail=1
  fi
done

echo "== Evaluation artifact provenance check =="
echo "   records checked: $checked"
if [ "$fail" -ne 0 ]; then
  echo "   -> add the missing provenance field(s), or move a legacy record out of the list."
  exit 1
fi
echo "   -> all recorded artifacts declare model + date + skill version."
exit 0
