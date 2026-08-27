# Linking foreground to background

Connecting a foreground product system to ecoinvent and the biosphere. The mechanism is
simple; the failure modes are numerous and the errors are unhelpful. Almost every failure
comes down to a small number of causes.

---

## How linking actually works

Brightway has no fuzzy matching, no "find the closest activity", no name resolution. An
exchange points at exactly one thing:

```python
{'input': ('database name', 'code'), 'amount': 2, 'type': 'technosphere'}
```

That tuple is the entire linking mechanism. Brightway looks up that exact key. If nothing
is there, the exchange is **unlinked** and the database will not calculate.

So linking = **getting a `(database, code)` pair right**. Everything below is about how
those pairs go wrong.

**Consequence worth stating out loud:** you must know the code of the ecoinvent activity
*before* you can link to it. There is no way to write "electricity, DK" and have
Brightway work out what you meant. Finding the code is a separate step, and it is a
modelling decision, not a lookup.

---

## Three databases, three identifier formats

A typical foreground system references three different databases, and each uses a
different kind of code. This trips people up constantly, because they all sit in the same
column of a spreadsheet.

| Database | Example code | Format |
|---|---|---|
| Your foreground | `Electricity production` or `a7d34649-9c10-4423-bac3-ecab9b43b20c` | Whatever you chose — a name or a UUID |
| ecoinvent | `7a6115b0457d395cd2ffb09edb920931` | 32 hex characters, **no dashes** |
| biosphere | `349b29d1-3e58-4c66-98b9-9d1a076efd2e` | 36 characters, **with dashes** |

The biosphere and ecoinvent formats differ. Mixing them up produces a `KeyError` that
looks like a typo but is actually the wrong database.

Database names must match **exactly**, including version and system model:

```
ecoinvent-3.11-consequential      ✓ (whatever your import created)
ecoinvent-3.11-biosphere          ✓
ecoinvent 3.11 consequential      ✗ spaces instead of dashes
ecoinvent-3.11-cutoff             ✗ if you imported consequential
```

Always check what actually exists rather than assuming:

```python
import bw2data as bd
print(list(bd.databases))
```

---

## Finding the code of an ecoinvent activity

The practical workflow, and the part that is genuinely LCA work rather than Python:

```python
ei = bd.Database('ecoinvent-3.11-consequential')

# search by name
results = ei.search('electricity market medium voltage', limit=20)
for a in results:
    print(a['code'], '|', a['name'], '|', a['location'])
```

You will get many near-identical hits. **Choosing between them is a modelling decision** —
which geography, which voltage level, market vs production activity. Do not just take the
first result.

Filtering more precisely:

```python
hits = [a for a in ei
        if a['name'] == 'market for electricity, medium voltage'
        and a['location'] == 'DK']
print(len(hits), hits[0]['code'] if hits else 'nothing found')
```

Then use `hits[0].key` — which is exactly the `(database, code)` tuple you need.

For biosphere flows:

```python
bio = bd.Database('ecoinvent-3.11-biosphere')
co2 = [f for f in bio
       if f['name'] == 'Carbon dioxide, fossil'
       and f['categories'] == ('air',)]
```

Biosphere flows are distinguished by **categories** as well as name — the same substance
exists for air, water and soil, and for different subcompartments. Picking the wrong
compartment gives a result with no error.

---

## Linking via the course spreadsheet template

> **Which Excel route?** This layout belongs to the course's `lci_to_bw2()` helper. Brightway's own
> `bi.ExcelImporter` uses a different, block-structured workbook and cannot read this
> format — see `official-bw25.md` if the person is not following the course.

A typical spreadsheet template links through two columns: **`Exchange database`** and
**`Exchange input`**. Together they form the tuple.

| Activity database | Activity code | Exchange database | Exchange input | Exchange type |
|---|---|---|---|---|
| `mydb` | `Electricity production` | `mydb` | `Electricity production` | `production` |
| `mydb` | `Electricity production` | `mydb` | `Fuel production` | `technosphere` |
| `mydb` | `Electricity production` | `ecoinvent-3.11-consequential` | `7a6115b0…` | `technosphere` |
| `mydb` | `Electricity production` | `ecoinvent-3.11-biosphere` | `349b29d1-…` | `biosphere` |

