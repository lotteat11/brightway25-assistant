# Brightway 2.5 Assistant

**A coding assistant that knows Brightway 2.5.**

For advanced LCA work in Brightway — linking foreground systems to ecoinvent, propagating
uncertainty, running sensitivity analyses, and getting the software to cooperate. Works
with GitHub Copilot, Claude Code, Cursor, and anything else that reads `AGENTS.md`.

---

## The problem it solves

Brightway was rewritten between version 2 and 2.5. The `brightway2` umbrella package split
into `bw2data`, `bw2calc` and `bw2io`, and `MonteCarloLCA` disappeared entirely.

Every tutorial, blog post and forum answer written before that — which is most of what
language models were trained on — describes the **old** API. So a general assistant will
confidently produce this:

```python
import brightway2 as bw                    # does not exist in 2.5
mc = MonteCarloLCA({act: 1}, method)       # removed in 2.5
for _ in range(500):
    next(mc)
```

It looks right. It fails with an `ImportError` that says nothing about API versions, so the
time goes into looking for a mistake that was never yours.

This assistant answers with the current API:

```python
import bw2calc as bc
mc = bc.LCA({act: 1}, method, use_distributions=True)
mc.lci(); mc.lcia()
results = [mc.score for _ in zip(range(500), mc)]
```

---

## How it works

No server, no background process, no fine-tuned model. It is a set of structured reference
files that your AI tool reads when you open the folder.

```
Open the folder in VS Code
        ↓
Copilot reads AGENTS.md automatically
        ↓
You ask: "why is this cell failing?"
        ↓
The answer comes with Brightway 2.5 knowledge in context
```

The files carry four kinds of knowledge: what changed between Brightway 2 and 2.5, the
errors that actually occur and what causes them, the linking model that connects a
foreground system to ecoinvent, and **how Brightway represents LCA** — sign conventions,
exchange types, why there is no allocation setting. That last one is not LCA theory; it is
the translation layer between LCA as you practise it and LCA as Brightway expects it
written, and it is where a lot of the friction actually sits.

**It is self-contained.** No notebooks, repositories or course material need to be present.

---

## Setup

```bash
git clone https://github.com/lotteat11/brightway25-assistant.git
cd brightway25-assistant
bash setup.sh
```

That is the whole installation. It builds a Python environment, installs Brightway 2.5 and
the scientific stack, registers a Jupyter kernel, and creates a `my-project/` folder with a
working example notebook. About five minutes. Safe to run again.

Prefer conda? `conda env create -f environment.yml` instead — see the file for the extra
steps.

Then open the folder in VS Code (with Copilot) or run `claude` in it.

> **Open the whole folder**, not a single file — that is how the tool finds the
> instructions.

Your own work goes in `my-project/`, or any subfolder. The only thing that matters is that
the folder you opened has `AGENTS.md` at its root.

**→ [GETTING-STARTED.md](GETTING-STARTED.md)** covers the rest: the AI tool, ecoinvent
credentials, and what to do when something breaks.

### Checking it works

Ask: *"How do I run a Monte Carlo in Brightway 2.5?"*

- Answer mentions `use_distributions=True` → working
- Answer mentions `MonteCarloLCA` → the instructions are not being read. Is the whole
  folder open?

---

## Using it

Ask the way you would ask a colleague who knows Brightway:

- *"Why is this cell failing?"* — paste the whole traceback
- *"Write the code to add lognormal uncertainty to this exchange"*
- *"How do I find Danish medium-voltage electricity in ecoinvent?"*
- *"My foreground imports but the score is zero"*
- *"What does ST > S1 mean in my sensitivity analysis?"*

It writes the code and explains briefly what was wrong. It does not withhold answers.

To work something out instead of being handed it — often the case when learning a method
you intend to use in your own research — say so:

> *"Explain it instead of giving me the answer"*

It then moves to hints and analogous examples. *"Just show me"* ends that immediately.

**On references:** it will not invent citations. Asked where a method comes from, it says
it does not have the reference rather than producing a plausible author and year. A
reference list will be added later.

---

## What is where

| | |
|---|---|
| [`setup.sh`](setup.sh) | One-command setup: environment, kernel, project folder |
| [`get-course-notebooks.sh`](get-course-notebooks.sh) | Downloads the Advanced LCA course notebooks and points them at the bw25 kernel |
| [`GETTING-STARTED.md`](GETTING-STARTED.md) | Full setup walkthrough |
| [`environment.yml`](environment.yml) | Conda alternative to `setup.sh` |
| [`skills/brightway25/`](skills/brightway25/) | The assistant itself |
| [`exercises/`](exercises/) | Exercises from the Advanced LCA course notebooks |
| [`AGENTS.md`](AGENTS.md) | Instructions in the form Copilot and others read |
| [`ai-adapters/`](ai-adapters/) | Source for the per-tool files |
| [`templates/`](templates/) | A working Excel workbook for `bi.ExcelImporter`, in the layout it requires |

