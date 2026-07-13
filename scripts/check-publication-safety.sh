#!/usr/bin/env bash
# check-publication-safety.sh
#
# Repository publication-safety scanner. Greps the *tracked* files of this repo
# for content that must not appear in a public repository:
#   - secrets (API keys, tokens, private keys)
#   - local absolute paths / usernames / home directories
#   - personal email addresses
#   - session / task / thread / conversation UUIDs
#   - checkpoint DBs, local histories, raw JSONL transcripts
#
# It scans the publishable working set — tracked files PLUS untracked-but-not-
# ignored files (git grep --untracked) — so newly added, not-yet-committed files
# are checked too, while .gitignore'd paths (node_modules, scratch) are skipped.
# Runnable by hand before publishing and in CI.
#
# Exit codes:
#   0  clean (no FAIL findings; WARN findings may still print for manual review)
#   1  at least one FAIL finding, or --strict and at least one WARN finding
#
# Usage:
#   bash scripts/check-publication-safety.sh          # normal
#   bash scripts/check-publication-safety.sh --strict # treat WARN as failure
#
# NOTE: this is a heuristic net, not a proof of safety. A green run means the
# known patterns did not match; it does not certify the absence of every
# possible leak. The human checklist in docs/publication-safety.md still applies.

set -u

STRICT=0
[ "${1:-}" = "--strict" ] && STRICT=1

cd "$(git rev-parse --show-toplevel)" || {
  echo "not inside a git repository" >&2
  exit 2
}

fail_count=0
warn_count=0

# This scanner and its own checklist necessarily embed the detection tokens
# ($USERPROFILE, C:\Users\…, `session id:` examples, the regexes themselves), so
# they are excluded from the scan to avoid self-referential false positives.
# Everything else is scanned in full.
SELF_EXCLUDE=(
  ':(exclude)scripts/check-publication-safety.sh'
  ':(exclude)docs/publication-safety.md'
  ':(exclude).publication-safety-allowlist'
)

# Allowlist: known-safe hits (e.g. deliberately synthetic UUIDs in fixtures) that
# should not be reported. Each non-comment line is an ERE matched against the
# "path:line:content" hit; a hit matching any line is dropped. This is what makes
# --strict safe to run in CI — a legitimate synthetic UUID can be permitted
# explicitly instead of failing the build.
ALLOWLIST_FILE=".publication-safety-allowlist"
ALLOW_TMP="$(mktemp)"
trap 'rm -f "$ALLOW_TMP"' EXIT
if [ -f "$ALLOWLIST_FILE" ]; then
  grep -vE '^[[:space:]]*(#|$)' "$ALLOWLIST_FILE" > "$ALLOW_TMP" 2>/dev/null || true
fi

# Drop allowlisted lines from a set of hits read on stdin.
allow_filter() {
  if [ -s "$ALLOW_TMP" ]; then
    grep -vEf "$ALLOW_TMP"
  else
    cat
  fi
}

# git grep over the publishable working set. Returns 0 if matches printed.
scan() {
  # $1 = severity (FAIL|WARN), $2 = label, $3 = ERE pattern, rest = extra pathspecs
  local sev="$1" label="$2" pattern="$3"
  shift 3
  local hits
  hits="$(git grep --untracked -nEI "$pattern" -- . "${SELF_EXCLUDE[@]}" "$@" 2>/dev/null | allow_filter)" || hits=""
  if [ -n "$hits" ]; then
    echo "  [$sev] $label"
    echo "$hits" | sed 's/^/        /'
    echo
    if [ "$sev" = "FAIL" ]; then
      fail_count=$((fail_count + 1))
    else
      warn_count=$((warn_count + 1))
    fi
  fi
}

echo "== Repository publication-safety scan =="
echo "   scope: $(git ls-files -co --exclude-standard | wc -l | tr -d ' ') publishable files (tracked + untracked, minus ignored)"
echo