Read row by row: **each row is one arrow**, from the activity named in the first columns
to the thing named in the exchange columns.

Rules that are easy to get wrong:

- The **production** exchange points at the activity itself — same database, same code
- Foreground-to-foreground exchanges use your own database name
- ecoinvent inputs use the ecoinvent database name and a 32-character code
- Biosphere flows use the biosphere database name and a dashed UUID
- Every activity needs exactly one production exchange

---

## Diagnosing unlinked exchanges

When `.write()` fails or a calculation misbehaves, find out *which* exchange is broken
rather than re-reading the whole spreadsheet:

```python
import bw2data as bd

db = bd.Database('mydb')
existing = {}
for name in bd.databases:
    existing[name] = {a['code'] for a in bd.Database(name)}

for act in db:
    for exc in act.exchanges():
        dbname, code = exc['input']
        if dbname not in existing:
            print(f"MISSING DATABASE: {dbname}  (in {act['name']})")
        elif code not in existing[dbname]:
            print(f"MISSING CODE: {code} in {dbname}  (in {act['name']})")
```

This turns "something is wrong" into a specific list of broken links. Run it before
debugging anything else.

To check a single suspected link:
```python
try:
    print(bd.get_activity(('ecoinvent-3.11-consequential', '7a6115b0…')))
except Exception as e:
    print('not found:', e)
```

---

## "My score is zero" — the differential

Several different faults produce a zero or implausibly low score, all without an error.
Work through them in this order:

1. **Dangling links** — an exchange points at a `(database, code)` that does not exist. Run
   the diagnostic loop above. Most common by far.
2. **Nothing connects to the background** — links resolve, but the foreground only
   references itself. Check that technosphere exchanges point into ecoinvent.
3. **Wrong biosphere compartment** — the flow exists but sits in `('air',)` when the method
   characterises `('air', 'urban air close to ground')`, or similar. Right link, no
   characterisation.
4. **The method does not characterise these flows** — flows absent from the method get a
   factor of zero. `method.load()` and check your flows are in it.
5. **All amounts are zero** — a spreadsheet import that read the wrong column.
6. **The functional unit is wrong** — demanding an activity that is not the one you think,
   or an amount of zero.

Faults 3 and 4 are the ones people miss, because the link diagnostic comes back clean.

## Common linking failures

| Symptom | Cause |
|---|---|
| `KeyError: ('ecoinvent-3.11-consequential', '…')` | Code does not exist in that database — wrong code, or wrong system model |
| `KeyError` on a biosphere flow | Used the ecoinvent code format (no dashes) instead of the biosphere one, or the flow is in a different compartment |
| Database name not found | Name does not match exactly — check `list(bd.databases)` |
| `.write()` fails with a validation error | An exchange is missing `input`, `amount` or `type`, or `input` is a list instead of a tuple |
| Everything imports but the score is zero | Foreground is not actually connected to anything — check that technosphere exchanges point at real background activities |
| Score is suspiciously small | Some exchanges silently unlinked or amounts wrong; run the diagnostic loop above |
| Results change after re-importing ecoinvent | `id` values differ between installations — never link by `id`, always by `code` |
| Works locally, fails on a colleague's machine | Same cause: `id` is installation-specific, `code` is portable |

---

## Why `code`, never `id`

Worth understanding rather than memorising, because it explains a whole class of bugs.

- **`code`** — a string you or ecoinvent chose. Stable. Portable. What linking uses.
- **`id`** — an integer assigned by *this* installation, and it is the row/column position
  in the A matrix. It depends on what else happens to be in the database.

**One legitimate use of `id`.** You will see `{act.id: 1}` as a demand key in Monte Carlo
code, and that is fine — a demand dict is transient, built and consumed inside one session,
where `id` is valid and slightly faster. The rule is about **stored** references: exchange
`input` tuples, saved data, anything shared or written to disk. Transient demand key: fine.
Stored link: never.

So `id` will point at a different activity on someone else's machine, or after you
re-import. Any workflow that shares data — a collaboration, a published supplement, a
reproducibility check — must use `code`.

Same distinction as in the matrix formulation: `id` is a coordinate, `code` is a name.