### Reference files

> **These are written for the assistant, not for you.** They are instructions telling an AI
> how to behave and what to watch out for, so they talk about "the user" in the third
> person and occasionally read like a briefing. You are welcome to read them — the content
> is accurate — but expect to see yourself discussed rather than addressed. For
> human-facing instructions, use [GETTING-STARTED.md](GETTING-STARTED.md).

`skills/brightway25/SKILL.md` governs behaviour. The rest are loaded as needed:

| File | Contents |
|---|---|
| [`common-tasks.md`](skills/brightway25/references/common-tasks.md) | Runnable recipes for everyday jobs — calculate one process, change an amount, copy an ecoinvent process, contribution analysis, uncertainty, Monte Carlo. Includes a SimaPro→Brightway mapping |
| [`lca-in-brightway.md`](skills/brightway25/references/lca-in-brightway.md) | How Brightway represents LCA: sign conventions, exchange types, substitution and why there is no allocation setting, the A/B matrices, uncertainty on exchanges |
| [`errors.md`](skills/brightway25/references/errors.md) | 25 error messages → cause → fix. Database, calculation, ecoinvent, environment and Python errors |
| [`linking.md`](skills/brightway25/references/linking.md) | Foreground-to-background linking: the three code formats, finding the right ecoinvent activity, spreadsheet import columns, and a diagnostic loop for broken links |
| [`bw25-api.md`](skills/brightway25/references/bw25-api.md) | The current API, plus what changed from Brightway 2 — in name and in behaviour |
| [`official-bw25.md`](skills/brightway25/references/official-bw25.md) | Standard workflows from the official Brightway tutorial: `ExcelImporter`, unlinked exchanges, `MultiLCA`, contribution analysis |
| [`setup.md`](skills/brightway25/references/setup.md) | The mental model, installation, kernels, project directories, synced folders, the ecoinvent checklist |
| [`python-primer.md`](skills/brightway25/references/python-primer.md) | The Python idioms Brightway code relies on: tuple keys, nested dicts, generators, the Monte Carlo iteration idiom |
| [`misconceptions.md`](skills/brightway25/references/misconceptions.md) | Eight recurring misreadings of method — OAT read as global, `loc`/`scale` as mean and SD, dependent sampling as cheating |
| [`notebooks/`](skills/brightway25/references/notebooks/) | **One file per Advanced LCA course notebook**, carrying the actual code plus what trips people up — so the assistant can answer and adapt without the notebook being open |
| [`course-map.md`](skills/brightway25/references/course-map.md) | How the ten notebooks depend on each other |

---

## Supported tools

| Tool | How | Note |
|---|---|---|
| **GitHub Copilot** in VS Code | Open the folder | Free plan is sufficient; VS Code reads `AGENTS.md` |
| **Claude Code** | `claude` in the folder | Fullest version — loads reference files on demand |
| **Cursor** | Open the folder | Reads `.cursor/rules/` |
| **Anything else** | Paste `AGENTS.md` into the chat | Works in claude.ai and ChatGPT too |

Claude Code gets the most out of it, since it can pull in detailed reference files when
they are relevant. The others get one flattened instruction file — less depth on the
teaching side, but the same knowledge of the API, the linking model and the errors.

---

## For maintainers

**Two modes.** The default is straightforward coding help. Teaching mode — hints and
questions instead of answers — activates **only** when someone asks for it. Deliberate:
someone stuck on `ModuleNotFoundError` is not learning LCA.

**It enforces nothing.** Anyone can open a fresh chat and ask directly. This is a working
tool, not an assessment mechanism.

