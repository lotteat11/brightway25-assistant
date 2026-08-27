# How Brightway represents LCA

The conventions Brightway uses to express LCA concepts. Not LCA theory — the people using
this know that. This is the translation layer between LCA as they practise it and LCA as
Brightway expects it written, and it is where most confusion actually sits.

Explain any of this freely, without waiting to be asked.

---

## The matrices

Everything reduces to the same algebra:

```
s = A⁻¹f          scaling vector: how much of each activity is needed
g = B s           inventory: elementary flows
score = CF · g    characterised result
```

| | |
|---|---|
| **A** | Technosphere matrix. Square. Rows and columns are both products/activities |
| **B** | Biosphere matrix. Rows are elementary flows, columns are activities |
| **f** | Demand vector — the functional unit |
| **CF** | Characterisation factors from the LCIA method |

`lca.lci()` computes `s` and `g`. `lca.lcia()` applies `CF`. They are separate because they
answer different questions — *what is emitted*, then *how much does it matter*. That is why
`.score` raises if you skip them.

Access the matrices directly when you need to inspect or perturb them:

```python
lca.technosphere_matrix        # A
lca.biosphere_matrix           # B
lca.inventory                  # g, as a matrix
lca.characterized_inventory    # after lcia()
```

---

## Sign conventions

**This is a Brightway convention, not an LCA principle**, and it is worth saying so — it
prevents people looking for a methodological reason that does not exist.

| Exchange | Sign | Why |
|---|---|---|
| `production` | positive | output of the activity, the diagonal of A |
| `technosphere` input | **negative** | consumed by the activity |
| `biosphere` emission | positive | released to the environment |
| `biosphere` resource use | negative | taken from the environment |
| `substitution` | see below | avoided production |

Symptoms of getting it wrong: results with the wrong sign, or roughly double the expected
magnitude.

When in doubt, read the sign directly off A. The algebra is unambiguous where the API is
not:

```python
import numpy as np
print(lca.technosphere_matrix.toarray())
```

---

## Exchange types

What each type means *to Brightway*:

**`production`** — the activity's own output. Every activity needs **exactly one**. It sits
on the diagonal of A. Missing or duplicated production exchanges are the usual cause of a
singular matrix.

```python
{'input': ('mydb', 'electricity'), 'amount': 10, 'type': 'production'}
```

The `input` points at the activity itself — same database, same code.

**`technosphere`** — an input from another activity, in your foreground or in ecoinvent.
Negative. Becomes an off-diagonal entry in A.

**`biosphere`** — an elementary flow. Goes into B, not A. Points at a flow in the biosphere
database, not at an activity.

**`substitution`** — avoided production. See below.

---

## Multifunctionality: substitution and allocation

**Brightway does not partition for you.** This surprises people coming from SimaPro or
GaBi, where allocation is a setting.

**System expansion / substitution** is expressed directly:

```python
{'input': ('ecoinvent-3.11-consequential', 'heat_code'),
 'amount': 5, 'type': 'substitution'}
```

This says the activity avoids 5 units of heat production elsewhere. Substitution introduces
a **further sign flip** on top of the technosphere convention — this is exactly where sign
confusion compounds, so be explicit about which flip is which when helping.

**Partitioning / allocation** must be done **before** the data enters Brightway. Compute
the allocated amounts yourself and write those numbers. There is no allocation setting to
switch on.

If someone asks "how do I set allocation in Brightway?", the answer is that they do not —
they either use substitution, or they pre-calculate. That is a real answer, not an evasion,
and worth stating plainly.

---

## Foreground, background, biosphere

Three roles, three databases in one project:

| Role | What it holds | Who wrote it |
|---|---|---|
| Foreground | The system being modelled | You |
| Background | Upstream supply chains | ecoinvent |
| Biosphere | Elementary flows | Comes with the ecoinvent import |

The boundary between foreground and background is a **modelling decision**, not a technical
one. It matters in practice for sensitivity analysis, where typically only foreground
parameters are perturbed — worth flagging if someone is surprised that background
uncertainty is not showing up.

Mechanically, connecting them is just exchanges pointing across databases. See
`linking.md`.

---

## Functional unit

A dict mapping activity to amount:

```python
lca = bc.LCA({act: 1000}, method_key)
```

Multiple activities in one functional unit are allowed:

```python
lca = bc.LCA({act_a: 1, act_b: 0.5}, method_key)
```

This becomes `f`. Changing it and recalculating:

```python
lca.redo_lci({other_act: 1})     # new demand, full recalculation
lca.redo_lcia({other_act: 1})    # reuse inventory, recharacterise
```

