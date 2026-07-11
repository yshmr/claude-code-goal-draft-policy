One thing this folder can't tell me: which repository's pull requests you mean. This is an empty directory with no `.git`, so there's no remote to infer a repo from and no local test/build command to run at all — the proof has to lean on `gh` (GitHub CLI) pointed at an explicit `owner/repo`, plus the `RELEASE_NOTES.md` file itself as the artifact.

**Before you paste this, fill in `<owner/repo>`** with the actual GitHub repository, and double check the date range — I assumed "this week" = Monday 2026-07-06 through today, Saturday 2026-07-11 (adjust `2026-07-06` if you mean a different week boundary). Everything else in the condition works regardless.

```
/goal RELEASE_NOTES.md contains exactly one bullet line for every pull request
merged in <owner/repo> since 2026-07-06 (this week), and no bullet for a PR that
isn't in that list. Prove it in the most recent turn by running:
gh pr list --repo <owner/repo> --state merged --search "merged:>=2026-07-06" --json number,title
to get the authoritative merged-PR list, then show: (a) the count N of PRs
returned, (b) the count of bullet lines in RELEASE_NOTES.md (e.g.
`grep -c "^- " RELEASE_NOTES.md`), and (c) for each PR number from the gh
output, confirm it appears in RELEASE_NOTES.md (e.g. `grep -o '#[0-9]\+'
RELEASE_NOTES.md | sort -u` compared against the gh numbers) — the goal is met
only when the two counts are equal and no PR number is missing or extra. If
`gh` fails (not authenticated, repo not found, or no network), stop after 3
turns and report the exact error instead of guessing at PR content — or
otherwise stop after 15 turns or if the missing/extra count doesn't change for
2 turns, then summarize which PRs are still unaccounted for. Do not invent a
bullet for a PR number that doesn't appear in the gh output, and do not delete
or reword a bullet for a PR that is genuinely in this week's merged list.
```

Why it's built this way:
- **No command exists in this folder**, so per the "empty folder" case the end state falls back to an artifact (`RELEASE_NOTES.md`'s content) rather than a test/build signal — but the *source of truth for what counts as "merged this week"* still needs a real, re-runnable command, which is `gh pr list --search "merged:>=DATE"` against the specific repo.
- **Count-matching alone is gameable** (Claude could pad with N generic bullets or drop a real one while keeping the count right), so the evidence signal also requires each PR number to actually appear in the file — not just N == N.
- **Stop clause has two branches**: a fast bail-out if `gh` itself can't run (auth/network/wrong repo — no point looping on that), and a normal turn cap / stall detector for the case where PRs are simply missing bullets and progress has stalled.
- The condition names `<owner/repo>` and the week-start date explicitly because those can't be inferred from an empty directory — replace both before running `/goal`.
