#!/usr/bin/env bash
# check-skill-metadata.sh
#
# Pure validator (no provider, no network):
#   1. goal-draft-policy/SKILL.md has YAML frontmatter with non-empty `name:`
#      and `description:` fields (what makes a Claude Code skill loadable).
#   2. Every tracked/untracked *.json file parses as valid JSON.
#
# Exit 0 = all good; 1 = a problem was found.

set -u
cd "$(git rev-parse --show-toplevel)" || { echo "not a git repo" >&2; exit 2; }

fail=0
SKILL="goal-draft-policy/SKILL.md"

echo "== Skill frontmatter check =="
if [ ! -f "$SKILL" ]; then
  echo "  [FAIL] $SKILL not found"
  fail=1
else
  # Frontmatter must open on line 1 with '---'.
  if [ "$(sed -n '1p' "$SKILL")" != "---" ]; then
    echo "  [FAIL] $SKILL: no YAML frontmatter opening '---' on line 1"
    fail=1
  else
    # Extract the frontmatter block (between the first two '---' lines).
    fm="$(awk 'NR==1{next} /^---[[:space:]]*$/{exit} {print}' "$SKILL")"
    for key in name description; do
      # key present and followed by a non-empty value (value may be on the same
      # line or, for description, a folded '>-' block on following lines).
      if ! printf '%s\n' "$fm" | grep -qE "^${key}:[[:space:]]*\S"; then
        echo "  [FAIL] $SKILL frontmatter: '${key}:' missing or empty"
        fail=1
      fi
    done
    [ "$fail" -eq 0 ] && echo "  ok: name + description present"
  fi
fi

echo
echo "== JSON validity check =="
json_count=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  json_count=$((json_count + 1))
  if ! node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$f" 2>/dev/null; then
    echo "  [FAIL] invalid JSON: $f"
    fail=1
  fi
done < <(git ls-files -co --exclude-standard '*.json')
echo "  checked $json_count JSON file(s)"

echo
if [ "$fail" -ne 0 ]; then
  echo "== Result: FAIL =="
  exit 1
fi
echo "== Result: ok =="
exit 0
