# Official Brightway 2.5 workflows

The standard, non-course way of doing things — drawn from the official tutorial at
<https://learn.brightway.dev/en/latest/content/chapters/BW25/BW25_introduction.html>.

Reach for this when someone is **not** following the Advanced LCA course: importing a
spreadsheet with `bw2io`'s own importer, running many activities against many methods, or
doing contribution analysis. The course notebooks use a custom helper (`lci_to_bw2.py`)
that is not a published package; everything here is standard Brightway.

> **BW25 is officially still in beta.** Breaking changes happen between releases. If
> something documented here does not match the installed version, believe the installed
> version and say so rather than insisting.

---

## Packages

```python
import bw2data as bd      # projects, databases, activities, methods
import bw2io as bi        # importers
import bw2calc as bc      # calculations
import bw2analyzer as bwa # contribution analysis
```

`bw2analyzer` is the one people miss — it does contribution analysis without hand-rolled
matrix work.

---

## Importing a foreground database from Excel

**This is the standard import path**, and it is not what the course notebooks use. Prefer
it for anyone working outside that course.

```python
fg = bi.ExcelImporter("my_inventory.xlsx")
fg.apply_strategies()

# Match internally first, then against each background database
fg.match_database(fields=["name", "unit", "location"])
fg.match_database("ecoinvent-3.11-cutoff",
                  fields=["name", "unit", "location", "reference product"])
fg.match_database("ecoinvent-3.11-biosphere",
                  fields=["name", "categories", "location"])

fg.statistics()          # how many datasets, exchanges, and unlinked
fg.write_database()      # only once statistics look right
```

Database names above are examples — read the real ones from `list(bd.databases)`.

**Choose `fields` to match what your spreadsheet actually contains.** Every field named
must be present on both sides; naming one your foreground lacks (`reference product` is the
usual culprit) makes the match silently do nothing. The official tutorial uses
`["name", "unit", "reference product", "location"]` for the internal match because its
example workbook carries all four.

### The workbook format

`bi.ExcelImporter` expects **Brightway's own block layout**, not an arbitrary spreadsheet:
a `Database` block with the database name and metadata, then repeated `Activity` blocks,
each followed by an `Exchanges` block whose first row is the column headers. Block keywords
go in the first column.

This is **not** the flat `Activity database | Activity code | Exchange database | Exchange
input` layout described in `linking.md` — that one belongs to the course's `lci_to_bw2()`
helper and `ExcelImporter` cannot read it. Pointing `ExcelImporter` at a course-style sheet
produces an empty or malformed import.

If someone needs a starting template, the reliable route is
`bi.create_default_excel_template()` if available in their version, or the example workbook
from the official tutorial — rather than describing the layout from memory.

### The order matters

`apply_strategies()` normalises the data; `match_database()` resolves exchanges against a
target. Matching before applying strategies leaves things unlinked that should have
matched.

### Unlinked exchanges

`statistics()` reports them. To see exactly which:

```python
list(fg.unlinked)
```

**Do not call `write_database()` while anything is unlinked** — those exchanges are
silently dropped, and the result is a database that calculates but gives a wrong (usually
too low) answer.

Fixing them means one of:

- correcting the name, unit, location or reference product in the spreadsheet so it matches
  the target exactly
- adding another `match_database()` call with different `fields`
- for genuinely new biosphere flows, adding them to the biosphere database:

```python
fg.add_unlinked_flows_to_biosphere_database()
fg.apply_strategies()
fg.statistics()
fg.write_database()
```

Match fields differ by target: technosphere activities match on
`name / unit / location / reference product`; biosphere flows on
`name / categories / location`. Using technosphere fields against the biosphere is a
common cause of "nothing matched".

---

## Importing ecoinvent

Two routes. The licensed API:

```python
if 'ecoinvent-3.11-cutoff' in bd.databases:
    print('already present')
else:
    bi.import_ecoinvent_release(
        version='3.11',
        system_model='cutoff',      # cutoff / apos / consequential / EN15804
        username='...', password='...')
```

Or from downloaded ecospold2 files:

```python
ei = bi.SingleOutputEcospold2Importer(dirpath=r'<path>', db_name='<name>')
ei.apply_strategies()
ei.statistics()
ei.write_database()
```

Name databases consistently — `ecoinvent-<version>-<system model>` — since every link
depends on the exact string.

---

## Calculating: the datapackage pattern

The official tutorial builds an LCA through `prepare_lca_inputs`:

```python
fu, data_objs, _ = bd.prepare_lca_inputs({act: 1}, method=method_key)
lca = bc.LCA(demand=fu, data_objs=data_objs)
lca.lci()
lca.lcia()
lca.score
```

This is the data-centric form BW25 is moving toward: `prepare_lca_inputs` gathers the
matrices as datapackages, which can then be reused, stored or shipped.

The shorter form works too and is what the course notebooks use:

```python
lca = bc.LCA({act: 1}, method_key)
```

Both are valid. Use whichever the person is already writing; mention `prepare_lca_inputs`
when they need reusable data objects or are following the official docs.

---

## MultiLCA — many activities against many methods

Absent from the course material, and the right tool whenever someone is scoring several
alternatives across several impact categories.

```python
functional_units = {
    "alternative A": {actA.id: 1},
    "alternative B": {actB.id: 1},
}
config = {"impact_categories": list_of_method_keys}

data_objs = bd.get_multilca_data_objs(functional_units=functional_units,
                                      method_config=config)

mlca = bc.MultiLCA(demands=functional_units, method_config=config, data_objs=data_objs)
mlca.lci()
mlca.lcia()
mlca.scores
```

