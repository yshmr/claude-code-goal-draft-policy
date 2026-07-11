# Your /goal

There's one thing I can't fill in for you: **which GitHub repo** the pull requests live in. This folder is empty (no `.git`, no remote), so `gh pr list` has nothing to infer a repo from — I've left it as a placeholder (`<OWNER/REPO>`) for you to replace before pasting. I also pinned "this week" to a fixed date range (Mon–today) rather than a rolling window, so the target PR count can't keep moving while Claude is still working on it.

```
/goal RELEASE_NOTES.md contains exactly one bullet per pull request merged in
<OWNER/REPO> between 2026-07-06 and 2026-07-11 (inclusive), and no others.
Prove it in the most recent turn by running:
  gh pr list --repo <OWNER/REPO> --state merged --search "merged:2026-07-06..2026-07-11" --json number,title --jq length
and showing the printed count, then running:
  grep -c "^- " RELEASE_NOTES.md
and showing that count matches exactly. Each bullet must reference a real PR
number from that gh pr list output (paste the full --json number,title,url
listing at least once so the mapping is checkable) — do not invent, merge,
duplicate, or drop entries. Do not edit any bullet for a PR outside that date
range. Stop after 15 turns, or if `gh pr list` errors twice in a row (e.g. no
repo access or not authenticated), or if the two counts stop changing for 2
turns without matching — then summarize what's blocking and what still needs a
human (e.g. `gh auth login`, or the correct repo name).
```

**Before you paste it:** replace both `<OWNER/REPO>` placeholders with the actual `owner/repo` (e.g. `anthropics/claude-code`). Also confirm `gh` is authenticated (`gh auth status`) and has access to that repo — the goal's stop clause catches repeated auth/repo failures and reports them instead of looping forever, but it can't fix them for you.

Why it's built this way:
- **Proof command** — `gh pr list --search "merged:<range>"` is the actual source of truth for "PRs merged this week"; a fixed date range (rather than `merged:>=7 days ago`) keeps the target count stable even if new PRs merge while the goal is still running.
- **Evidence signal** — two independently-obtained counts (gh's count vs. a `grep -c` of RELEASE_NOTES.md bullets) have to match, and the full PR listing must appear at least once so each bullet is traceable to a real PR rather than a plausible-sounding invention.
- **Guardrail** — no bullets for PRs outside the range, no duplicates/invented entries.
- **Stop clause** — bounded by turns, and by two realistic failure modes for an empty-folder handoff (no `gh` auth, wrong/inaccessible repo) so it fails loud instead of looping silently.
