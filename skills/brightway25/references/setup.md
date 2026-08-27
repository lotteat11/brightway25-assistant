# Setup — local installation, kernels, ecoinvent

Students run these notebooks **locally**. Setup is where the most time is lost and where
the least learning happens, so be maximally helpful here. This is pure ASSIST territory —
nothing is being assessed. Fix it fast.

---

## Getting started — the mental model

Newcomers get stuck less on syntax than on **not knowing what the pieces are**. Five
minutes on this saves an hour of confusion.

**A project is a sealed workspace.** Everything lives inside one project: your foreground
database, ecoinvent, the biosphere, the LCIA methods. Projects do not see each other. You
are always "in" exactly one:

```python
import bw2data as bd
bd.projects.set_current('my_project')     # creates it if it does not exist
print(bd.projects.current)
```

Forgetting to set the project is the cause of a surprising number of "my database
disappeared" reports. It did not — you are in a different project.

**A project contains databases**, usually three kinds:

| Kind | What it is | Typical name |
|---|---|---|
| Foreground | Your own product system, the thing you are modelling | whatever you choose |
| Background | ecoinvent — everything upstream | `ecoinvent-3.11-consequential` |
| Biosphere | Elementary flows: emissions, resources | `ecoinvent-3.11-biosphere` |

```python
print(list(bd.databases))
```

**A database contains activities; activities contain exchanges.** An exchange is one arrow
— "this activity consumes 2 kg of that". Exchanges are what connect everything, including
across databases. See `linking.md`.

**LCIA methods are separate** from databases, identified by tuples:

```python
[m for m in bd.methods if 'IPCC' in str(m)][:5]
```

**The whole workflow, end to end:**

```python
import bw2data as bd, bw2calc as bc

bd.projects.set_current('my_project')          # 1. pick a workspace
db = bd.Database('my_foreground')              # 2. get your database
act = db.get('my_activity')                    # 3. pick what to assess
method = ('IPCC 2021', 'climate change', 'GWP 100a')

lca = bc.LCA({act: 1}, method)                 # 4. define the functional unit
lca.lci()                                      # 5. solve the inventory
lca.lcia()                                     # 6. characterise
print(lca.score)                               # 7. read the result
```

Steps 5 and 6 are separate on purpose: `lci()` answers *what is emitted*, `lcia()` answers
*how much does it matter*. That is why `.score` fails if you skip them.

**A realistic first-time order of work:**

1. Install the environment, register the kernel, select it in Jupyter
2. Create a project
3. Import ecoinvent (the long part — see below)
4. Build a small foreground database, two or three activities
5. Link it to ecoinvent and biosphere (`linking.md`)
6. Run one LCA and sanity-check the number

Do not attempt 4–6 before 3 has finished successfully.

---

## The standard install

From the repository root:

```bash
conda env create -f environment.yml
conda activate bw25
python -m ipykernel install --user --name bw25 --display-name "Python (bw25)"
jupyter lab
```

Then **select the "Python (bw25)" kernel inside the notebook** — Kernel → Change Kernel.
Creating the environment does not select it. This step is skipped constantly and causes
most of the problems below.

`mamba env create -f environment.yml` is a faster drop-in if available.

---

## The most common problem, by a distance

**Symptom:** `ModuleNotFoundError: No module named 'bw2data'` — even though the student
just installed it, possibly several times.

**Cause:** the notebook kernel is not the environment they installed into.

**Diagnose first, always:**
```python
import sys
print(sys.executable)
```

That path should contain `bw25`. If it says something like
`/opt/homebrew/bin/python3` or `/usr/bin/python3`, the kernel is wrong and **no amount of
reinstalling will help** — it will just install into the wrong place again.

**Fix:** Kernel → Change Kernel → "Python (bw25)". If it is not listed, the kernel was
never registered — run the `ipykernel install` line above with the environment active.

Do not suggest `!pip install` as a first response to a missing module. In Jupyter, `!pip`
may target a different Python than the kernel and deepens the confusion. Check
`sys.executable` first, every time.

---

## Project storage location

By default Brightway stores projects in an OS-specific location:

