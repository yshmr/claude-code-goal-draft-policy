```
/goal No call sites of the deprecated db.query_raw() helper remain in src/ — every
one has been migrated to the new db.query() API, and the test suite still passes.
Prove it in the most recent turn by running `rg -n "\.query_raw\(" src/` (0 matches)
and `pytest -q` (summary line shows 0 failed / all passed). Constraints: do not edit
any file under tests/, and do not change the public method signatures in
src/billing/db.py (leave the query_raw definition itself intact). Stop after 15 turns
or if the match count doesn't drop for 2 turns — then summarize the blocker.
```

Rationale: I inspected the repo and found two `db.query_raw(...)` call sites in
`src/billing/invoices.py`; the `query_raw` definition in `src/billing/db.py` is the
deprecated API surface, not a call site. I chose `rg -n "\.query_raw\(" src/` for the
absence check — the `.query_raw(` pattern matches usages but not the `def query_raw`
definition, so the goal completes only when all call sites are gone without deleting the
helper. For tests I used `pytest -q`, the command the project's `pyproject.toml`
configures (`testpaths = ["tests"]`, `addopts = "-q"`). Guardrails forbid editing tests
(so Claude can't "pass" by weakening them) and changing db.py signatures; a turn cap plus
a no-progress trigger bound the loop. Note: goals that run shell commands pause on
approval prompts unless you're in acceptEdits/bypassPermissions mode.
