# Exercises embedded in the notebooks

Extracted from the `Course-material-bw25` notebooks in
[advanced-lca-notebooks](https://github.com/massimopizzol/advanced-lca-notebooks) so they
can be seen in one place. These are the exercises **already in the notebooks** — not new
ones. Wording is condensed; the notebooks remain the authority.

---

## 0 — LCI matrix algebra

**Discussion.** If the mathematics is just `g = BA⁻¹f`, why do we need LCA software at all?

*Worth drawing out: scale (ecoinvent is ~20,000×20,000), sparse matrices, data management
and provenance, uncertainty propagation, keeping units and flows consistent, and
reproducibility. Good opening for notebook 3.*

**Homework.** Rewrite the notebook code using the technology matrix format from the
course textbook.

---

## 1 — Simple LCA

**Group exercise.** Model the "Heat production" system from the course slides, first in
Excel, then in Brightway. Compare the results.

*The point is that the two agree — and that building it twice exposes what the Brightway
data structure is actually encoding.*

**Optional.** Build a product system from your own data, or from a reference of your
choosing.

**Also in the notebook.** Model the same system twice: once with everything in a single
database, once with technosphere and biosphere separated. Results should be identical.
The second is closer to how ecoinvent is organised.

---

## 2 — Navigating

**Try it out** on your own product system as well as the course example.

**Challenge.** Retrieve an exchange by *name* rather than by numeric index.

*This is harder than it looks and forces engagement with the data structure — exchanges
have no name of their own; the name belongs to the input activity.*

**Extract and store** a specific exchange value (the notebook uses CO₂) for use in a later
computation.

---

## 3 — Ecoinvent

**Exercise.** Link your foreground system's emissions to the biosphere database, connect
its inputs to ecoinvent activities, and calculate a carbon footprint using the ILCD
climate change method.

*Choosing among near-identical ecoinvent activities is the real content here. Worth
surfacing explicitly: which geography, which system model, and why.*

---

## 4 — Excel import

**Group exercise, in stages:**

1. Build a product system in the Excel template
2. Link it to ecoinvent and biosphere
3. Import it into Brightway and verify the calculation
4. **Exchange your code and data with another group**
5. Reproduce their results; give feedback on reproducibility and clarity

*Step 4 is the pedagogically interesting one — a reproducibility exercise as much as a
technical one. Expect `code` vs `id` problems, absolute file paths, and undocumented
assumptions to surface here. That is the lesson, not a failure.*

---

## 5 — Monte Carlo

1. Add lognormal uncertainty to selected exchanges, choosing your own `scale`
2. Run 500 iterations
3. Compare mean, median, min and max against the nominal deterministic score
4. Plot the distribution as a histogram
5. Interpret: what does the spread tell you, and what does it not?

*Step 3 reliably produces the "why isn't the mean equal to the nominal score?" question.
That surprise is instructive — let it happen before explaining. Compare mean against
median.*

---

## 6 — Comparative Monte Carlo

1. Run a 100-iteration Monte Carlo on a randomly chosen ecoinvent process
2. Compare two transport alternatives — EURO5 vs EURO6 lorry — using the comparative
   approach with a shared A matrix
3. Visualise with histograms and box plots
4. Compute descriptive statistics and interpret the variance

*The conceptual question to press: why does sharing the A matrix let you make a stronger
claim than comparing two independently sampled distributions?*

---

## 7 — OAT sensitivity analysis

Worked through in the notebook on a fictional biobased product system (baseline
180.28 kg CO₂-Eq): perturb each foreground parameter by 10%, recompute, rank by
sensitivity ratio.

**The question to ask afterwards:** you now have a ranked table. What would happen to that
ranking if two parameters were both at the high end of their range simultaneously?

*OAT cannot answer this — which is precisely the motivation for notebook 8. Asking it here
makes GSA arrive as an answer to a question students already have, rather than as extra
machinery.*

---

## 8 — Global sensitivity analysis

Worked through in the notebook: correlation analysis, then FAST via SALib, on the same
biobased system. Result: `par3` (product required during the use stage) dominates,
S1 = 0.934.

**Interpretation questions:**
- What is the difference between S1 and ST, and what does it mean when ST > S1?
- Does the GSA ranking agree with the OAT ranking from notebook 7? If not, why not?
- Why does GSA need so many more model runs?

*Students are not expected to derive FAST — they are expected to interpret it. Worth
saying out loud; some will assume they need the maths.*

---

## Cross-cutting exercise ideas

Not in the notebooks — sketches for the group exercise slots, if useful:

- **Reproduce a published LCA.** Take a paper with a simple published inventory and
  rebuild it. Compare. Discuss why the numbers differ.
- **Uncertainty on your own PhD data.** For PhD students: apply notebook 5–6 methods to a
  system from their own work. High engagement, and produces something they can use.
- **Break something deliberately.** Remove a production exchange, or a sign, and predict
  the error before running it. Builds traceback confidence.
- **Method sensitivity.** Run the same system through several LCIA methods. Which
  conclusions survive?
