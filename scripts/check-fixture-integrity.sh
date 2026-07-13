#!/usr/bin/env bash
# check-fixture-integrity.sh
#
# Pure validator (no provider, offline): the evaluation fixtures that recorded
# results were produced against must not silently change. Each fixture file's
# git blob hash is pinned in evaluation/fixtures.manifest.sha256; this recomputes
# and compares. A mismatch means a fixture was edited after its results were
# recorded — regenerate the results deliberately, then refresh the manifest.
#
# Why git blob hashes (not sha256sum of the working tree): git stores content
# LF-normalized, so the blob hash is identical on Windows (CRLF checkout) and on
# Linux CI. A raw sha256sum of the working copy would differ across platforms.
#
# Usage:
#   bash scripts/check-fixture-integrity.sh          # verify against manifest
#   bash scripts/check-fixture-integrity.sh --write   # (re)generate the manifest
#
# Exit 0 = fixtures match the manifest; 1 = drift (or manifest missing on verify).

set -u
cd "$(git rev-parse --show-toplevel)" || { echo "not a git repo" >&2; exit 2; }

MANIFEST="evaluation/fixtures.manifest.sha256"
GLOB='*/fixtures/*'

# Emit "<blobhash>  <path>" for every tracked fixture file, sorted by path.
generate() {
  # git ls-files -s prints "<mode> <sha1> <stage>\t<path>"
  git ls-files -s "$GLOB" \
    | sed -E 's/^[0-7]+ ([0-9a-f]+) [0-9]+\t/\1  /' \
    | LC_ALL=C sort -k2
}

if [ "${1:-}" = "--write" ]; then
  generate > "$MANIFEST"
  echo "wrote $MANIFEST ($(wc -l < "$MANIFEST" | tr -d ' ') fixtures)"
  exit 0
fi

echo "== Fixture integrity check =="
if [ ! -f "$MANIFEST" ]; then
  echo "  [FAIL] $MANIFEST not found — run: bash scripts/check-fixture-integrity.sh --write"
  exit 1
fi

cur="$(mktemp)"; trap 'rm -f "$cur"' EXIT
generate > "$cur"

if diff -q "$MANIFEST" "$cur" >/dev/null 2>&1; then
  echo "   fixtures pinned: $(wc -l < "$MANIFEST" | tr -d ' ')"
  echo "   -> all fixtures match the manifest."
  exit 0
fi

echo "  [FAIL] fixture drift vs $MANIFEST:"
manifest_paths() { awk '{print $2}' "$MANIFEST" | LC_ALL=C sort; }
current_paths()  { awk '{print $2}' "$cur"      | LC_ALL=C sort; }
comm -23 <(manifest_paths) <(current_paths) | sed 's/^/        missing: /'
comm -13 <(manifest_paths) <(current_paths) | sed 's/^/        added:   /'
# changed = path in both, but blob hash differs
while IFS= read -r p; do
  m="$(awk -v p="$p" '$2==p {print $1}' "$MANIFEST")"
  c="$(awk -v p="$p" '$2==p {print $1}' "$cur")"
  [ "$m" != "$c" ] && echo "        changed: $p"
done < <(comm -12 <(manifest_paths) <(current_paths))
echo
echo "   -> if intended, regenerate results then: bash scripts/check-fixture-integrity.sh --write"
exit 1
