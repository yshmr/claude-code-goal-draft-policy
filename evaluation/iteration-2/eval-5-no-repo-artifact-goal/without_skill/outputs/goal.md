# Your `/goal` command

Paste this into Claude Code, replacing `OWNER/REPO` with the GitHub repo you
want release notes for (this folder is empty, so there's no repo for Claude to
infer — you have to name it):

```
/goal RELEASE_NOTES.md in the current folder contains exactly one bullet for every pull request merged into OWNER/REPO this week, then stop. "This week" = merged on or after the most recent Monday 00:00 in my local time through now. Because the completion check can only read this conversation and cannot run tools, on EVERY turn you must print two things: (1) the authoritative list of this week's merged PRs, freshly re-fetched with `gh pr list --repo OWNER/REPO --state merged --search "merged:>=YYYY-MM-DD" --limit 200 --json number,title,mergedAt` (compute YYYY-MM-DD as this week's Monday), shown as number + title; and (2) the full current contents of RELEASE_NOTES.md. The goal is met ONLY when the two printed blocks agree: every merged-PR number appears in exactly one bullet, the bullet count equals the merged-PR count, and no bullet references a PR outside this week. If the fetch fails (gh not installed/authenticated, repo not found), print the exact error and stop — do not fabricate PRs or bullets.
```

## Why it's written this way

- **The checker is blind to tools.** After each turn a small, fast model decides
  whether you're done, and it can only see what's in the transcript — it can't
  run `gh` or open the file. So the goal forces Claude to paste both the live PR
  list *and* the file contents into the chat every turn. That's the only way the
  check can actually confirm "one bullet per PR" instead of guessing.

- **Re-fetch every turn.** A PR could merge while Claude is working. Re-pulling
  the list each turn keeps the target honest and prevents Claude from declaring
  victory against a stale snapshot.

- **Exact match, both directions.** "One bullet for every PR" is spelled out as
  count-equal + every number present + nothing extra, so Claude can't stop early
  (missing PRs) or pad the file (bullets for PRs outside this week).

- **Empty-folder reality.** There's no git remote here to infer, so you must
  supply `OWNER/REPO`, and `gh` must be installed and authenticated
  (`gh auth status`). The explicit failure clause means Claude stops and tells
  you instead of hallucinating a release-notes file — a real risk when a
  keep-going goal meets a source it can't reach.

## Before you run it

- Install + authenticate GitHub CLI: `gh auth status` should show you logged in.
- Confirm you can read the repo: `gh pr list --repo OWNER/REPO --state merged --limit 1`.
- Optional: if by "this week" you mean something other than "since Monday"
  (e.g. last 7 days), tweak the date phrase in the goal accordingly.
