# Brightway 2.5 API — and the legacy traps

**Read this before answering any API question from memory.** Model training data is
saturated with Brightway 2 idioms that no longer work. A confident wrong answer here costs
real time.

---

## Imports

```python
import bw2data as bd      # projects, databases, activities, methods
import bw2calc as bc      # LCA calculations
import bw2io as bi        # importers (ecoinvent, Excel)
```

**Legacy — do not suggest:**
```python
import brightway2 as bw   # Brightway 2 umbrella import
```

You will still meet the legacy import in older scripts and in some teaching material. If
someone is following a source that uses it, meet them where they are — but flag the
mismatch, or it will confuse them when they move between sources.

---

## Brightway 2 vs 2.5 — what actually changed

Old code arrives from published supplements, colleagues' scripts, older tutorials, and AI
assistants working from memory. Understanding *what* changed makes old code translatable
instead of just broken.

**The umbrella package was split.** Brightway 2 had one `brightway2` package that
re-exported everything. Brightway 2.5 exposes the real packages directly:

| Package | Contains |
|---|---|
| `bw2data` (`bd`) | Projects, databases, activities, exchanges, methods |
| `bw2calc` (`bc`) | LCA calculations, Monte Carlo |
| `bw2io` (`bi`) | Importers — ecoinvent, Excel |

So most of the migration is knowing *which* package a name moved to.

### Name translation

| Legacy (Brightway 2) | Brightway 2.5 |
|---|---|
| `import brightway2 as bw` | `import bw2data as bd`, `import bw2calc as bc`, `import bw2io as bi` |
| `bw.LCA(...)` | `bc.LCA(...)` |
| `bw.Database(...)` | `bd.Database(...)` |
| `bw.methods`, `bw.databases`, `bw.projects` | `bd.methods`, `bd.databases`, `bd.projects` |
| `bw.get_activity(...)` | `bd.get_activity(...)` |
| `bw.Method(...)` | `bd.Method(...)` |
| `bw2setup()` | Not needed — `bi.import_ecoinvent_release()` brings biosphere with it |

### Behavioural changes — not just renames

These are the ones that cause real confusion, because a mechanical find-and-replace
leaves them broken.

**Monte Carlo is no longer a separate class.**

```python
# Brightway 2
mc = MonteCarloLCA({act: 1}, method)
for _ in range(500):
    next(mc)
    results.append(mc.score)

# Brightway 2.5 — an ordinary LCA with distributions switched on
mc = bc.LCA({act: 1}, method, use_distributions=True)
mc.lci(); mc.lcia()
results = [mc.score for _ in zip(range(500), mc)]
```

`MonteCarloLCA` does not exist in 2.5. Code that imports it came from a Brightway 2
source.

**Activities have both `code` and `id`.** `id` (an integer, the matrix coordinate) is
much more prominent in 2.5. It is installation-specific — never use it for linking or
sharing. See `linking.md`.

**ecoinvent import goes through `ecoinvent_interface`** with your licence credentials,
rather than pointing at a folder of downloaded files.

**Data is stored differently on disk.** Brightway 2 projects are not automatically usable
by 2.5. Do not tell someone their old project will just open.

### Recognising old code

Any of these means Brightway 2:

- `import brightway2` or `from brightway2 import *`
- `MonteCarloLCA`, `ParameterVectorLCA`
- `bw2setup()`
- `bw.` as a prefix on almost anything

Say plainly that it is old-API code from an outdated source — **it is not their mistake**,
and the fix is usually mechanical apart from the behavioural changes above.

---

## Projects

```python
bd.projects.set_current('advanced_lca')   # creates if absent
bd.projects.current
bd.projects.report()                      # name, #databases, size
list(bd.projects)
bd.projects.delete_project('name', delete_dir=True)
```

Custom storage location — **must precede the Brightway import**:
```python
import os
os.environ['BRIGHTWAY2_DIR'] = '/Users/you/Documents/BWprojects'
import bw2data as bd
```
Changing it mid-session requires a kernel restart. See `setup.md`.

---

## Databases

```python
bd.databases                       # dict-like, all databases in project
db = bd.Database('mydb')
db.write(db_dict)                  # bulk write
db.get('activity_code')
list(db)                           # all activities
len(db)
db.search('electricity', limit=10)
db.delete()
```

`.search()` is full-text over names. On ecoinvent expect many near-identical hits
differing by location or system model — **which one to pick is a method question**, not a
search-syntax question.

---

## Activities and exchanges

```python
act = db.get('electricity')
act['name']; act['unit']; act['location']
act.as_dict()                       # everything
act.key                             # ('mydb', 'electricity')
act['code']                         # UUID string — stable across installs
act.id                              # integer — matrix coordinate, install-specific

excs = list(act.exchanges())        # list() — generator, consumed once
for exc in excs:
    exc['amount']; exc['type']
    exc.input; exc.output
    exc.as_dict()

act.technosphere(); act.biosphere(); act.production()
```

`code` vs `id`: `code` is what you share and reference; `id` is an internal matrix
coordinate that differs between installations. These get conflated often — and it ties
directly to the matrix formulation: `id` is a coordinate in A.

---

