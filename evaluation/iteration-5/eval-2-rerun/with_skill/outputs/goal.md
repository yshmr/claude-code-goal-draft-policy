Here's a ready-to-paste `/goal`:

```
/goal No call site in src/ invokes db.query_raw( anymore — every call is migrated
to db.query(), and the full test suite still passes. Prove it in the most recent
turn by running `rg -n "\.query_raw\(" src/ | wc -l` and showing it prints 0
(this pattern matches call sites like `db.query_raw(` but not the method's own
`def query_raw(` line, so the deprecated method may stay defined in db.py,
just unused), plus running `python -m pytest -q` and showing the summary line
reports all tests passed with none failed — or stop after 10 turns or if the
query_raw count doesn't drop for 2 turns, then summarize what's blocking.
Do not modify any file under tests/, and do not change the behavior or
signature of db.query() while migrating. State the turn number each turn.
```

Why these choices, from inspecting `src/billing/`:

- **Verification command**: `pyproject.toml` has `[tool.pytest.ini_options]` with `testpaths = ["tests"]`, so `python -m pytest -q` is the real, canonical test command for this repo (not a guessed `npm test`-style default).
- **Call-site scope**: `db.query_raw(` appears 3 times total — the deprecated method's own definition in `src/billing/db.py` (`def query_raw(...)`) plus 2 real call sites in `src/billing/invoices.py` (`overdue_invoices`, `paid_invoices`). The proof command uses `\.query_raw\(` (with the leading dot) specifically so it counts only *calls* and doesn't force Claude to delete the deprecated method itself — the user asked to migrate call sites, not remove the helper. If you'd rather the helper be deleted too, say so and I'll fold `def query_raw` into the same check.
- **Guardrail**: `tests/test_invoices.py` only asserts the return type is a list, so no test changes should be needed — locking `tests/` stops Claude from "passing" by editing the test instead of the code. Locking `db.query()`'s signature/behavior stops it from reshaping the new API to dodge real call-site work.
- **Stop clause**: the task is small (2 call sites), so a 10-turn cap is generous; the stall branch (`query_raw count doesn't drop for 2 turns`) catches it getting stuck on something else. If it runs unattended, remember goals that shell out still pause on tool-approval prompts unless you're in auto-approve mode.
