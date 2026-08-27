# Common misconceptions

Patterns in *reasoning*, not errors in code. Use them to diagnose: when a question implies
one of these, address the underlying belief rather than the surface question.

Never announce a misconception by name. Just address the concept.

> ⚠️ **Provisional.** These are inferred from where LCA teaching material tends to pause
> and warn, not from systematic observation. Each carries a confidence note. Correct,
> delete and add freely — a wrong entry is worse than a missing one, because it makes the
> assistant diagnose something that is not there.
>
> Append as patterns emerge. The questions people actually ask are the real list.

---

## 1. OAT results read as global

**The belief:** "I ran a sensitivity analysis, so I know which parameters matter."

**Why it happens:** one-at-a-time analysis produces a clean ranked table, and rankings look
definitive.

**Reality:** OAT is *local*. It varies one parameter around a single point in parameter
space with everything else fixed. The effect of changing a parameter can be entirely
different when the others sit at different values — so an OAT ranking can mislead.

**How to address:** ask what happens if two parameters are both at the high end of their
ranges. OAT never visits that corner. Global sensitivity analysis then arrives as the
answer to a question they already have, rather than as extra machinery.

*Confidence: high.*

---

## 2. `loc` and `scale` treated as mean and standard deviation

**The belief:** setting `scale=1.2` means 20% standard deviation.

**Reality:** for a lognormal in Brightway, `loc` is the **log** of the geometric mean and
`scale` is the **log** of the geometric standard deviation. So `np.log(1.2)`, not `1.2`.

**Symptom:** distributions far wider or narrower than intended. Usually no error — just
wrong results.

**Related, and equally common:** negative amounts must be negated before taking the log —
`np.log(-exc['amount'])`. Technosphere inputs are negative and `np.log()` of a negative is
undefined. The sign lives in `amount`; the distribution is defined on the magnitude. Code
copied from a positive emission to a negative input produces `nan` with no clear
explanation.

**How to address:** plot the resulting distribution and read the spread off the histogram.
Seeing a nominal "20% uncertainty" span orders of magnitude makes the point faster than
any explanation.

*Confidence: high.*

---

## 3. Expecting the Monte Carlo mean to equal the deterministic score

**The belief:** "my MC mean is 82 but the nominal score is 80 — something is broken."

**Reality:** nothing is broken. With lognormal inputs the mean of the output distribution
is generally *not* the deterministic result. The nominal score uses the geometric mean of
each input; the MC mean averages a right-skewed distribution and sits higher.

**How to address:** compare mean against *median* — the median sits much closer to nominal.
That single comparison usually produces the insight unaided. Worth letting the surprise
land rather than explaining it away immediately.

*Confidence: medium-high.*

---

## 4. Dependent sampling looks like cheating

**The belief:** "reusing the same random draw for both alternatives must bias the
comparison."

**Reality:** the opposite. When both alternatives face the same sampled background, what
varies between them is only what actually *differs* between them. This reduces variance,
needs fewer iterations, and makes **paired** tests valid. Independent sampling inflates the
apparent uncertainty of the difference — which is the quantity the comparison is about.

**How to address:** the most conceptually demanding idea in comparative LCA, and worth the
full ladder. A useful analogy: testing two treatments on the same subjects versus two
different groups. The paired design is stronger precisely because it removes
between-subject variation.

*Confidence: medium-high — it runs against intuition.*

---

## 5. Sign conventions on inputs and substitution

**The belief:** uncertainty about when an amount should be negative.

**Reality:** inputs to the technosphere are negative in the A matrix. Substitution
exchanges (avoided production) introduce a further sign flip, and the two get conflated.

**Symptom:** results with the wrong sign, or roughly double the expected magnitude.

**How to address:** go back to the matrix formulation and read the sign directly off A. The
algebra is unambiguous where the API is not. Note also that partitioning requires
pre-calculating allocated values — Brightway does not do it for you.

*Confidence: medium.*

---

## 6. `code` and `id` treated as interchangeable

**The belief:** either identifier will do.

**Reality:** `code` is a string, stable across installations, and is what you share and
link with. `id` is an integer matrix coordinate specific to one installation — it points at
something different on a colleague's machine, or after re-importing ecoinvent.

**Symptom:** code that works locally and breaks when shared. Matters directly for
reproducibility and for any collaborative workflow.

**How to address:** connect it to the matrix. `id` is a row or column number in A, and row
numbers depend on what else is in the matrix. See `linking.md`.

*Confidence: medium.*

---

## 7. `lci()` and `lcia()` seen as ceremony

**The belief:** two lines you have to type before `.score` works.

**Reality:** two distinct computational steps. `lci()` solves `s = A⁻¹f` and `g = Bs` — the
inventory. `lcia()` applies characterisation factors: `score = CF · g`. Two different
questions: *what is emitted*, then *how much does it matter*.

**How to address:** cheap and high-value. One sentence connecting the API to the algebra
turns an arbitrary-seeming rule into something reasonable — and makes `redo_lci()` versus
`redo_lcia()` obvious later.

*Confidence: medium — inferred from the API design.*

---

## 8. Searching ecoinvent treated as a syntax problem

**The belief:** "I can't find the right activity — what's the search syntax?"

**Reality:** the search usually works fine. Twenty near-identical hits differing by
location, system model or cut-off assumptions is not a search failure — **choosing among
them is a modelling decision**, and a consequential one.

**How to address:** this is where a question that arrives as a coding problem should become
a method discussion. Do not just hand over a `filter` argument. Ask what the study is
actually modelling: which geography, which system model, which representation.

*Confidence: medium.*

---

## Watch list

Worth noticing, not yet worth acting on:

- **Generators consumed twice** — a Python problem that presents as an LCA one ("my
  exchanges disappeared"). See `python-primer.md`.
- **Foreground/background boundary** — where the modelled system ends and ecoinvent begins,
  especially in sensitivity analysis where only foreground parameters are perturbed.
- **`np.matrix` vs `np.array`** — "tidying up" matrix code silently changes `*` from matrix
  multiplication to elementwise. See `errors.md`.
- **Small iteration counts** — teaching examples use 100–500 iterations for speed; that is
  a pedagogical compromise, not a recommendation.
- **Assuming `.write()` merges** — it replaces. Re-running a cell can silently discard
  earlier work.

---

## Notes from practice

<!-- Append as patterns emerge. Date entries so changes over time stay visible.

### 2026-xx-xx
- …

-->
