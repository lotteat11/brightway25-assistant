# Python primer — the idioms these notebooks actually use

The Python patterns that come up constantly in Brightway work. Not a Python course.

Use this when **Python** is the obstacle rather than the LCA — when someone knows exactly
what they want to compute but the syntax is in the way.

Explain the idiom and move on. No preamble about what they should already know.

---

## Dicts

The whole Brightway data model is nested dicts.

```python
activity = {'name': 'Electricity production', 'unit': 'kilowatt hour', 'location': 'DK'}
activity['name']            # read
activity['comment'] = '…'   # add
activity.get('foo')         # → None instead of KeyError if missing
```

`.get()` vs `[]` matters when a field may be absent — `[]` raises, `.get()` returns `None`.

Iterating:
```python
for key in activity:                    # keys
for key, value in activity.items():     # both — used constantly in notebook 2
```

---

## Tuples, and why keys look like `('db', 'code')`

```python
key = ('mydb', 'electricity')   # tuple — parentheses
```

Brightway identifies every activity by `(database_name, activity_code)`. Two databases can
each hold `'electricity'`; the pair is what is unique.

**Tuples are immutable, so they can be dict keys. Lists cannot.** This is the reason for
`TypeError: unhashable type: 'list'` — the single most common Python error on this course.

```python
('mydb', 'electricity')     # ✓
['mydb', 'electricity']     # ✗ TypeError
```

---

## Nested structure: an activity with exchanges

The shape that intimidates students in notebook 1. Read it outside-in:

```python
db = {
    ('mydb', 'electricity'): {          # ← key: (database, code)
        'name': 'Electricity production',
        'unit': 'kilowatt hour',
        'exchanges': [                  # ← a LIST of dicts
            {'input': ('mydb', 'electricity'), 'amount': 10, 'type': 'production'},
            {'input': ('mydb', 'fuel'),        'amount': -2, 'type': 'technosphere'},
            {'input': ('bio', 'CO2'),          'amount': 1,  'type': 'biosphere'},
        ]
    },
}
```

- outer dict: database, keyed by tuple
- each value: one activity's fields
- `'exchanges'`: a **list**, because there are many, each a dict

Three levels, and every level is a plain Python container. Nothing Brightway-specific
about the *structure* — only about which keys are required.

---

## List comprehensions

Used everywhere for filtering:

```python
[act for act in db if act['name'] == 'Electricity production']
```

Reads as: *build a list of `act`, for each `act` in `db`, where the name matches.*
Equivalent to:

```python
result = []
for act in db:
    if act['name'] == 'Electricity production':
        result.append(act)
```

If the comprehension is opaque, write the loop instead — it is not worse code.

Extracting one field:
```python
[a['name'] for a in db][:10]      # first 10 names
```

---

## Generators — the silent trap

`.exchanges()` returns a **generator**: items are produced on demand and **only once**.

```python
excs = act.exchanges()
print(excs)          # <generator object …>  — looks broken, isn't
list(excs)           # [ …the exchanges… ]
list(excs)           # []  ← already consumed! No error.
```

**Fix once, at the top:**
```python
excs = list(act.exchanges())    # now reusable, indexable
```

This causes bugs with **no traceback** — a second loop simply does nothing. When a loop
"doesn't run", check this first.

---

## The Monte Carlo idiom

The idiom that appears in every Brightway Monte Carlo example:

```python
mc_results = [mc.score for _ in zip(range(500), mc)]
```

Piece by piece:
- `mc` is itself iterable — each step draws a new random sample and recomputes
- `range(500)` caps it at 500 iterations
- `zip(a, b)` pairs them and stops at the shorter one — so: 500 draws
- `_` means "I don't need this value" — a convention, not syntax
- `mc.score` is read *after* each advance

So: *advance the simulation 500 times; collect the score each time.* A plain loop is equivalent and often clearer:

```python
mc_results = []
for _ in range(500):
    next(mc)
    mc_results.append(mc.score)
```

---

## f-strings

```python
print(f'The score is {lca.score:.2f} kg CO2-eq')
```
`f` prefix enables `{}` substitution; `:.2f` means two decimals.

---

## pandas, minimally

```python
df = pd.read_csv('mydata.csv')
df.head()                       # first rows — always look before debugging
df.columns                      # column names — where import bugs hide
df.shape                        # (rows, columns)
df = df.drop(columns=['x'])
df.describe()                   # summary stats — used for MC results
df['col'].mean()
```

When a spreadsheet import misbehaves, **inspect `df.columns` before debugging the code**.
Import failures are nearly always column-name or column-order problems.

---

## numpy, minimally

```python
A = np.matrix([[10., 0.], [-2., 100.]])
A.getI()        # inverse
A * B           # matrix multiplication — because these are np.matrix
A.shape
```

**Critical:** with `np.array` instead, `*` becomes **elementwise** and gives wrong answers
with no error. Use `@` and `np.linalg.inv()` if working with arrays. See `errors.md`.

The trailing `.` in `10.` makes it a float. Integer division and integer matrices cause
occasional surprises; floats avoid them.

---

## Reading a traceback

1. Read the **last line** — that is the error.
2. Scan upward for the last line naming *your* notebook, not library files. That is where
   your mistake is.
3. Ignore the rest on first pass.

Reading from the top means hitting unfamiliar library paths first, which is why the actual
message often goes unseen. Worth saying out loud once — it transfers to every future
traceback.

---

## Jupyter behaviours that confuse

- **Cells share state.** Running out of order gives results that do not match the code as
  written. When something is inexplicable: *Kernel → Restart & Run All*.
- **Last expression auto-displays.** `lca.score` alone prints; inside a loop it does not —
  needs `print()`.
- **`!pip install` may target a different Python than the kernel.** Check
  `import sys; print(sys.executable)`. See `setup.md`.
- **A hung cell** shows `[*]`. The ecoinvent import legitimately takes minutes.
