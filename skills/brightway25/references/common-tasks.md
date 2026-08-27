# Common tasks

Short, complete recipes for things people do constantly. Each one is runnable as written —
substitute the names, do not fill in gaps.

Reach for this when the question is "how do I *do* X", rather than a concept or an error.

---

## Coming from SimaPro

The same operations, differently expressed. Useful for orienting someone quickly.

| In SimaPro | In Brightway |
|---|---|
| Pick a process, click calculate | `bc.LCA({act: 1}, method_key)` then `.lci()`, `.lcia()`, `.score` |
| Choose an impact method from a dropdown | Look the key up in `bd.methods`, pass it to `LCA` |
| Browse the database tree | `db.search("...")` or a comprehension filtering on `name`/`location` |
| Edit a value in a process | Find the exchange, set `exc['amount']`, `exc.save()` |
| Allocation setting in preferences | **No setting.** Pre-calculate allocated values, or express avoided production as a `substitution` exchange |
| Tree view of contributions | `bwa.print_recursive_calculation(...)` — see below |
| Uncertainty on a parameter | Fields on the exchange (`uncertainty type`, `loc`, `scale`), then `use_distributions=True` |
| One project file holding everything | A *project* holding several databases |

Two differences worth naming out loud, because they surprise people:

- **Nothing is guessed.** SimaPro resolves a process by name from a menu. Brightway
  resolves an exchange by an exact `(database, code)` pair. There is no fuzzy matching, so
  finding the right code is a step of its own.
- **Ecoinvent is read-only in practice.** To change a background process, copy what you
  need into your own foreground database and edit the copy.

---

## Find the right activity in ecoinvent

Searching is easy; **choosing between the results is the hard part**, and it is a modelling
decision rather than a syntax problem. A search for electricity in ecoinvent returns dozens
of near-identical entries.

### See what you actually got

Print the fields that distinguish them, not just the names:

```python
ei = bd.Database('ecoinvent-3.11-consequential')      # your actual name

for a in ei.search('electricity, medium voltage', limit=30):
    print(f"{a['location']:<8} | {a.get('reference product',''):<28} | {a['name']}")
```

Sorting by location first makes the list readable — the same activity usually appears once
per region.

### What the differences mean

| Field | What it decides |
|---|---|
| `location` | Where the process happens. `DK`, `RER` (Europe), `GLO` (global), `RoW` (rest of world). Use the most specific one your system justifies |
| `reference product` | What the activity *produces*. Two activities can share a name and produce different things |
| **market** vs **production** in the name | A *market* includes distribution and the regional supply mix; a *production* activity is one specific route. For an input you buy, the market is usually right |
| voltage / grade / technology in the name | High/medium/low voltage, primary/secondary material, and so on — match your actual system |
| system model (in the database name) | cutoff, consequential, APOS. Chosen once for the whole study, not per activity |

**"market for X" versus "X production"** is the distinction people get wrong most often. If
your process consumes electricity from the grid, you want the market. If you are modelling
a specific power plant, you want the production activity.

### Narrow to one

Once you know which you want, filter exactly rather than taking `[0]`:

```python
hits = [a for a in ei
        if a['name'] == 'market for electricity, medium voltage'
        and a['location'] == 'DK']

print(len(hits), 'match')          # expect exactly 1
act = hits[0]
print(act['name'], '|', act['location'], '|', act['code'])
```

If `len(hits)` is not 1, do not proceed — either the filter is too loose, or the exact name
is different from what you assumed. `[0]` on an unchecked list is how the wrong activity
ends up in a study.

Keep the **code**, not the `id`, if you are recording which activity you used — see
`linking.md`.

---

## Calculate the impact of one process

```python
import bw2data as bd
import bw2calc as bc

bd.projects.set_current('my_project')

# 1. Find the activity. Search, then narrow by location — expect many near-identical hits.
ei = bd.Database('ecoinvent-3.11-consequential')      # your actual database name
hits = [a for a in ei.search('market for electricity, medium voltage', limit=50)
        if a['location'] == 'DK']
for a in hits:
    print(a['code'], '|', a['name'], '|', a['location'])

act = hits[0]                                          # check the list before taking [0]

# 2. Find the method. Never type the key from memory — the wording varies by release.
for m in bd.methods:
    if 'IPCC' in str(m) and 'GWP100' in str(m):
        print(m)

method_key = ...                                       # paste one of the printed keys

# 3. Calculate
lca = bc.LCA({act: 1}, method_key)
lca.lci()
lca.lcia()
print(lca.score, bd.methods[method_key]['unit'])
```

