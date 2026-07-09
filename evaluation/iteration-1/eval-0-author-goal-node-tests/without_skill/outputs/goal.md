# /goal setup: make the authentication tests pass

## The command to run

```
/goal The authentication tests pass: running `npm run test:auth` completes with every test passing and exit code 0.
```

Paste that into Claude Code. Claude will then keep working across turns on its own until that condition is satisfied, instead of stopping and handing control back to you after each step.

## Why this condition

I inspected the repo (do-not-modify, so nothing was changed):

- `package.json` defines the script `"test:auth": "jest tests/auth"`. That is the exact, machine-checkable command that scopes to authentication.
- The auth tests live in `tests/auth/login.test.ts` and cover `src/auth/login.ts`:
  - "returns a token on valid credentials"
  - "returns null on empty credentials"

Tying the goal to `npm run test:auth` exiting 0 gives Claude an objective, unambiguous stopping point — it can run the command itself, read the result, and know whether it is done. (A vaguer condition like "fix the auth code" has no clear finish line and invites Claude to stop early or overshoot.)

Note: only the auth suite is targeted. If you'd rather gate on the entire suite, use `npm test` instead of `npm run test:auth` in the condition.

## Important: `/goal` alone does not remove approval prompts

Your request had two parts, and they're controlled by two different mechanisms:

1. **"Keep working across turns"** — this is exactly what `/goal` provides. Handled by the command above.
2. **"Without me approving every turn"** — this is about *tool permissions*, not `/goal`. By default Claude still pauses to ask before running commands (like `jest`) or editing files. `/goal` will keep re-prompting Claude to continue, but you'll still be tapping approve on each tool call unless you change the permission mode.

To get true hands-off operation, combine the goal with a less restrictive permission mode. Options, from safest to most autonomous:

- **Accept Edits mode** — press `Shift+Tab` to cycle the mode indicator (shown at the bottom of the Claude Code TUI) to "accept edits". File edits stop prompting; commands may still ask.
- **Pre-approve the specific tools** you know it needs, so only those run without prompts. Add to `.claude/settings.json` (or `.claude/settings.local.json`) in the repo:

  ```json
  {
    "permissions": {
      "allow": [
        "Bash(npm run test:auth)",
        "Bash(npm test)",
        "Bash(npx jest:*)",
        "Edit",
        "Write"
      ]
    }
  }
  ```

  This is the recommended middle ground: Claude can run the tests and edit source files freely, but you haven't handed it a blank check for arbitrary commands.
- **Bypass all permissions** — launch with `claude --dangerously-skip-permissions`. Fully unattended, but Claude can run *any* command without asking. Only do this if you trust the task and environment (e.g. a sandbox or throwaway branch).

## Suggested workflow

1. (Optional but recommended) Add the `permissions.allow` block above to `.claude/settings.json`, or plan to flip to Accept Edits mode with `Shift+Tab`.
2. Run the `/goal` command.
3. Let Claude iterate: it will run `npm run test:auth`, inspect failures, edit `src/auth/login.ts` (and/or the tests if appropriate), and re-run until the suite is green.

## One heads-up about this repo

The project runs TypeScript tests through Jest but the lockfile is empty and there's no visible `ts-jest`/Babel config or `jest.config`. If dependencies aren't installed, Claude may first need to `npm install` and possibly add TS-transform config before `jest` can even execute the `.test.ts` files. That's fine — it's within scope of reaching a passing `npm run test:auth`, and the goal condition will simply keep Claude working until that command actually succeeds. If you pre-approve tools, consider also allowing `Bash(npm install:*)`.
