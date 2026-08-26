# Course map — Course-material-bw25

Ten notebooks. Use this to orient: what a notebook teaches, what a student must already
understand to follow it, and where the difficulty actually sits.

**The difficulty curve is not what it looks like.** Notebooks 0–4 look easy (small
files, simple ideas) but are where Python-unfamiliar students lose the most time — the
LCA is straightforward and the Python is not. Notebooks 5–8 look hard (big files, real
statistics) but the code is largely given; the struggle is conceptual. Route accordingly:
0–4 skews ASSIST, 5–8 skews TUTOR. Do not apply that mechanically — a method question in
notebook 1 is still a method question.

---

## Setup — `Project_create_and_locate.ipynb`

Projects, project directories, where Brightway stores data on disk.

- `projects.create_project()`, `set_current()`, `projects.report()`, `delete_project()`
- Custom storage via `os.environ['BRIGHTWAY2_DIR']`
- Locking for synced folders: `bw.config.p['lockable'] = True`

**Uses the legacy `import brightway2 as bw` API** — the only notebook in this folder that
does. Expect confusion when students compare it to notebooks 1+. See `bw25-api.md`.

**Gotchas:** `BRIGHTWAY2_DIR` must be set *before* importing Brightway, and changing it
mid-session needs a kernel restart. Both are classic sources of "my project disappeared".

---

## 0 — `0-LCI-matrix.ipynb` · LCI as linear algebra

The foundation: **g = B A⁻¹ f**. Pure NumPy, no Brightway at all.

- `A` technology matrix (negative = input), `B` intervention matrix, `f` demand vector
- Scaling vector `s = A⁻¹f`, inventory `g = Bs`, then `LCIA = CF · g`
- The classic electricity/fuel example from the course textbook

**Prerequisites:** matrix multiplication, matrix inverse. Some students will need this
refreshed — do it without condescension.

**Uses `np.matrix` deliberately** so `*` reads as matrix multiplication. See the trap note
in `SKILL.md` — switching to `np.array` breaks results *silently*.

**Discussion question in the notebook:** if the maths is this simple, why do we need LCA
software? (Answer involves scale, data management, uncertainty, matrix sparsity — good
tutor material.)

**Homework:** rewrite using the textbook's technology matrix format.

---

## 1 — `1-Simple-LCA.ipynb` · First Brightway LCA

The same textbook system, now in Brightway.

- `bd.Database(...).write({...})` with nested activity/exchange dicts
- Exchange `type`: `'production'`, `'technosphere'`, `'biosphere'`, `'substitution'`
- Custom LCIA method: `bd.Method()`, `.validate()`, `.register()`, `.write()`, `.load()`
- `bc.LCA(fu)`, `.lci()`, `.lcia()`, `.score`, `.characterized_inventory`
- Two modelling styles: everything in one database vs. technosphere/biosphere separated
  (the latter closer to how ecoinvent works). Both must give identical results.

**Prerequisites:** notebook 0. Nested dicts and tuple keys — see `python-primer.md`.

**Hard parts:** the nested dict structure is genuinely intimidating on first contact;
substitution exchanges and sign conventions; why `lci()` must precede `lcia()`.

**Exercise:** model the "Heat production" system from the slides in both Excel and
Brightway. Optional: build a product system from your own data.

---

## 2 — `2-Navigate.ipynb` · Exploring a database

Getting at what is actually stored.

- `.get()`, `.as_dict()`, `.exchanges()`, `.items()`, `exc.input` / `exc.output`
- Activities behave like dicts; exchanges too
- `code` (UUID string) vs `id` (integer matrix coordinate)
- Exchange input/output map to matrix rows and columns — ties back to notebook 0

**Prerequisites:** notebook 1. Dict iteration, `list()` on generators, comprehensions.

**Hard parts:** `.exchanges()` returns a generator, so it looks empty when printed and
can only be consumed once. Very common confusion — see `errors.md`.

**Exercise:** retrieve exchanges by name rather than by index; extract a CO₂ value for
later computation.

---

## 3 — `3-Ecoinvent.ipynb` · Real background data

Scaling up from toy systems to ecoinvent.

- `bi.import_ecoinvent_release(version='3.11', system_model='consequential', username=…, password=…)`
- Requires ecoinvent credentials and `ecoinvent_interface` installed
- `.search()` with `limit` and `filter`; `.get(code)`; comprehension-based filtering
- Linking a foreground system to ecoinvent and to `biosphere3`

**Prerequisites:** notebooks 1–2, working install, valid licence.

**Hard parts:** import is slow and looks hung; credentials fail confusingly; searching a
20 000-activity database returns near-identical activities differing only by location or
system model — choosing correctly is a *method* question, not a search-syntax question.

**Expected warning:** "Not able to determine geocollections for all datasets" — harmless,
reassure and move on.

**Exercise:** link foreground emissions to biosphere, connect to ecoinvent, compute a
carbon footprint with the ILCD climate change method.

---

## 4 — `4-Excel-import.ipynb` · Your own inventory data