Two things to notice:

- **Demands are keyed by `.id`, not by the activity object.** This is the legitimate
  transient use of `id` — see `linking.md`. It is a demand dict built and consumed in one
  session, not a stored link.
- The outer keys ("alternative A") are labels you choose, and they come back in the results.

### Getting a results table out

`.scores` is a **flat dict keyed by `(method_key, functional_unit_label)`** — not a table.
Pivot it into the alternatives × categories matrix people actually want:

```python
import pandas as pd

df = pd.Series(mlca.scores).unstack(level=0)   # rows = alternatives, cols = methods
df.columns = [m[-1] for m in df.columns]        # last tuple element as a short label
df
```

`pd.DataFrame(mlca.scores)` does **not** work — a tuple-keyed flat dict does not reshape on
its own. Build the Series first and `unstack`.

If the orientation comes out transposed, swap `level=0` for `level=1`; which element of the
key comes first has varied between releases, so check rather than assume.

---

## Contribution analysis

`bw2analyzer` walks the supply chain so you do not have to:

```python
import bw2analyzer as bwa

bwa.utils.print_recursive_calculation(
    ("my_db", "my_activity"),
    method_key,
    amount=1,        # match the functional unit
    max_level=2,     # how deep to walk
)
```

For structured output instead of printed text:

```python
import pandas as pd

act = bd.get_activity(("my_db", "my_activity"))     # pass the activity, not the key
ca = bwa.utils.recursive_calculation_to_object(
    act, method_key, amount=1, max_level=2)
pd.DataFrame(ca)
```

`print_recursive_calculation` accepts either a key tuple or an activity;
`recursive_calculation_to_object` is less forgiving, so resolve the activity first. Both
names are also exported at package level (`bwa.print_recursive_calculation`), which is what
the docs use.

`max_level` matters: ecoinvent supply chains are deep, and 3 or more can produce an
unreadable amount of output. Start at 2.

If you want the numbers rather than a tree, sum the characterised inventory **per process**
and map the columns back to activities:

```python
import numpy as np

col_sums = np.array(lca.characterized_inventory.sum(axis=0)).ravel()
rev_act = lca.dicts.activity.reversed
contributions = sorted(
    ((v, bd.get_activity(rev_act[i])) for i, v in enumerate(col_sums) if v),
    reverse=True)[:10]
for score, act in contributions:
    print(f"{score:10.4f}  {act['name']}")
```

`print(lca.characterized_inventory)` on its own just shows a sparse-matrix summary — it is
flows × processes, not a contribution ranking.

---

## Inspecting uncertainty already in a database

ecoinvent ships with uncertainty on many exchanges. To see what an entry looks like:

```python
lognormals = [exc for exc in db.random().exchanges()
              if exc.get("uncertainty type") == 2]
if lognormals:
    print(lognormals[0].as_dict())
else:
    print("that activity has no lognormal exchanges — try another")
```

The guard matters: a foreground database you built yourself usually has **no** uncertainty
at all, and an unguarded `[0]` raises `IndexError`.

`uncertainty type == 2` is lognormal. This is a good way to show someone the real field
layout before they write their own — see `lca-in-brightway.md` for setting it.

---

## Monte Carlo, official form

```python
fu, data_objs, _ = bd.prepare_lca_inputs({act: 1}, method=method_key)
mc = bc.LCA(demand=fu, data_objs=data_objs, use_distributions=True)
mc.lci()
mc.lcia()
scores = [mc.score for _ in zip(mc, range(100))]
```

Note `zip(mc, range(100))` — the course notebooks write `zip(range(100), mc)`. Both collect
100 scores, because `range(100)` is the shorter iterable either way. They are not quite
identical: `zip` pulls left to right, so `zip(mc, range(100))` advances the sampler once
more before discovering `range` is exhausted — 101 draws for 100 scores. Harmless here, but
do not repeat the general claim that argument order never matters to `zip`; it does when an
argument has side effects.

---

## The matrix correspondence

The official tutorial states it as `h = CBA⁻¹f`:

| Symbol | Matrix | In Brightway |
|---|---|---|
| A | technosphere | `lca.technosphere_matrix` |
| B | biosphere | `lca.biosphere_matrix` |
| C | characterisation | applied by `lcia()` |
| f | demand vector | the functional unit |
| h | characterised result | `lca.characterized_inventory`, summing to `lca.score` |

Same algebra as `g = BA⁻¹f` followed by `CF · g` — `C` is just the characterisation step
written into one expression. See `lca-in-brightway.md`.

---

## When this file and the course notebooks disagree

They solve the same problems differently:

| Task | Course notebooks | Official |
|---|---|---|
| Spreadsheet import | `lci_to_bw2.py` (custom helper) | `bi.ExcelImporter` |
| Building an LCA | `bc.LCA({act: 1}, method)` | `prepare_lca_inputs` + `data_objs` |
| Many alternatives | loop with `redo_lcia()` | `bc.MultiLCA` |
| Contribution analysis | manual matrix work | `bw2analyzer` |

Neither is wrong. Match whichever the person is already using, and mention the alternative
only when it genuinely solves their problem better — for instance, `ExcelImporter` for
someone outside the course, who cannot be expected to have `lci_to_bw2.py`.
