# Setup — local installation, kernels, ecoinvent

Installation, kernels, and ecoinvent credentials. This is where most time is lost, and
none of it is LCA — resolve it quickly.

---

## How Brightway is organised

The structure, before the syntax. Most difficulty with Brightway is structural rather than
about Python.

**A project is a sealed workspace.** Everything lives inside one project: your foreground
database, ecoinvent, the biosphere, the LCIA methods. Projects do not see each other. You
are always "in" exactly one:

```python
import bw2data as bd
bd.projects.set_current('my_project')     # creates it if it does not exist
print(bd.projects.current)
```

"My database disappeared" is usually a project that was never set. The database is still
there; the session is pointed somewhere else.

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
method = ...    # look one up: [m for m in bd.methods if 'IPCC' in str(m)][:5]
                # keys differ by release; ecoinvent 3.11 uses a 4-tuple

lca = bc.LCA({act: 1}, method)                 # 4. define the functional unit
lca.lci()                                      # 5. solve the inventory
lca.lcia()                                     # 6. characterise
print(lca.score)                               # 7. read the result
```

Steps 5 and 6 are separate on purpose: `lci()` answers *what is emitted*, `lcia()` answers
*how much does it matter*. That is why `.score` fails if you skip them.

**A working order for a new project:**

1. Install the environment, register the kernel, select it in Jupyter
2. Create a project
3. Import ecoinvent (the long part — see below)
4. Build a small foreground database, two or three activities
5. Link it to ecoinvent and biosphere (`linking.md`)
6. Run one LCA and sanity-check the number

Do not attempt 4–6 before 3 has finished successfully.

---

## Installing

Either environment manager works — **conda if there is no reason to prefer otherwise**,
since it handles the scientific stack with fewer surprises. What matters is that Brightway,
the notebook kernel and any later install all target the **same** environment; most setup
problems are a mismatch between those.

**conda:**

```bash
conda create -n bw25 -c conda-forge python=3.11 brightway25 ecoinvent_interface jupyterlab ipykernel
conda activate bw25
python -m ipykernel install --user --name bw25 --display-name "Python (bw25)"
```

**venv and pip:**

```bash
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install brightway25 ecoinvent_interface jupyterlab ipykernel
python -m ipykernel install --user --name bw25 --display-name "Python (bw25)"
```

Then **select the "Python (bw25)" kernel inside the notebook** — Kernel → Change Kernel.
Creating the environment does not select it. This step is skipped constantly and causes
most of the problems below.

If a repository with an `environment.yml` or a setup script is at hand, use that instead —
it does the same thing with the versions already pinned.

### Installing a package once you have already started

A frequent stumble, because a notebook holds the environment open:

1. **Close the notebook** and stop the Jupyter server (Ctrl-C in its terminal)
2. In a terminal, **activate the environment**: `conda activate bw25`
3. Install: `conda install -c conda-forge <package>` — or `pip install <package>` if the
   environment was built with venv
4. **Reopen** the notebook and restart the kernel

Do not use `!conda install` or `!pip install` from inside a cell. The intuition is
reasonable — install from Jupyter, install for Jupyter — but it does not hold: `!` runs in
the shell Jupyter was *launched* from, which is often a different Python than the kernel is
running. The package lands somewhere the notebook cannot see, which is the exact cause of
the `ModuleNotFoundError` below.

---

## The most common problem, by a distance

**Symptom:** `ModuleNotFoundError: No module named 'bw2data'`, despite the package being
installed — possibly several times.

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

Two constraints:
1. The environment variable must be set **before** the import. After has no effect.
2. Changing it mid-session requires a **kernel restart**.

Symptom: "my projects disappeared". Brightway is reading a different directory. Check
`bd.projects.dir`.

---

## Synced folders (Dropbox, OneDrive, iCloud)

Storing projects in a synced folder causes intermittent corruption and locking errors. Two
machines syncing the same SQLite database will eventually damage it.

Best: keep projects **outside** synced folders. If unavoidable:
```python
bd.config.p['lockable'] = True
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