Getting real data in from a spreadsheet.

1. Build inventory in the Excel template → 2. export CSV (avoids encoding problems) →
3. `from lci_to_bw2 import *` → 4. `pd.read_csv()` and clean → 5. `lci_to_bw2(df)` →
6. `bd.Database(...).write(db)`

- `lci_to_bw2.py` (Massimo Pizzol, 2017) converts a DataFrame to a Brightway dict
- Column layout matters: first five columns are `Activity …`, the rest `Exchange …`
- Uncertainty fields can be carried through at import

**Prerequisites:** notebooks 1–3, basic pandas.

**Hard parts:** the CSV format is unforgiving — column names, ordering, and
`Activity type == 'biosphere'` rows all matter. Most failures here are data-shape
failures, not code failures. Check the CSV before debugging the code.

**Known errors:** database locked (two notebooks open on one project), encoding issues
(use CSV, not xlsx), missing geocollections (harmless).

**Exercise:** groups build a product system in Excel, import it, then *exchange data with
another group* and try to reproduce their results — a reproducibility exercise as much as
a technical one.

---

## 5 — `5-Monte-Carlo.ipynb` · Uncertainty propagation

First probabilistic notebook. **Tutor territory.**

- Lognormal distributions for environmental data; `loc` = log of geometric mean,
  `scale` = log of geometric standard deviation
- `mc = bc.LCA(demand={act: amount}, method=m, use_distributions=True)`
- `mc_results = [mc.score for _ in zip(range(500), mc)]`
- Compare stochastic mean/median against the nominal deterministic score
- Histograms via `plt.hist()`, summaries via `df.describe()`

**Prerequisites:** notebooks 1–2. Basic probability — distribution, mean vs median.

**Hard parts:** `loc`/`scale` being *logs* trips up nearly everyone. The
`[... for _ in zip(range(500), mc)]` idiom is opaque — see `python-primer.md`. Also: why
the MC mean does not equal the nominal score (a genuinely instructive surprise, worth
tutoring rather than explaining away).

---

## 6 — `6-Comparative-Monte-Carlo.ipynb` · Comparison done properly

**The methodological centrepiece of the course** (197 KB, the largest notebook).

- Comparing alternatives that deliver the same functional unit
- **Key idea:** sample *one* A matrix per iteration and evaluate all alternatives against
  it — dependent sampling — rather than sampling independently per alternative
- Consequences: lower variance, fewer iterations needed, and **paired statistical tests
  become valid**
- `mc.redo_lcia(demand)` re-scores under the same random draw
- Box plots, scatter plots, `df.describe()`, paired tests

**Prerequisites:** notebook 5. Paired vs unpaired tests.

**Hard parts:** *why* dependent sampling is legitimate rather than cheating — this is the
central conceptual hurdle of the course and deserves the full tutoring ladder. Also: what
`redo_lcia()` actually reuses, and why comparing independently-sampled distributions by
eye is a weaker claim than a paired test.

**Exercises:** 100-iteration MC on a random ecoinvent process; compare EURO5 vs EURO6
lorry transport using the comparative approach; visualise and interpret.

---

## 7 — `7-ALIGNED-OAT-sensitivity-analysis.ipynb` · Local sensitivity

- One-at-a-time: perturb each parameter by 10%, hold others fixed, recompute
- Sensitivity ratio (see the notebook for the source)
- Loop over foreground exchanges, modify the matrix, `redo_lci()` then `lcia()`
- Rank parameters by influence
- Baseline in the notebook: 180.28 kg CO₂-Eq, fictional biobased product system

**Prerequisites:** notebooks 1–5.

**Hard parts:** OAT results are *local* and students routinely over-generalise them. The
notebook says so explicitly — "the effect of a change in the parameter might be different
when other parameters assume different values… so OAT can be misleading!" That warning is
the pedagogical point of the notebook and the bridge to notebook 8. Tutor it; don't let it
slide past.

---

## 8 — `8-ALIGNED-Global-sensitivity-analysis.ipynb` · Global sensitivity

Where OAT fails and what replaces it.

- Correlation analysis (Pearson) as a first pass
- **FAST** (Fourier Amplitude Sensitivity Test) via `SALib`
- First-order `S1` vs total-order `ST` indices — the difference is the teaching point
- Same biobased system; result: `par3` (product required during use) dominates,
  S1 = 0.934

**Prerequisites:** notebooks 5–7. Variance decomposition — conceptually, not formally.

**Hard parts:** what S1 and ST actually mean, and why ST > S1 indicates interaction
effects. Also why GSA needs far more model runs than OAT. Students may need reassurance
that they are not expected to derive FAST — they need to *interpret* it.

---

## Suggested dependency order

```
Project_create_and_locate  →  0  →  1  →  2  →  3  →  4
                                     ↓
                                     5  →  6
                                     ↓
                                     7  →  8
```

5 needs only 1–2, so a student blocked on ecoinvent credentials (3) can still progress
through the uncertainty material. Worth knowing when someone is stuck on setup — do not
let an install problem stall the whole course for them.
