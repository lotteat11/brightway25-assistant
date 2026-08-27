# Getting started

From nothing to a working setup where your AI tool knows Brightway 2.5. Around
**30–60 minutes** the first time, plus the ecoinvent download.

Four steps:

1. [The Python environment](#1-the-python-environment) — 10 min
2. [The AI assistant](#2-the-ai-assistant) — 10 min
3. [Course notebooks](#3-course-notebooks-optional) — optional, 2 min
4. [ecoinvent](#4-ecoinvent) — 5 min setup, 10–30 min download

Step 4 can wait until you need background data.

> **If something breaks**, jump to [When it doesn't work](#when-it-doesnt-work). You can
> also just ask the assistant — it is set up to recognise these specific failures.

---

## 1. The Python environment

You need **conda**. If you do not have it,
[Miniforge](https://github.com/conda-forge/miniforge#download) is a good default — free,
and works on macOS, Windows and Linux.

Open a terminal (macOS: Terminal · Windows: **Anaconda Prompt**, not PowerShell):

```bash
git clone https://github.com/lotteat11/brightway25-assistant.git
cd brightway25-assistant

conda env create -f environment.yml
conda activate bw25
python -m ipykernel install --user --name bw25 --display-name "Python (bw25)"
```

That last line registers the environment so Jupyter can see it. **Do not skip it** — it
is the root of most later problems.

Check it worked:

```bash
python -c "import bw2data, bw2calc; print('OK')"
```

---

## 2. The AI assistant

Pick either. **Copilot is free** and the obvious choice if you have nothing set up.

### Option A: GitHub Copilot in VS Code (free)

1. Install [VS Code](https://code.visualstudio.com/)
2. Create a [GitHub account](https://github.com/signup) if you do not have one
3. Open VS Code → click the **Copilot icon** in the status bar → **Use AI Features**
4. Sign in with GitHub

You are placed on **Copilot Free**, which has a monthly quota — enough for normal use.

> **Student or academic?** Apply for the
> [GitHub Student Developer Pack](https://education.github.com/pack) or
> [GitHub Education for teachers](https://education.github.com/teachers) for Copilot Pro
> with no quota. Verification takes a few days; use Free meanwhile.

**Open the right folder.** The assistant only works when the `brightway25-assistant` folder
is open in VS Code:

```
File → Open Folder… → select brightway25-assistant
```

VS Code then reads `AGENTS.md` and `.github/copilot-instructions.md` automatically. Opening
a single notebook without the folder gives you a plain Copilot with no Brightway knowledge.

You will also want the **Jupyter** extension to run notebooks — VS Code offers it when you
open a `.ipynb` file.

### Option B: Claude Code

Requires a Claude subscription or API key.

```bash
npm install -g @anthropic-ai/claude-code
cd brightway25-assistant
claude
```

Claude Code reads `skills/brightway25/` automatically. This is the fullest version — it
pulls in detailed reference files as they become relevant.

### Checking it works

Ask your assistant:

> *How do I run a Monte Carlo simulation in Brightway 2.5?*

**Correct** answers mention `bc.LCA(..., use_distributions=True)`.
**Wrong** answers mention `MonteCarloLCA` — the instructions are not being read. Check that
you opened the whole folder rather than a single file.

---

## 3. Course notebooks (optional)

Only relevant if you are following the Advanced LCA course. The assistant works fine
without them.

```bash
git clone https://github.com/massimopizzol/advanced-lca-notebooks.git
```

The material is in `Course-material-bw25`. Put it next to `brightway25-assistant` or inside
it — either works.

When you open a notebook, **select the right kernel**:

```
Kernel → Change Kernel → Python (bw25)
```

This step gets missed constantly. Without it you get `ModuleNotFoundError` no matter how
many times you reinstall.

---

## 4. ecoinvent

Take these in order — each step rules out a whole class of failure.

### Step 0: Log in on the website and accept the agreement

> **The step that gets skipped, and the most common cause of authentication failure.**

Go to [ecoinvent.org](https://ecoinvent.org), log in, and **accept the licence agreement
and the personal-data agreement**.

If you have never logged in through a browser, **your account will not work from Python** —
regardless of the username and password being correct. The error message says nothing about
agreements, so this can cost a lot of time.

If logging in on the website fails, nothing in Python will help.

### Step 1: Confirm you have a direct ecoinvent account

If you normally reach ecoinvent through a university portal, you may **not** have a direct
username and password. Institutional SSO is not the same thing.

Can you log in at ecoinvent.org with a username and password? Then you are set. If not, you
need access provisioned first — your library or research group will know.

Also worth checking: your licence may not cover every version or system model.

### Step 2: Install the package

```bash
conda activate bw25
conda install -c conda-forge ecoinvent_interface
```

### Step 3: Run the import

```python
import bw2io as bi

bi.import_ecoinvent_release(
    version='3.11',
    system_model='consequential',
    username='YOUR-USERNAME',
    password='YOUR-PASSWORD')
```

`version` and `system_model` are **strings** — `'3.11'` in quotes, not `3.11`. System
models: `'cutoff'`, `'consequential'`, `'apos'`.

### Step 4: Wait — do not interrupt

**The import takes 10–30 minutes with no progress bar.** The cell shows `[*]` and looks
completely dead.

> **It is not stuck.** Let it run.

Interrupting can leave a half-imported database that fails confusingly afterwards. If that
has already happened, the fastest fix is to delete the project and start over:

```python
import bw2data as bd
bd.projects.delete_project('project_name', delete_dir=True)
```

Watch disk space: each ecoinvent project runs to several GB.

---

### Keeping credentials out of notebooks

If you share a notebook, the password goes with it. Pick one:

**Prompt each time** — nothing stored:
```python
import getpass
username = input('ecoinvent username: ')
password = getpass.getpass('ecoinvent password: ')
```

**Store once** — then never pass credentials again:
```python
from ecoinvent_interface import permanent_setting
permanent_setting("username", "your-username")
permanent_setting("password", "your-password")
```
After that, `import_ecoinvent_release()` works without `username` and `password`.

---

### When ecoinvent still fails

| Symptom | Likely cause |
|---|---|
| Login rejected, credentials are correct | Agreement not accepted on the website — **step 0** |
| Never logged in through a browser | Same — go to ecoinvent.org first |
| Works for a colleague, not for you | Your licences cover different versions |
| `version` or `system_model` rejected | Passed as a number instead of a string, or not covered by your licence |
| Cell runs forever | Normal. 10–30 min. Do not interrupt |
| Import failed, now behaving oddly | Half-imported project — delete it and start over |
| *"Not able to determine geocollections"* | **Harmless warning.** The import succeeded |

Still stuck? Ask the assistant and paste the full error — it knows these specific failures.

---

## When it doesn't work

### `ModuleNotFoundError: No module named 'bw2data'`

The most common problem by a distance. The package is installed — the notebook is just
running a different Python.

Run this in the notebook:

```python
import sys; print(sys.executable)
```

If the path does not contain `bw25`, the kernel is wrong:
**Kernel → Change Kernel → Python (bw25)**

**Do not reinstall.** It will install the same package into the same wrong place.

### `Database ... is locked`

Two notebooks are open on the same project. Close the others (Jupyter: **Running** tab →
Shutdown), or restart the kernel.

Rule of thumb: **one notebook per project at a time.**

### The AI suggests code that doesn't work

If it proposes `import brightway2 as bw` or `MonteCarloLCA`, it is using Brightway 2. Tell
it:

> *That's Brightway 2. We're on Brightway 2.5 — use bw2data and bw2calc.*

If it happens repeatedly, the instructions are not being read. Check that the whole folder
is open.

### Something else

Ask the assistant and paste the entire error message — including the parts that look
irrelevant.

---

## Using it

It is a **coding assistant**. Ask the way you would ask a colleague:

- *"Why is this cell failing?"* — paste the traceback
- *"Write the code to add lognormal uncertainty to this exchange"*
- *"How do I find Danish medium-voltage electricity in ecoinvent?"*
- *"My foreground imports but the score is zero"*
- *"Plot my Monte Carlo results as a boxplot"*

It writes the code and explains briefly. It does not withhold answers.

**Want to work it out instead?** Say so:

- *"Explain it instead of giving me the answer"*
- *"Help me understand why this works"*

It then switches to hints and analogous examples. *"Just show me"* ends that immediately.

**On references:** the assistant will not invent citations. Asked where a method comes
from, it says it does not have the reference rather than guessing at an author and year.