## Writing a database

```python
db_dict = {
    ('mydb', 'electricity'): {
        'name': 'Electricity production',
        'unit': 'kilowatt hour',
        'location': 'DK',
        'exchanges': [
            {'input': ('mydb', 'electricity'), 'amount': 10, 'type': 'production'},
            {'input': ('mydb', 'fuel'),        'amount': -2, 'type': 'technosphere'},
            {'input': ('bio', 'CO2'),          'amount': 1,  'type': 'biosphere'},
        ],
    },
}
bd.Database('mydb').write(db_dict)
```

Exchange types: `'production'`, `'technosphere'`, `'biosphere'`, `'substitution'`.

Rules that cause most `.write()` failures:
- every activity needs exactly **one** production exchange
- `'input'` is always a `(database, code)` **tuple**
- every exchange needs `input`, `amount`, `type`
- referenced databases must already exist

---

## LCIA methods

```python
bd.methods                                  # all available
[m for m in bd.methods if 'IPCC' in str(m)]  # find one
method = bd.Method(('IPCC 2021', 'climate change', 'GWP 100a'))
method.load()

# custom method
my = bd.Method(('my method', 'climate'))
my.validate(cfs); my.register(); my.write(cfs)
```
Method keys are tuples. `cfs` is `[(flow_key, factor), …]`.

---

## LCA calculation

```python
lca = bc.LCA({act: 1000}, method_key)
lca.lci()      # solve inventory:      s = A⁻¹f,  g = Bs
lca.lcia()     # characterise:         score = CF · g
lca.score
lca.inventory
lca.characterized_inventory
lca.technosphere_matrix; lca.biosphere_matrix
```

Order matters: `lci()` before `lcia()` before `.score`. This mirrors the underlying
algebra exactly — `lci()` solves `s = A⁻¹f` and `g = Bs`; `lcia()` applies `CF · g`.
Saying so makes the API feel less arbitrary.

Recalculating after changing the demand:
```python
lca.redo_lci({other_act: 1})
lca.redo_lcia({other_act: 1})
```

---

## Monte Carlo

```python
mc = bc.LCA({act: 1000}, method_key, use_distributions=True)
mc.lci(); mc.lcia()
results = [mc.score for _ in zip(range(500), mc)]
```

Uncertainty on an exchange. The notebooks use the named constants from `stats_arrays`
rather than bare integers:

```python
from stats_arrays import LognormalUncertainty

exc['uncertainty type'] = LognormalUncertainty.id      # an integer, not a float
exc['loc']   = np.log(exc['amount'])                   # log of geometric mean
exc['scale'] = np.log(1.01)                            # log of geometric SD
exc.save()
```

Two things students get wrong here:

1. **`loc` and `scale` are logs.** `scale = np.log(1.2)`, not `1.2`. Nearly everyone gets
   this wrong once, and it produces no error — just a wrong distribution.
2. **Negative amounts must be negated before taking the log.** Technosphere inputs are
   negative, and `np.log()` of a negative number is undefined. Notebook 5 does:
   ```python
   fuel_exc['loc'] = np.log(-fuel_exc['amount'])       # note the minus
   ```
   The sign lives in `amount`; the distribution is defined on the magnitude.

Uncertainty type codes: `0` undefined, `1` no uncertainty, `2` lognormal, `3` normal,
`4` uniform, `5` triangular. Prefer the named constants (`LognormalUncertainty.id`,
`NormalUncertainty.id`, …) rather than bare integers.

**Comparative Monte Carlo — dependent sampling:**
```python
mc = bc.LCA(demand_a, method_key, use_distributions=True)
mc.lci(); mc.lcia()
for _ in zip(range(500), mc):        # one A matrix per iteration
    for d in [demand_a, demand_b]:
        mc.redo_lcia(d)              # both alternatives, SAME draw
        results[d].append(mc.score)
```
The shared draw is what makes paired tests valid.

---

## Ecoinvent import

```python
import bw2io as bi
bi.import_ecoinvent_release(
    version='3.11',
    system_model='consequential',
    username='...', password='...')
```
Needs `ecoinvent_interface` installed and a valid licence. Brings `biosphere3` with it.
Takes several minutes with no progress indicator — students think it has hung.

Version and system model are strings: `'3.11'`, `'3.10'`; `'cutoff'`, `'consequential'`,
`'apos'`.

---

## Sensitivity analysis

OAT — perturb, recompute, compare:
```python
lca.technosphere_matrix[row, col] = new_value
lca.redo_lci(); lca.lcia()
```

GSA uses `SALib` outside Brightway:
```python
from SALib.sample import fast_sampler
from SALib.analyze import fast
param_values = fast_sampler.sample(problem, N)
Si = fast.analyze(problem, Y)
Si['S1']; Si['ST']
```
`S1` first-order (this parameter alone), `ST` total (including interactions). `ST > S1`
means interaction effects — the interpretive point of notebook 8.

---

## When unsure

Brightway moves. If uncertain about a call, say so and suggest checking:
- <https://docs.brightway.dev>
- <https://github.com/brightway-lca>

A student sent to the docs is better served than a student sent to a plausible-looking
method that does not exist.