`redo_lcia()` reusing the *same* sampled matrices is what makes dependent sampling work in
comparative Monte Carlo.

---

## LCIA methods

Identified by tuples, stored separately from databases:

```python
# Method keys are tuples whose exact shape depends on the database version.
# NEVER type one from memory — list them and copy the real one:
[m for m in bd.methods if 'IPCC' in str(m)][:5]
# ecoinvent 3.11, for example, uses a 4-tuple:
#   ('ecoinvent-3.11', 'IPCC 2021', 'climate change: fossil',
#    'global warming potential (GWP100)')
method = bd.Method(some_key_you_looked_up)
method.load()          # [(flow_key, factor), …]
```

A method is a list of `(flow, characterisation factor)` pairs — which is why building a
custom method is straightforward:

```python
my = bd.Method(('my method', 'climate'))
cfs = [(('biosphere_db', 'co2_code'), 1.0),
       (('biosphere_db', 'ch4_code'), 28.0)]
my.validate(cfs); my.register(); my.write(cfs)
```

Flows not listed get a factor of zero. A suspiciously low score sometimes means the method
simply does not characterise the flows in the inventory.

---

## Uncertainty

Uncertainty lives **on exchanges**, not on activities:

```python
from stats_arrays import LognormalUncertainty

exc['uncertainty type'] = LognormalUncertainty.id
exc['loc']   = np.log(exc['amount'])     # log of geometric mean
exc['scale'] = np.log(1.2)               # log of geometric SD
exc.save()
```

Three Brightway-specific points that are not obvious from LCA knowledge:

1. **`loc` and `scale` are logarithms** for lognormal distributions.
2. **Negative amounts must be negated before taking the log** — `np.log(-exc['amount'])`.
   The sign lives in `amount`; the distribution is defined on the magnitude.
3. **A negative amount also needs `exc['negative'] = True`.** Omit it and the sampler
   returns *positive* draws for what should be a negative technosphere input. No error, no
   traceback — just a sign error in the results. Always set it alongside the negated log.

```python
fuel_exc['uncertainty type'] = LognormalUncertainty.id
fuel_exc['loc']      = np.log(-fuel_exc['amount'])   # negate before the log
fuel_exc['scale']    = np.log(1.2)
fuel_exc['negative'] = True                          # required for negative amounts
fuel_exc.save()
```

### "I want 20% uncertainty" — ask what they mean

This request is ambiguous, and the ambiguity matters. `scale = np.log(1.2)` sets a
**geometric standard deviation** of 1.2, whose 95% interval is roughly **−30% to +43%** —
a factor of 2 from end to end, not ±20%. Someone who says "20%" usually means one of:

| They mean | Encode as |
|---|---|
| ±20% at 95% confidence, multiplicative | `scale = np.log(1.2)/1.96` → GSD ≈ 1.098, giving −17%/+20% |
| A GSD of 1.2 (a common pedigree-style default) | `scale = np.log(1.2)` → −30%/+43% |
| ±20% hard bounds, no tail | `UniformUncertainty` with `minimum`/`maximum` |
| ±20% most likely at nominal | `TriangularUncertainty` with `minimum`/`maximum` |

Ask before writing the number. Getting this wrong produces a plausible-looking
distribution that misstates the uncertainty by a factor of two or more — and nothing in
the output reveals it.

Bounded distributions use different fields:

```python
from stats_arrays import UniformUncertainty, TriangularUncertainty

exc['uncertainty type'] = UniformUncertainty.id
exc['minimum'], exc['maximum'] = 0.8 * amount, 1.2 * amount

exc['uncertainty type'] = TriangularUncertainty.id
exc['loc'] = amount                                   # the mode, NOT a log here
exc['minimum'], exc['maximum'] = 0.8 * amount, 1.2 * amount
```

Note `loc` is a log only for lognormal. For triangular it is the mode, in the original
units. Mixing that up is easy.

Monte Carlo then samples those distributions:

```python
mc = bc.LCA(demand, method, use_distributions=True)
```

Without uncertainty data on any exchange, Monte Carlo correctly returns the deterministic
result every iteration. That looks broken but is not.

---

## What Brightway does not do

Worth saying early, because assuming otherwise wastes time:

- **No allocation.** Pre-calculate, or use substitution.
- **No fuzzy matching.** Exchanges point at exact `(database, code)` tuples.
- **No unit conversion.** Units are metadata; Brightway does not check or convert them. A
  mismatch produces a wrong number with no warning.
- **No automatic regionalisation.** The geocollections warning refers to this; it is not
  needed for standard LCA.
- **No validation that your model is sensible.** It will happily calculate a system with
  the wrong sign throughout.
