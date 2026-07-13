#!/usr/bin/env bash
# check-markdown-links.sh
#
# Pure validator: every RELATIVE markdown link in a tracked .md file must point
# at a path that exists in the repo. Catches renamed/moved/typo'd links so a
# third party never hits a 404 inside the docs.
#
# Scope: publishable .md files (tracked + untracked, minus ignored). External
# links (http/https/mailto), pure anchors (#section), and autolinks are skipped
# — this checks repo-local targets only, so it needs no network (pure CI).
#
# Exit 0 = all relative links resolve; 1 = at least one broken link.

set -u
cd "$(git rev-parse --show-toplevel)" || { echo "not a git repo" >&2; exit 2; }

pairs="$(mktemp)"
trap 'rm -f "$pairs"' EXIT

# Build a "<mdfile>\t<target>" list first, so the resolution loop runs in the
# main shell (no pipe subshell swallowing counters).
while IFS= read -r md; do
  # grep the working-tree file directly (covers untracked-but-not-ignored files
  # that git grep would miss).
  grep -hoE '\]\([^)]+\)' -- "$md" 2>/dev/null \
  | sed -E 's/^\]\(//; s/\)$//' \
  | while IFS= read -r target; do
      printf '%s\t%s\n' "$md" "$target"
    done
done < <(git ls-files -co --exclude-standard '*.md') >> "$pairs"

broken=0
checked=0

while IFS="$(printf '\t')" read -r md target; do
  case "$target" in
    http://*|https://*|mailto:*|tel:*|\#*|\<*|"") continue ;;
  esac
  path="${target%%#*}"      # strip anchor
  path="${path%%\?*}"       # strip query
  [ -z "$path" ] && continue
  case "$path" in *"://"*) continue ;; esac   # any leftover URL scheme
  checked=$((checked + 1))
  resolved="$(dirname "$md")/$path"
  if [ ! -e "$resolved" ]; then
    echo "  [BROKEN] $md -> $target"
    broken=$((broken + 1))
  fi
done < "$pairs"

echo "== Markdown relative-link check =="
echo "   relative links checked: $checked"
echo "   broken: $broken"
if [ "$broken" -gt 0 ]; then
  echo "   -> fix the broken links above."
  exit 1
fi
echo "   -> all relative links resolve."
exit 0