# --- FAIL categories: high confidence, must be zero before publishing --------

# Secrets. Private-key headers, common token prefixes, AWS keys, generic
# key/secret assignments with a value.
scan FAIL "secrets / tokens / private keys" \
  '(sk-[A-Za-z0-9]{20})|(ghp_[A-Za-z0-9]{20})|(github_pat_[A-Za-z0-9_]{20})|(xox[baprs]-[A-Za-z0-9-]{10})|(AKIA[0-9A-Z]{16})|(-----BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY-----)|((api[_-]?key|secret|access[_-]?token|auth[_-]?token|password)["'"'"' ]*[:=]["'"'"' ]*[A-Za-z0-9/+_.-]{12,})'

# Local absolute paths / usernames. Generic — does NOT hardcode this author's
# name, so the script itself is safe to publish. The Windows-drive branch uses a
# non-letter/digit separator class instead of a literal backslash, because
# git-bash (MSYS) collapses backslashes in command arguments and would otherwise
# silently break the pattern (matches both C:\Users\name and C:/Users/name).
scan FAIL "local absolute paths / usernames" \
  '([Cc]:[^A-Za-z0-9]Users[^A-Za-z0-9][A-Za-z0-9._-]+)|(/home/[A-Za-z0-9._-]+)|(/Users/[A-Za-z0-9._-]+)|(\$USERPROFILE|%USERPROFILE%)|(/root/[A-Za-z0-9._-])'

# Personal email addresses. Benign addresses (noreply@, example.*) are filtered
# out so the git Co-Authored-By footer convention does not trip the scan.
email_hits="$(git grep --untracked -nEI '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' -- . "${SELF_EXCLUDE[@]}" ':(exclude)LICENSE' 2>/dev/null \
  | grep -vE 'noreply@|@example\.(com|org|net)|@users\.noreply\.github\.com' | allow_filter || true)"
if [ -n "$email_hits" ]; then
  echo "  [FAIL] personal email addresses"
  echo "$email_hits" | sed 's/^/        /'
  echo
  fail_count=$((fail_count + 1))
fi

# --- WARN categories: likely-but-not-certain; review each hit ----------------

# UUIDs. Session/task/thread IDs must be redacted; synthetic UUIDs in fixtures
# are fine. So this is a review prompt, not an automatic fail.
scan WARN "UUIDs (verify each is synthetic or redacted, not a real session/task/thread id)" \
  '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'

# Explicit ID field labels.
scan WARN "session/task/thread/conversation id fields" \
  '(session|task|thread|conversation|checkpoint) ?id["'"'"' ]*[:=]'

echo "== Tracked artifact-type check =="
db_hits="$(git ls-files -co --exclude-standard | grep -iE '\.(jsonl|sqlite|sqlite3|db)$|checkpoint|(^|/)history(\.|$)' || true)"
if [ -n "$db_hits" ]; then
  echo "  [FAIL] checkpoint DBs / raw JSONL / local history committed:"
  echo "$db_hits" | sed 's/^/        /'
  echo
  fail_count=$((fail_count + 1))
else
  echo "  ok: no .jsonl/.sqlite/.db/checkpoint/history files tracked"
  echo
fi

# --- verdict -----------------------------------------------------------------
echo "== Result =="
echo "   FAIL categories: $fail_count"
echo "   WARN categories: $warn_count"

if [ "$fail_count" -gt 0 ]; then
  echo "   -> NOT safe to publish: resolve FAIL findings above."
  exit 1
fi
if [ "$STRICT" -eq 1 ] && [ "$warn_count" -gt 0 ]; then
  echo "   -> --strict: WARN findings present, treated as failure."
  exit 1
fi
if [ "$warn_count" -gt 0 ]; then
  echo "   -> No FAIL findings. Review the WARN findings above manually."
else
  echo "   -> Clean against known patterns. Complete docs/publication-safety.md before publishing."
fi
exit 0