Which of the near-identical hits to use is a modelling decision — geography, market vs
production, system model — not a search problem.

---

## Change the amount of an exchange

Two situations, and people conflate them.

**Permanently, in the database:**

```python
act = bd.Database('my_foreground').get('my_activity')

for exc in list(act.exchanges()):          # list() — see the note below
    if exc.input['name'] == 'market for electricity, medium voltage':
        print('was', exc['amount'])
        exc['amount'] = 12
        exc.save()                          # without save() nothing is written
        print('now', exc['amount'])
```

Two things that bite:

- **`list()` around `act.exchanges()`.** It returns a generator, which can only be consumed
  once — a second loop over it silently does nothing, with no error.
- **`exc.save()`.** Changing `exc['amount']` in memory does nothing on its own.

**Temporarily, for a what-if:** scale the functional unit instead of editing data.

```python
lca = bc.LCA({act: 1}, method_key)
lca.lci(); lca.lcia()
print('baseline', lca.score)

lca.redo_lcia({act: 1.2})                   # 20% more of the same activity
print('scaled  ', lca.score)
```

This scales the *whole* activity, not one input. To vary a single input, edit the exchange,
recalculate, and set it back — that is what the sensitivity-analysis code does.

---

## Copy an ecoinvent process so you can modify it

Ecoinvent should be treated as read-only. To change a background process:

```python
source = bd.get_activity(('ecoinvent-3.11-consequential', 'some_code'))
mine   = source.copy(code='my_modified_electricity', database='my_foreground')

for exc in list(mine.exchanges()):
    if exc.input['name'] == 'hard coal':
        exc['amount'] = exc['amount'] * 0.5
        exc.save()
```

The copy keeps all the original's exchanges, so only the changes need writing.

---

## See what contributes most

```python
import bw2analyzer as bwa

act = bd.get_activity(('my_foreground', 'my_activity'))
bwa.print_recursive_calculation(act, method_key, amount=1, max_level=2)
```

`max_level` is how many steps up the supply chain to walk: level 1 is the activity's direct
inputs, level 2 their inputs, and so on. Ecoinvent chains are deep — start at 2, since 3 or
more usually produces more output than anyone reads.

For a sortable table rather than a printed tree, see `official-bw25.md`.

---

## Add uncertainty to one exchange

```python
import numpy as np
from stats_arrays import LognormalUncertainty

for exc in list(act.exchanges()):
    if exc.input['name'] == 'market for electricity, medium voltage':
        amount = exc['amount']
        exc['uncertainty type'] = LognormalUncertainty.id
        exc['loc']   = np.log(abs(amount))       # abs(): log of a negative is undefined
        exc['scale'] = np.log(1.2) / 1.96        # ±20% at 95% — see below
        if amount < 0:
            exc['negative'] = True               # required, or draws come back positive
        exc.save()
```

**Decide what the uncertainty figure means before writing it.** `scale = np.log(1.2)` is a
geometric standard deviation of 1.2 — a 95% range of about −30%/+43%, a factor of two end
to end. For ±20% at 95%, divide by 1.96 as above. `lca-in-brightway.md` has the full table.

---

## Run a Monte Carlo

```python
mc = bc.LCA({act: 1}, method_key, use_distributions=True)
mc.lci()
mc.lcia()

results = [mc.score for _ in zip(range(500), mc)]

import numpy as np
print('nominal-ish median', np.median(results))
print('mean              ', np.mean(results))
print('95% range         ', np.percentile(results, [2.5, 97.5]))
```

Without `use_distributions=True` you get the same number 500 times. Same if no exchange in
the system carries uncertainty — ecoinvent does, a hand-built foreground usually does not
until you add it.

The mean sitting above the deterministic score is expected, not a bug: lognormal
distributions are right-skewed. Compare the median.

---

## Check what is in a database

```python
db = bd.Database('my_foreground')
print(len(db), 'activities')

for a in db:
    print(a['code'], '|', a['name'], '|', a.get('location'))

act = db.get('some_code')
print(act.as_dict())

for exc in list(act.exchanges()):
    print(f"{exc['amount']:>10}  {exc['type']:<14} {exc.input['name']}")
```

The last loop is the quickest way to see whether an activity is wired up as intended.