### Step 2 — check `ecoinvent_interface` is installed

The install commands above include it. If it is missing:

```bash
conda activate bw25
conda install -c conda-forge ecoinvent_interface     # or: pip install ecoinvent_interface
```

From a terminal with the notebook closed — see *Installing a package once you have already
started* above.

Note `ecoinvent_interface` is described by its authors as unofficial and unsupported, and
it talks to an API that changes. Version drift is a real cause of sudden breakage — if
something worked last month and does not now, check whether the package needs updating.

### Step 3 — run the import

```python
import bw2io as bi

bi.import_ecoinvent_release(
    version='3.11',
    system_model='cutoff',       # 'cutoff' / 'consequential' / 'apos'
    username='...', password='...')
```

Arguments are **strings**: `'3.11'`, not `3.11`.

**Choosing the system model is a methodological decision, and expensive to change.** It is
part of the database name, so every link in a foreground model points at one specific
choice; switching means re-importing and rewriting every link, since activity codes differ
between system models too.

`cutoff` is what most attributional studies use; `consequential` for consequential studies;
`apos` for allocation at the point of substitution. If someone does not already know which
their project needs, the answer is to ask their supervisor or check the study protocol —
say so plainly rather than choosing for them.

Teaching material often shows `consequential` because a particular course chose it. That is
not a default. Also check the licence covers the combination — not every licence includes
every version and system model.

The import brings a biosphere database with it — no separate `bw2setup()` in 2.5. **Its
name varies by release**: recent imports use `ecoinvent-3.11-biosphere`, older setups
`biosphere3`. Check `list(bd.databases)`; never hardcode it.

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

The import brings a biosphere database with it — no separate `bw2setup()` needed in 2.5.
**Its name varies by release** (`ecoinvent-3.11-biosphere` or `biosphere3`) — check
`list(bd.databases)`.

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

## Verifying the ecoinvent import

Different question from "does Brightway run" — this checks that ecoinvent arrived intact.
Worth running before building anything on top of it, because every partial-import failure
mode produces a project that *looks* fine at `list(bd.databases)` and fails weeks later as
a zero score or an `UnknownObject`.

```python
import sys
import bw2data as bd
import bw2calc as bc

print(sys.executable)                    # the environment you installed into?
bd.projects.set_current('my_project')
print(list(bd.databases))                # copy the exact names from here
```

Then check the contents are the right order of magnitude:

```python
ei  = bd.Database('...')                 # paste your ecoinvent name
bio = bd.Database('...')                 # paste your biosphere name

print(len(ei),  'activities')            # tens of thousands
print(len(bio), 'biosphere flows')       # thousands
print(len(bd.methods), 'LCIA methods')   # hundreds to low thousands
```

Exact counts vary by version and system model, so treat these as orders of magnitude, not
targets. What matters is that nothing is zero or in the single digits — that means the
import did not complete, and the fix is to delete the project and redo it rather than build
on it.

Finally, one real calculation end to end. This exercises the databases, the links between
them, and the LCIA methods together:

```python
for m in bd.methods:                     # never type a method key from memory
    if 'IPCC' in str(m) and 'GWP100' in str(m):
        print(m)

method_key = ...                         # paste one of the printed keys

hits = [a for a in ei
        if a['name'] == 'market for electricity, medium voltage'
        and a['location'] == 'DK']       # or any location in your region
print(len(hits), 'match')                # expect exactly 1
act = hits[0]

lca = bc.LCA({act: 1}, method_key)
lca.lci()
lca.lcia()
print(lca.score, bd.methods[method_key]['unit'])
```

A plausible non-zero number means everything works. A score of exactly `0.0` means
something is unlinked — see `linking.md`. An error at `.lci()` usually means the biosphere
database is missing or misnamed.

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
