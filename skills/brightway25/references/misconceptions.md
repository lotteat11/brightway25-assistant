# Misconceptions — what students get wrong

> ⚠️ **PROVISIONAL — needs review by Lotte and Massimo.**
>
> These are *inferred* from the notebooks, not observed in teaching. The method: where
> the material pauses to warn, repeats itself, or belabours a point is usually where
> students trip. That is a decent heuristic and not a substitute for classroom experience.
>
> **Please correct, delete and add.** A wrong entry here is worse than a missing one,
> because it makes the assistant diagnose a misconception the student does not have.
>
> **This file should grow.** The questions students actually ask the assistant *are* the
> real misconception list. Append as you notice patterns; nothing here is meant to be
> final.

---

## How to use this file

These are patterns in *reasoning*, not errors in code. Use them to diagnose: when a
student's question implies one of these, address the underlying belief rather than the
surface question. Never say "you have misconception #4" — just tutor the concept.

---

## 1. OAT results are treated as global

**The belief:** "I ran a sensitivity analysis, so I know which parameters matter."

**Why it happens:** notebook 7 produces a clean ranked table. Rankings look definitive.

**Reality:** OAT is *local* — it varies one parameter around one point in parameter space,
holding everything else fixed. The notebook says so outright: "the effect of a change in
the parameter might be different when other parameters assume different values… so OAT
can be misleading!" That warning is the pedagogical point of notebook 7 and the bridge to
notebook 8.

**How to tutor:** ask what would happen if two parameters were both high. Get them to see
that OAT never explores that corner. Then GSA in notebook 8 answers a question they now
want answered — rather than arriving as extra machinery.

*Confidence: high — the notebook flags it explicitly.*

---

## 2. `loc` and `scale` are the mean and standard deviation

**The belief:** setting `scale=1.2` means a 20% standard deviation.

**Reality:** for lognormal in Brightway, `loc` is the **log** of the geometric mean and
`scale` is the **log** of the geometric standard deviation. So `np.log(1.2)`, not `1.2`.

**Symptom:** wildly wide Monte Carlo distributions, or suspiciously narrow ones. Usually
no error — just wrong results.

**How to tutor:** have them plot the resulting distribution and read the spread off the
histogram. Seeing a "20% uncertainty" span three orders of magnitude makes the point
faster than any explanation. Then explain why geometric parameters suit environmental
data.

**Related, and confirmed in notebook 5:** negative amounts must be negated before taking
the log — `np.log(-fuel_exc['amount'])`. Technosphere inputs are negative and `np.log()`
of a negative is undefined. The sign lives in `amount`; the distribution is defined on the
magnitude. Students who copy the CO₂ line (positive amount) to a fuel input (negative)
get a `nan` or a warning and no obvious explanation.

*Confidence: high — the notebook explains it carefully, which suggests it has caused
trouble.*

---

## 3. The Monte Carlo mean should equal the deterministic score

**The belief:** "my MC mean is 82 but the nominal score is 80 — something is broken."

**Reality:** nothing is broken. For lognormal inputs the mean of the output distribution
is generally *not* the deterministic result. The nominal score uses the geometric mean of
each input; the MC mean averages a right-skewed distribution and sits higher.

**How to tutor:** a genuinely instructive surprise — do not explain it away quickly.
Compare mean vs *median* (the median will sit much closer to nominal). That single
comparison usually produces the insight unaided.

*Confidence: medium-high — notebook 5 sets up exactly this comparison.*

---

## 4. Dependent sampling looks like cheating

**The belief:** "reusing the same random draw for both alternatives must bias the
comparison."

**Reality:** the opposite. Both alternatives share the same background uncertainty, so
what varies between them is only what actually *differs* between them. This reduces
variance, requires fewer iterations, and makes **paired** tests valid. Independent
sampling inflates the apparent uncertainty of the *difference* — which is the quantity the
comparison is about.

**How to tutor:** the central conceptual hurdle of the course; use the full ladder. An
analogy that lands: testing two drugs on the same patients versus two different groups.
Same-patient comparison is stronger precisely because it removes between-patient
variation.

*Confidence: medium-high — it is the most conceptually demanding idea in the course and
runs against intuition.*

---

## 5. Sign conventions on inputs and substitution

**The belief:** confusion about when an amount is negative.

**Reality:** in the sign convention used here, inputs to the technosphere are
negative in the A matrix. Substitution exchanges (avoided production) add another sign
flip, and students lose track of which is which.

**Symptom:** results with the wrong sign, or roughly double the expected magnitude.

**How to tutor:** go back to notebook 0 and read the sign directly off the matrix. The
algebra is unambiguous where the API is not. Note also that partitioning requires
pre-calculating allocated values — Brightway does not do it for you.

*Confidence: medium — notebook 1 discusses it at some length, which is suggestive.*

---

## 6. `code` and `id` are interchangeable

**The belief:** either identifier will do.

**Reality:** `code` is a UUID string, stable across installations, and is what you share
and reference. `id` is an integer matrix coordinate, specific to one installation, and will
point at something different on a colleague's machine.

**Symptom:** code that works locally and breaks when shared — which matters directly for
the notebook 4 group exercise on reproducibility.

**How to tutor:** connect to notebook 0. `id` is a row/column number in A. Row numbers
depend on what else is in the matrix.

*Confidence: medium — notebook 2 and 3 both make the distinction explicitly.*

---

## 7. `lci()` and `lcia()` are ceremony

**The belief:** two lines you have to type before `.score` works.

**Reality:** they are the two distinct computational steps. `lci()` solves `s = A⁻¹f` and
`g = Bs` — the inventory. `lcia()` applies characterisation factors — `score = CF · g`.
Two different questions: *what is emitted*, then *how much does it matter*.

**How to tutor:** cheap and high-value. Whenever the API ordering comes up, spend one
sentence connecting it to notebook 0's algebra. It converts an arbitrary-seeming rule into
something students can reason about — and makes `redo_lci()` vs `redo_lcia()` obvious
later.

*Confidence: medium — inferred from the API design rather than flagged in the notebooks.*

---

## 8. Searching ecoinvent is a syntax problem

**The belief:** "I can't find the right activity — what's the search syntax?"

**Reality:** the search usually works fine. Twenty near-identical hits differing by
location, system model, or cut-off assumptions is not a search failure — **choosing among
them is an LCA modelling decision**, and it is one of the more consequential ones a student
will make.

**How to tutor:** this is where a question that arrives as ASSIST should switch to TUTOR.
Do not just hand over a `filter` argument. Ask what the study is actually modelling —
which geography, which system model, which of these is the right representation.

*Confidence: medium — inferred from the scale of notebook 3 and the nature of ecoinvent.*

---

## Candidates I am less sure about

Worth watching for, not yet worth acting on:

- **Generators consumed twice** — a Python problem, but presents as an LCA one ("my
  exchanges disappeared"). Covered in `python-primer.md`.
- **Foreground vs background confusion** — where the modelled system ends and ecoinvent
  begins, especially in notebooks 7–8 where only foreground parameters are perturbed.
- **`np.matrix` vs `np.array`** — a student who "tidies up" notebook 0 gets silently
  wrong answers. Covered in `errors.md`.
- **Treating 100 MC iterations as sufficient** — the notebooks use small counts for speed;
  students may not register that this is a teaching compromise.
- **Assuming `.write()` merges** — it replaces. Re-running a cell can silently discard
  earlier work.

---

## Notes from teaching

<!-- Append here as you observe them. Date entries so patterns across cohorts stay visible.

### 2026-xx-xx
- …

-->
