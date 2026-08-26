# Errors — traceback → cause → fix

Check here first for any traceback. Most errors on this course are one of these.

**How to use this with a student who is not fluent in Python:** read the *last* line of
the traceback first — that is the actual error. Everything above it is the call stack.
Tell them this; many students read from the top, panic at unfamiliar file paths, and
never reach the line that says what went wrong.

Always translate before fixing. `KeyError: ('db', 'act')` means nothing until someone
says "Python looked for an activity with that name and there isn't one".

---

## Brightway: database and activity errors

### `KeyError: ('some_db', 'some_activity')`
**Means:** no activity with that code exists in that database.
**Usual causes:** typo; wrong database name; the database was never written; you are in
the wrong project.
**Fix:**
```python
print(bd.projects.current)   # right project?
print(list(bd.databases))    # database there?
print([a['code'] for a in bd.Database('some_db')][:20])   # what codes exist?
```

### `AssertionError` / `ValidityError` on `.write()`
**Means:** the dict you passed does not match the structure Brightway expects.
**Usual causes:** missing `'exchanges'` key; an exchange missing `'input'`, `'amount'` or
`'type'`; `'input'` given as a string instead of a `(database, code)` tuple; no
`'production'` exchange on an activity.
**Fix:** every activity needs a production exchange; every exchange needs input/amount/type;
inputs are always tuples. See `python-primer.md` on tuple keys.

### `Database ... is locked` / `Cannot lock project`
**Means:** another process holds the project.
**Usual causes:** a second notebook or a Python console open on the same project; a
crashed kernel that never released the lock.
**Fix:** shut down other kernels (Jupyter: *Running* tab → Shutdown). If nothing else is
running, restart the kernel. On synced folders (Dropbox/OneDrive) this recurs — see
`setup.md`.

### `.write()` seems to succeed but the database is empty
**Usual cause:** writing a dict built from a DataFrame where `lci_to_bw2()` silently
dropped rows because of column naming.
**Fix:** `len(db)` before writing; `print(list(db.items())[:1])` to inspect one entry.

### `Not able to determine geocollections for all datasets`
**Not an error.** A warning about regionalization, irrelevant to this course. Reassure and
move on — students often stop here thinking the import failed.

---

## Brightway: calculation errors

### `AttributeError: 'LCA' object has no attribute 'score'`
**Means:** you asked for the result before computing it.
**Fix:** `lca.lci()` then `lca.lcia()`, *then* `.score`. `lci()` solves the inventory,
`lcia()` characterises it — this ordering is a method point, not just an API quirk. Good
moment to tutor briefly.

### `Nonsquare matrix` / `singular matrix` / `LinAlgError`
**Means:** A cannot be inverted.
**Usual causes:** an activity with no production exchange; a product produced by nothing;
a duplicated activity code.
**Fix:** check every activity has exactly one production exchange. Conceptually: each
column must produce exactly one product. Ties back to notebook 0.

### `ImportError: cannot import name 'MonteCarloLCA'`
**Means:** legacy Brightway 2 code. Removed in 2.5.
**Fix:**
```python
mc = bc.LCA(demand={act: 1}, method=m, use_distributions=True)
mc.lci(); mc.lcia()
results = [mc.score for _ in zip(range(500), mc)]
```
See `bw25-api.md`. Note this is a likely wrong answer from a general AI assistant.

### Monte Carlo returns identical values every iteration
**Usual causes:** `use_distributions=True` omitted; no uncertainty defined on any
exchange; re-reading `.score` without advancing the iterator.
**Fix:** confirm exchanges carry `'uncertainty type'` and `scale`. Without uncertainty
data, MC correctly returns the deterministic result — worth saying, since students assume
it is broken.

### `redo_lcia()` raises, or gives suspicious results
**Usual cause:** called before the first `lci()`/`lcia()`, or with a demand referring to
an activity not in the sampled matrix.
**Fix:** run a full `lci()`/`lcia()` first. Conceptually `redo_lcia()` re-scores under the
*same* random draw — that reuse is the whole point of notebook 6.

