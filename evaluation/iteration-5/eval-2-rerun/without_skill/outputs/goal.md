```
/goal No call sites of db.query_raw( remain anywhere under src/ (the deprecated
method definition in src/billing/db.py may stay, but nothing may call it), and
the full test suite passes. Prove it in the most recent turn by running
`rg -n "\.query_raw\(" src | wc -l` and showing it prints 0, plus running
`python -m pytest -q` and showing the summary line reports 0 failed with the
same total test count as the starting run (2 passed) — or stop after 15 turns
or if the printed query_raw count doesn't drop for 2 turns, then summarize
what's blocking. Do not modify or delete any file under tests/ — show
`git diff --stat` each turn to prove it stays untouched. Do not change the
public behavior of overdue_invoices() or paid_invoices() (same arguments,
same return type). State the turn number each turn.
```

Why these choices:
- **Proof commands** — I inspected the repo: it's `src/billing/db.py` (defines `query_raw` and the replacement `query`) and `src/billing/invoices.py` (the only two call sites, in `overdue_invoices()` and `paid_invoices()`). `pyproject.toml` has `[tool.pytest.ini_options]` with `testpaths = ["tests"]`, so `python -m pytest -q` is the real test command for this project — not a guess.
- **Call-site pattern** — `\.query_raw\(` (with the leading dot) specifically matches call sites like `db.query_raw(...)`, not the `def query_raw(...)` definition line in `db.py`, so the goal doesn't force Claude to delete the deprecated method itself, only to stop calling it — matching what you asked ("migrate every call site").
- **Test-count pin** — the suite currently has 2 tests (`test_overdue_returns_list`, `test_paid_returns_list`). Requiring the same count blocks a false completion via a weakened/deleted test.
- **Guardrail** — `tests/` is protected via a required `git diff --stat` each turn, and the two functions' external signatures are pinned, so the migration can't "succeed" by changing what callers see.
- **Stop clause** — bounded at 15 turns with a stall check on the grep count, and Claude must summarize what's left if it stops early.

One thing to flag: this environment doesn't currently have `pytest` installed (`python -m pytest -q` fails with "No module named pytest"). If that's also true wherever you run the goal, either install it first (`pip install pytest`) or tell me and I'll swap the proof command to something that works in your environment.