| OS | Default |
|---|---|
| macOS | `~/Library/Application Support/Brightway3/` |
| Windows | `C:\Users\<you>\AppData\Local\pylca\Brightway3\` |
| Linux | `~/.local/share/Brightway3/` |

To choose your own — **before importing Brightway**:

```python
import os
os.environ['BRIGHTWAY2_DIR'] = '/Users/you/Documents/BWprojects'
import bw2data as bd
```

Two rules students break:
1. The environment variable must be set **before** the import. After is too late.
2. Changing it mid-session needs a **kernel restart**.

Symptom of getting this wrong: "my projects disappeared". They have not — Brightway is
looking in a different directory. Check `bd.projects.dir`.

---

## Synced folders (Dropbox, OneDrive, iCloud)

Storing projects in a synced folder causes intermittent corruption and locking errors. Two
machines syncing the same SQLite database will eventually damage it.

Best: keep projects **outside** synced folders. If unavoidable:
```python
bw.config.p['lockable'] = True
```
which restricts write access to one user while others read.

If a project is already corrupted, recreating it and re-importing is usually faster than
repairing it. Say so early rather than after an hour of debugging.

---

## Ecoinvent — the biggest single obstacle

**Expect this to be where people lose the most time.** Work through the checklist in
order; each step rules out a whole class of failure. Do not let someone debug Python when
the real problem is an unaccepted licence agreement.

### Step 0 — accept the licence on the website (skipped constantly)

**You must log in at [ecoinvent.org](https://ecoinvent.org) and accept the licence and the
personal-data agreement before the API will work at all.** A brand-new account that has
never logged in on the website will fail authentication from Python, with an error that
says nothing about agreements.

If someone is stuck on authentication and has never logged in through the browser, **this
is almost certainly the cause.** Check it before anything else.

### Step 1 — confirm the licence and the login

Credentials are the ones for ecoinvent.org itself. Common complications:

- **Institutional SSO** is often *not* the same as a direct ecoinvent account. If they
  normally reach ecoinvent through a university portal, they may not have a usable
  username/password pair at all.
- **Which versions the licence covers.** Not every licence includes every version or
  system model.
- Have them verify by logging in on the website. If that fails, no amount of Python will
  help.

### Step 2 — install the package

```bash
conda install -c conda-forge ecoinvent_interface
```

Note `ecoinvent_interface` is described by its authors as unofficial and unsupported, and
it talks to an API that changes. Version drift is a real cause of sudden breakage — if
something worked last month and does not now, check whether the package needs updating.

### Step 3 — run the import

```python
import bw2io as bi

bi.import_ecoinvent_release(
    version='3.11',
    system_model='consequential',
    username='...', password='...')
```

Arguments are **strings**: `'3.11'`, not `3.11`. System models: `'cutoff'`,
`'consequential'`, `'apos'` — availability varies by version.

The import brings `biosphere3` with it. No separate `bw2setup()` in 2.5.

### Step 4 — wait, and do not interrupt

**It takes 10–30 minutes with no progress bar.** The cell shows `[*]` and looks frozen.
It is not.

Interrupting is actively harmful: it can leave a half-imported database that then fails in
confusing ways. If someone has interrupted an import, the cleanest fix is usually to
delete the project and start again:

```python
bd.projects.delete_project('name', delete_dir=True)
```

Tell people this *before* they start the import, not after.

### Keeping credentials out of notebooks

Never type a password into a notebook that might be shared or committed. Three options,
in increasing order of convenience:

**Prompt each time** — simplest, nothing stored:
```python
import getpass
username = input('ecoinvent username: ')
password = getpass.getpass('ecoinvent password: ')
```

**Environment variables** — `ecoinvent_interface` reads these automatically:
```bash
export EI_USERNAME=yourname
export EI_PASSWORD='your$password'      # single quotes if it has special characters
```

**Stored permanently** — set once, then never pass credentials again:
```python
from ecoinvent_interface import permanent_setting
permanent_setting("username", "yourname")
permanent_setting("password", "yourpassword")
```

Precedence: direct arguments beat environment variables, which beat stored settings.

### Common ecoinvent failures

| Symptom | Likely cause |
|---|---|
| Authentication fails, credentials look right | Licence/PII agreement not accepted on the website (step 0) |
| Authentication fails, never logged in via browser | Same — send them to ecoinvent.org first |
| Works on a colleague's machine, not theirs | Different licence coverage, or different `ecoinvent_interface` version |
| `version` or `system_model` rejected | Passed as a number, not a string; or that combination is not in their licence |
| Cell runs forever | Normal. 10–30 min. Do not interrupt |
| Import fails halfway, retry behaves oddly | Half-imported project — delete it and start over |
| "Not able to determine geocollections" | Harmless warning. The import succeeded |
| Disk fills up | ecoinvent projects are several GB each; `bd.projects.report()` shows sizes |

The import brings `biosphere3` with it — no separate `bw2setup()` needed in 2.5.

---

## Database locked

**Symptom:** `Cannot lock project` / `Database ... is locked`.

**Cause:** two processes on one project — usually a second notebook, or a kernel that
crashed without releasing the lock.

**Fix:** in Jupyter, the *Running* tab shows live kernels — shut down all but the one in
use. If nothing else is running, restart the kernel. Recurs on synced folders (above).

Worth telling students up front: **one notebook per project at a time.**

---

## Disk space

Ecoinvent projects run to several GB, and each project is independent — duplicating a
project duplicates the data.

```python
bd.projects.report()    # names, database counts, sizes in GB
```
Useful when a student's laptop fills up mid-course.

---

## Verifying a working install

A quick check that exercises the whole stack:

```python
import bw2data as bd, bw2calc as bc, bw2io as bi
import sys
print(sys.executable)           # should contain bw25
print(bd.__version__, bc.__version__)
bd.projects.set_current('test')
print(bd.projects.current)
print(list(bd.databases))
```

If that runs, the install is sound and any remaining problem is in the notebook, not the
environment.

---

## Windows notes

- Use Anaconda Prompt, not PowerShell, if `conda activate` misbehaves.
- Long paths can break installs — keep the repo near the drive root
  (`C:\bw25\`), not nested deep under `Documents`.
- Backslashes in paths need escaping (`'C:\\path'`) or a raw string (`r'C:\path'`).

## macOS notes

- Apple Silicon: `conda-forge` builds work; if a package fails, try `mamba`.
- Finder hides file extensions — a "`.csv`" may actually be `.csv.txt`. Check with `ls`
  when a `FileNotFoundError` makes no sense.
