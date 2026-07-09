## Recommended `/goal`

```
/goal Every call site of the deprecated db.query_raw() helper in the billing service has been migrated to the new db.query() API, and the test suite still passes. Done means ALL of the following are true and verified: (1) a repo-wide search for "query_raw(" returns no matches anywhere except the helper's own definition in src/billing/db.py — zero remaining callers; (2) each migrated call uses db.query(sql, params) and passes any dynamic values through the params dict instead of interpolating them into the SQL string; (3) running `pytest -q` from the repo root reports all tests passing with zero failures or errors. Keep working across turns until every call site is migrated and pytest is green — do not stop early or hand back a partial migration.
```

## Why this works

The `/goal` command keeps Claude working across turns until the stated condition is objectively met. This condition is written so Claude can self-verify completion rather than guess:

- **Exhaustive, not "a few places"** — the completion check is a repo-wide search for `query_raw(` returning zero *callers*. This forces Claude to find every site (there are currently two, both in `src/billing/invoices.py`), and it stays correct even if there are call sites Claude hasn't seen yet.
- **Excludes the helper definition** — `db.query_raw()` itself is defined in `src/billing/db.py`. The condition explicitly exempts that one line so the goal doesn't get "stuck" trying to delete the definition (the user asked to migrate *call sites*, not remove the deprecated method).
- **Encodes correct usage, not just a rename** — the new `query(sql, params=None)` API takes a params dict. Requiring dynamic values to go through `params` prevents a lazy find-and-replace that leaves SQL-injection-prone string interpolation in place.
- **Ties in the test gate** — `pytest -q` passing is part of the condition, matching "not stop until it's fully done and the tests still pass."

## What Claude will do under this goal

1. Search the repo for `query_raw(` call sites (finds `src/billing/invoices.py:7` and `:11`).
2. Rewrite each to `db.query(...)`, using a `params` dict for any dynamic values (the current two queries are static, so a straight swap to `db.query(sql)` is valid).
3. Run `pytest -q` and confirm all tests pass (`tests/test_invoices.py`).
4. Re-run the search to confirm no callers remain, then report done.

Note: I inspected the fixture repo to size the condition but did not modify any files.
