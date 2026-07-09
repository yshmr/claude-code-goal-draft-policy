# Official `/goal` reference (Claude Code docs)

Distilled from the official documentation, "Keep Claude working toward a goal":
<https://code.claude.com/docs/en/goal>. This file is the ground truth for how
`/goal` behaves. When drafting or repairing a condition, rely on the facts here —
they define what the evaluator can and cannot do, which is what makes a condition
judgeable. If Claude Code's behavior appears to have changed, re-fetch the URL
above and update this file rather than guessing.

## What `/goal` is

`/goal <condition>` sets a completion condition and Claude keeps working toward it
without the user prompting each step. After each turn, a small fast model checks
whether the condition holds. If not, Claude starts another turn instead of
returning control. The goal clears automatically once the condition is met.

Intended for substantial work with a verifiable end state, e.g.:
- Migrating a module to a new API until every call site compiles and tests pass
- Implementing a design doc until all acceptance criteria hold
- Splitting a large file into focused modules until each is under a size budget
- Working through a labeled issue backlog until the queue is empty

**Requires Claude Code v2.1.139 or later.**

## How evaluation works (the load-bearing facts)

- `/goal` is a wrapper around a **session-scoped prompt-based Stop hook**. Each
  time Claude finishes a turn, the condition plus the conversation so far are sent
  to the configured **small fast model (defaults to Haiku)**.
- The model returns a **yes/no decision and a short reason**. "No" tells Claude to
  keep working and passes the reason as guidance for the next turn. "Yes" clears
  the goal and records an achieved entry in the transcript.
- The evaluator runs on whichever provider the session uses. **It does not call
  tools**, so it can only judge what Claude has already surfaced in the
  conversation. → This is why conditions must be verifiable from the transcript.
- Evaluation tokens bill on the small fast model and are typically negligible vs.
  main-turn spend.

## Using `/goal`

**One goal can be active per session.** The same command sets, checks, and clears
it depending on the argument.

- **Set**: `/goal <condition>`. If a goal is already active, the new one replaces
  it. Setting a goal **starts a turn immediately**, with the condition itself as
  the directive — no separate prompt needed. While active, a `◎ /goal active`
  indicator shows how long it has been running. After each turn the evaluator's
  most recent reason appears in the status view and transcript.
- **Check status**: `/goal` with no arguments shows the condition, how long it has
  run, turns evaluated, current token spend, and the evaluator's most recent
  reason. If no goal is active but one was achieved earlier in the session, it
  shows the achieved condition with its duration, turn count, and token spend.
- **Clear**: `/goal clear` removes an active goal before its condition is met.
  Aliases: `stop`, `off`, `reset`, `none`, `cancel`. Running `/clear` (new
  conversation) also removes any active goal.
- **Resume**: a goal still active when a session ended is restored on `--resume` /
  `--continue`. The condition carries over, but turn count, timer, and token-spend
  baseline all reset. A goal already achieved or cleared is not restored.
- **Non-interactive**: works in headless mode, the desktop app, and Remote
  Control. `claude -p "/goal <condition>"` runs the loop to completion in one
  invocation. Ctrl+C stops a non-interactive goal early.

## Writing an effective condition (official guidance)

The evaluator judges the condition against what Claude has surfaced in the
conversation. It does not run commands or read files independently, so write the
condition as something Claude's own output can demonstrate. "All tests in
`test/auth` pass" works because Claude runs the tests and the result lands in the
transcript for the evaluator to read.

A condition that holds up across many turns usually has:
- **One measurable end state**: a test result, a build exit code, a file count,
  an empty queue.
- **A stated check**: how Claude should prove it, such as "`npm test` exits 0" or
  "`git status` is clean".
- **Constraints that matter**: anything that must not change on the way there,
  such as "no other test file is modified".

The condition can be up to **4,000 characters**. To bound how long a goal runs,
include a turn or time clause in the condition, such as `or stop after 20 turns`.
Claude reports progress against that clause each turn and the evaluator judges it
from the conversation.

## Requirements / when `/goal` is unavailable

- Runs only in workspaces where the **trust dialog has been accepted** (the
  evaluator is part of the hooks system).
- Unavailable when `disableAllHooks` is set at any settings level, or when
  `allowManagedHooksOnly` is set in managed settings. In each case the command
  tells you why instead of silently doing nothing.

## Ways to keep a session running (official comparison)

| Approach | Next turn starts when | Stops when |
|----------|----------------------|------------|
| `/goal` | The previous turn finishes | A model confirms the condition is met |
| `/loop` | A time interval elapses | You stop it, or Claude decides the work is done |
| Stop hook | The previous turn finishes | Your own script or prompt decides |

`/goal` is a session-scoped shortcut (active for the current session only); a Stop
hook lives in settings and applies to every session in its scope. **Auto mode** is
complementary: it approves tool calls within a turn but doesn't start a new one —
combine it with `/goal` so each goal turn runs unattended.

## Source

Official documentation: <https://code.claude.com/docs/en/goal> (fetched during the
session that created this skill; re-fetch to refresh).