---

## Import and environment errors

### `ModuleNotFoundError: No module named 'bw2data'` (or `bw2calc`, `SALib`, `ecoinvent_interface`)
**Means:** package missing *from the environment the kernel is using* — often installed,
but somewhere else.
**Fix:** check which Python the kernel is actually running:
```python
import sys; print(sys.executable)
```
If that is not your course environment, the kernel is wrong — see `setup.md`. Installing
again will not help and usually makes it worse. **This is the single most common setup
problem.** Diagnose the kernel before suggesting any install.

### `ImportError: cannot import name 'lci_to_bw2'`
**Means:** `lci_to_bw2.py` is not in the working directory.
**Fix:** `import os; print(os.getcwd())` — the file must be beside the notebook.

### `ecoinvent_interface` authentication failures
**Usual causes:** wrong credentials; no licence for the requested version; typo in
`version` or `system_model`; institutional login that differs from the ecoinvent website
login.
**Fix:** verify by logging in at ecoinvent.org. Check the version string exactly
(`'3.11'`, not `3.11`). Note the import is slow — several minutes, no progress bar. Tell
students it is not frozen.

---

## Python errors these notebooks actually produce

### `TypeError: unhashable type: 'list'`
**Means:** a list was used where a tuple was needed. Almost always `['db', 'code']`
instead of `('db', 'code')`.
**Fix:** square brackets → parentheses. Explain: dict keys must be immutable; tuples are,
lists are not.

### `TypeError: 'generator' object is not subscriptable` — or a generator prints as empty
**Means:** `.exchanges()` returns a generator: it produces items once, on demand.
**Fix:** `excs = list(act.exchanges())`, then index and re-use freely.
**Common trap:** looping over a generator twice — the second loop silently does nothing.
This is a *very* common notebook-2 confusion and produces no error at all.

### `KeyError: 'amount'` when iterating exchanges
**Usual cause:** treating an exchange object as a plain dict.
**Fix:** `exc['amount']` works; `exc.as_dict()` shows everything available.

### `ValueError: shapes (a,b) and (c,d) not aligned`
**Means:** matrix dimensions do not match for multiplication.
**Fix:** print `.shape` of each. For `g = B @ A_inv @ f`: A is n×n, B is m×n, f is n×1.
Usually a row/column mix-up when building the matrices by hand in notebook 0.

### Notebook 0 results wrong after switching `np.matrix` → `np.array`
**Means:** `*` is matrix multiplication on `np.matrix` but **elementwise** on `np.array`.
**No error is raised — the numbers are just wrong.** Insidious.
**Fix:** either keep `np.matrix`, or switch to `@` and `np.linalg.inv()` throughout:
```python
A = np.array([[10., 0.], [-2., 100.]])
g = B @ np.linalg.inv(A) @ f
```
Do not push students to modernise mid-course; do explain the trap if they have already
hit it.

### `SettingWithCopyWarning` (pandas)
**Usually harmless** in notebook 4, but means a slice was modified. If values are not
updating, use `.copy()` or `.loc[]`.

### `FileNotFoundError` on CSV or Excel
**Fix:** `os.getcwd()`, then check the exact filename including extension. On macOS,
Finder hides extensions — `.csv` may really be `.csv.txt`.

---

## When the error is not in this file

1. Read the **last** line — the exception type and message.
2. Find the last line of the traceback pointing at *the student's own* notebook, not
   library internals. That is usually where the mistake is.
3. Check the obvious state: right project, right database, right kernel.
4. Reproduce minimally — one cell, smallest input.

If it looks like a genuine Brightway bug rather than a usage error, say so. The
Brightway community lives at <https://github.com/brightway-lca> and its Discord — worth
pointing students there rather than guessing at internals.
