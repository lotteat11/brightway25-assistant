# Setup — local installation, kernels, ecoinvent

Students run these notebooks **locally**. Setup is where the most time is lost and where
the least learning happens, so be maximally helpful here. This is pure ASSIST territory —
nothing is being assessed. Fix it fast.

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

## Ecoinvent

Needs a **valid licence** and credentials — the same ones used at ecoinvent.org. Note that
institutional SSO logins sometimes differ from the direct ecoinvent account; if
credentials fail, have the student verify by logging in on the website.

```bash
conda install -c conda-forge ecoinvent_interface
```

```python
import bw2io as bi
bi.import_ecoinvent_release(
    version='3.11',
    system_model='consequential',
    username='...', password='...')
```

**Tell students it takes several minutes with no progress bar.** A cell showing `[*]` for
ten minutes is normal. Many kill it and retry, which wastes more time and occasionally
leaves a half-imported database.

Arguments are strings: `'3.11'` not `3.11`; `'cutoff'`, `'consequential'`, `'apos'`.

Do not put credentials in a notebook that will be shared or committed. Suggest:
```python
import getpass
username = input('ecoinvent username: ')
password = getpass.getpass('ecoinvent password: ')
```

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