**Notebooks are not vendored.** The Advanced LCA course notebooks live in
[massimopizzol/advanced-lca-notebooks](https://github.com/massimopizzol/advanced-lca-notebooks),
which stays the single source. The assistant does not depend on them being present — only
`course-map.md` refers to them, and only for people following the course.

**Teaching with the notebooks.** `bash get-course-notebooks.sh` fetches them into
`Course-material-bw25/` and rewrites each notebook's kernelspec to `bw25`. Upstream they
specify a generic `python3` kernel, so without that rewrite every student hits
`ModuleNotFoundError` on the first cell until they change the kernel by hand. The folder
must stay intact: notebooks 4, 7 and 8 import `lci_to_bw2.py` and read CSVs relative to
their own directory. Re-running the script pulls upstream changes and asks before replacing
local edits.

**Editing instructions.** `ai-adapters/AGENTS.md` is the single source for the non-Claude
tools:

```bash
bash ai-adapters/sync-adapters.sh
```

regenerates `AGENTS.md`, `.github/copilot-instructions.md` and `.cursor/rules/`. Commit the
generated files. `skills/brightway25/SKILL.md` is maintained separately, since it uses
progressive disclosure the flat formats cannot express.

**`misconceptions.md` needs review.** It is inferred from where teaching material tends to
pause and warn, not from systematic observation, and each entry carries a confidence note.
Correcting it is the highest-value contribution available. The file has a dated section for
ongoing notes — the questions people actually ask are the real list.

**References were removed** and will be reinstated later. Until then the assistant says it
does not have the source rather than guessing.

## The four things that cost the most time

### 1. Getting oriented in Brightway

Not syntax — structure. A *project* is a sealed workspace containing a foreground database,
ecoinvent as background, and a biosphere database of elementary flows. Databases hold
*activities*; activities hold *exchanges*, and an exchange is one arrow: "this activity
consumes 2 kg of that".

```python
bd.projects.set_current('my_project')
act = bd.Database('my_foreground').get('my_activity')
lca = bc.LCA({act: 1}, method)
lca.lci()                                  # trace the supply chain: total emissions
lca.lcia()                                 # weight them by the impact method
print(lca.score)
```

`lci()` and `lcia()` answer different questions — what is emitted, then how much it
matters — which is why `.score` needs both.

### 2. Brightway 2 versus 2.5

Most old code translates mechanically. Some of it changed *behaviourally*, which is where a
find-and-replace leaves you with something broken:

| Brightway 2 | Brightway 2.5 |
|---|---|
| `import brightway2 as bw` | `import bw2data as bd`, `bw2calc as bc`, `bw2io as bi` |
| `MonteCarloLCA(fu, method)` | `bc.LCA(fu, method, use_distributions=True)`, then iterate |
| `bw2setup()` | Not needed — the ecoinvent import brings biosphere with it |
| ecoinvent from a folder of files | `ecoinvent_interface` with licence credentials |

Brightway 2 projects on disk are not directly usable in 2.5 either.

The assistant flags old-API code explicitly — the source is outdated, not you.

### 3. Linking foreground to background

**Brightway does no fuzzy matching.** An exchange points at exactly one `(database, code)`
tuple. If nothing is there, the exchange is unlinked and the database will not calculate.
There is no way to write "electricity, DK" and have Brightway work out what you meant.

Three databases, three identifier formats — all sitting in the same spreadsheet column:

| Database | Example | Format |
|---|---|---|
| Foreground | `Electricity production` | whatever you chose |
| ecoinvent | `7a6115b0457d395cd2ffb09edb920931` | 32 hex characters, **no** dashes |
| biosphere | `349b29d1-3e58-4c66-98b9-9d1a076efd2e` | 36 characters, **with** dashes |

Database names must match exactly — `ecoinvent-3.11-consequential`, not `ecoinvent 3.11`
or a different system model.

The worst failure here is silent: if the foreground is not actually connected, the score
comes back zero or implausibly low with no error at all. The assistant carries a diagnostic
loop that checks every exchange and reports precisely which links are broken.

It also knows to link by `code` and never `id` — `id` is a matrix coordinate specific to
one installation, and points somewhere else on another machine.

### 4. Installing ecoinvent

The one nobody warns you about:

> **You must log in at [ecoinvent.org](https://ecoinvent.org) in a browser and accept the
> licence and personal-data agreement before the API will authenticate at all.**
>
> A new account that has never logged in through the website is rejected from Python, and
> the error says nothing about agreements.

Also covered: institutional SSO is often not the same as an ecoinvent account; the import
takes 10–30 minutes with no progress bar and interrupting it leaves a half-imported
project; `version='3.11'` is a string; keeping credentials out of notebooks with
`permanent_setting()`; and the geocollections warning being harmless.

---

## Credits

This assistant is made by **Lotte Ansgaard Thomsen** and **Massimo Pizzol**, Aalborg
University.

Course material by Massimo Pizzol —
[advanced-lca-notebooks](https://github.com/massimopizzol/advanced-lca-notebooks),
BSD 3-Clause.

Brightway is developed by
[Chris Mutel and the Brightway community](https://github.com/brightway-lca).

BSD 3-Clause — see [LICENSE](LICENSE).
