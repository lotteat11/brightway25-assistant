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

### `KeyError` on an ecoinvent or biosphere code
**Means:** the exchange points at something that is not there — an unlinked exchange.
**Check, in order:**
1. Does the database name match exactly? `print(list(bd.databases))` — `ecoinvent-3.11-consequential`, not `ecoinvent 3.11` or a different system model
2. Is the code in the right format? ecoinvent codes are 32 hex characters with **no
   dashes**; biosphere codes are 36 characters **with dashes**. Using one where the other
   belongs is common
3. Does the code actually exist? `bd.get_activity((dbname, code))`

**Do not read the spreadsheet by hand.** `linking.md` has a loop that checks every
exchange in a database and prints exactly which links are broken. Run that first.

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

### Everything imports, but the score is zero or suspiciously small
**Usual cause:** exchanges are silently unlinked, so the foreground is not actually
connected to the background. No error is raised — the calculation just has nothing to
propagate through.
**Fix:** run the diagnostic loop in `linking.md`. Also sanity-check that technosphere
exchanges point at real ecoinvent activities and not at placeholder rows.

### Results differ between machines, or after re-importing ecoinvent
**Means:** something is linked by `id` instead of `code`.
**Why:** `id` is an integer matrix coordinate assigned by *this* installation — it depends
on what else is in the database. `code` is a stable string.
**Fix:** always link by `code`. See `linking.md`.

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

**Check this first, before anything else:** has the user logged in at
[ecoinvent.org](https://ecoinvent.org) in a browser and **accepted the licence and the
personal-data agreement?** The API refuses accounts that have not, and the error message
says nothing about agreements. This is the single most common cause, and it is invisible
from Python.

Other causes, in rough order of likelihood:

- **Institutional SSO ≠ ecoinvent account.** If they normally reach ecoinvent through a
  university portal, they may not have a direct username/password at all.
- **Licence does not cover that version or system model.** Not every licence includes
  every release.
- **Arguments passed as numbers.** `version='3.11'` — a string, not `3.11`.
- **Special characters in the password**, if set via environment variables — needs single
  quotes: `export EI_PASSWORD='pa$$word'`.
- **Outdated `ecoinvent_interface`.** It talks to an API that changes; something that
  worked last month can break. Try updating.

**Fix:** work through `setup.md`'s ecoinvent checklist in order. Do not debug Python until
step 0 is confirmed.

### Ecoinvent import appears frozen

**Not an error.** The import takes **10–30 minutes with no progress bar**. The cell shows
`[*]` and looks dead.

**Do not interrupt it.** Interrupting can leave a half-imported project that fails in
confusing ways afterwards. Say this *before* someone starts the import.

If they already interrupted one, the cleanest fix is usually to start over:
```python
bd.projects.delete_project('name', delete_dir=True)
```

### Ecoinvent import fails partway through, and retrying behaves strangely

**Usual cause:** a previous interrupted or failed import left the project in a partial
state.
**Fix:** delete the project and re-import rather than trying to repair it. Faster and more
reliable.

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
