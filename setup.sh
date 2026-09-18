#!/usr/bin/env bash
#
# Sets up everything you need to work with Brightway 2.5:
#
#   1. A Python virtual environment (.venv) with Brightway and the scientific stack
#   2. A Jupyter kernel so notebooks can find it
#   3. Either a folder for your own work, or the Advanced LCA course notebooks
#
# Run it from this directory:
#
#     bash setup.sh
#
# It asks what you want to use it for. Takes about 5 minutes.
# Safe to run again — it skips whatever already exists.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

VENV="$ROOT/.venv"
KERNEL_NAME="bw25"
KERNEL_LABEL="Python (bw25)"
PROJECT_DIR="${1:-my-project}"

INSTALL_OK=no      # set by the verification step
EI_DONE=no         # yes / no / skip / failed — drives the closing message
EI_PROJECT=""

bold()  { printf '\033[1m%s\033[0m\n' "$1"; }
ok()    { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn()  { printf '  \033[33m!\033[0m %s\n' "$1"; }
fail()  { printf '  \033[31m✗\033[0m %s\n' "$1" >&2; }

echo
bold "Brightway 2.5 Assistant — setup"
echo

# ------------------------------------------------------------- What is this for?

MODE="${SETUP_MODE:-}"

if [ -z "$MODE" ]; then
    echo "  What do you want to use this for?"
    echo
    echo "    1) My own Brightway work"
    echo "       Creates a project folder with an example notebook to check the"
    echo "       installation works."
    echo
    echo "    2) Learning from the Advanced LCA course notebooks"
    echo "       Downloads the ten course notebooks (matrix LCI, ecoinvent, Monte"
    echo "       Carlo, sensitivity analysis) and sets them up to run."
    echo
    echo "    3) Both"
    echo
    printf "  Choose [1/2/3, default 1]: "
    read -r answer
    echo
    case "${answer:-1}" in
        1|"") MODE="own" ;;
        2)    MODE="course" ;;
        3)    MODE="both" ;;
        *)    warn "Not a valid choice — setting up your own project folder."
              MODE="own" ;;
    esac
fi

case "$MODE" in
    own)    ok "Setting up for your own work" ;;
    course) ok "Setting up with the course notebooks" ;;
    both)   ok "Setting up both" ;;
esac

# ---------------------------------------------------------------- 1. Python

bold "1/4  Checking Python"

PYTHON=""
for candidate in python3.12 python3.11 python3; do
    if command -v "$candidate" >/dev/null 2>&1; then
        version=$("$candidate" -c 'import sys; print("%d.%d" % sys.version_info[:2])')
        major=${version%%.*}; minor=${version##*.}
        if [ "$major" -eq 3 ] && [ "$minor" -ge 10 ]; then
            PYTHON="$candidate"; break
        fi
    fi
done

if [ -z "$PYTHON" ]; then
    fail "No Python 3.10 or newer found."
    echo
    echo "  Install Python first:"
    echo "    macOS    brew install python@3.11"
    echo "             or download from https://www.python.org/downloads/"
    echo "    Windows  https://www.python.org/downloads/  (tick \"Add python.exe to PATH\")"
    echo "    Linux    sudo apt install python3.11 python3.11-venv"
    echo
    exit 1
fi

ok "$($PYTHON --version) at $(command -v $PYTHON)"

# ------------------------------------------------------- 2. Virtual environment

echo
bold "2/4  Setting up the virtual environment"

if [ -d "$VENV" ]; then
    ok "Already exists at .venv — reusing it"
else
    "$PYTHON" -m venv "$VENV"
    ok "Created .venv"
fi

VPY="$VENV/bin/python"
[ -x "$VPY" ] || VPY="$VENV/Scripts/python.exe"     # Windows / Git Bash

"$VPY" -m pip install --quiet --upgrade pip
ok "pip up to date"

echo "  Installing packages — this takes a few minutes..."
"$VPY" -m pip install --quiet \
    brightway25 \
    ecoinvent_interface \
    stats_arrays \
    numpy pandas scipy matplotlib seaborn \
    SALib \
    jupyterlab ipykernel openpyxl

ok "Brightway 2.5 and the scientific stack installed"

# Apple Silicon: bw2calc warns about this on every import, and it does make
# calculations noticeably faster. Optional — a failure here is not fatal.
if [ "$(uname -s)" = "Darwin" ] && [ "$(uname -m)" = "arm64" ]; then
    if "$VPY" -m pip install --quiet scikit-umfpack 2>/dev/null; then
        ok "scikit-umfpack installed (faster calculations on Apple Silicon)"
    else
        warn "scikit-umfpack unavailable — Brightway will warn on import, but works fine"
    fi
fi

# ------------------------------------------------------------- 3. Jupyter kernel

echo
bold "3/4  Registering the Jupyter kernel"

"$VPY" -m ipykernel install --user \
    --name "$KERNEL_NAME" --display-name "$KERNEL_LABEL" >/dev/null 2>&1

ok "Kernel \"$KERNEL_LABEL\" registered"
warn "In each notebook: Kernel → Change Kernel → $KERNEL_LABEL"

# --------------------------------------------------------- 4. Your project folder

if [ "$MODE" = "own" ] || [ "$MODE" = "both" ]; then

echo
bold "4/4  Creating your project folder"

if [ -d "$PROJECT_DIR" ]; then
    ok "$PROJECT_DIR/ already exists — leaving it alone"
else
    mkdir -p "$PROJECT_DIR"

    cat > "$PROJECT_DIR/first_lca.ipynb" <<'NOTEBOOK'
{
 "cells": [
  {"cell_type": "markdown", "id": "c1", "metadata": {}, "source": [
    "# First LCA\n",
    "\n",
    "A tiny system, end to end, to confirm everything works.\n",
    "\n",
    "**Before running:** Kernel → Change Kernel → Python (bw25)"
  ]},
  {"cell_type": "markdown", "id": "c1b", "metadata": {}, "source": [
    "### Two warnings you can ignore\n",
    "\n",
    "You will probably see these below. Neither is an error \u2014 red text in Jupyter is not\n",
    "always a failure.\n",
    "\n",
    "- **scikit-umfpack warning** \u2014 calculations are slightly slower without it on Apple\n",
    "  Silicon. Nothing is broken.\n",
    "- **Not able to determine geocollections** \u2014 refers to regionalised LCA, which you are\n",
    "  not doing."
  ]},
  {"cell_type": "code", "execution_count": null, "id": "c2", "metadata": {}, "outputs": [], "source": [
    "import sys\n",
    "print(sys.executable)   # should contain .venv"
  ]},
  {"cell_type": "code", "execution_count": null, "id": "c3", "metadata": {}, "outputs": [], "source": [
    "import bw2data as bd\n",
    "import bw2calc as bc\n",
    "\n",
    "bd.projects.set_current('my_first_project')\n",
    "print(bd.projects.current)"
  ]},
  {"cell_type": "markdown", "id": "c4", "metadata": {}, "source": [
    "## A two-activity system\n",
    "\n",
    "Electricity production consuming fuel, both emitting CO2."
  ]},
  {"cell_type": "code", "execution_count": null, "id": "c5", "metadata": {}, "outputs": [], "source": [
    "bd.Database('bio').write({\n",
    "    ('bio', 'co2'): {'name': 'CO2', 'type': 'emission', 'categories': ('air',)},\n",
    "})\n",
    "\n",
    "bd.Database('db').write({\n",
    "    ('db', 'el'): {\n",
    "        'name': 'Electricity production', 'unit': 'kilowatt hour',\n",
    "        'exchanges': [\n",
    "            {'input': ('db', 'el'),   'amount': 10, 'type': 'production'},\n",
    "            {'input': ('db', 'fuel'), 'amount': -2, 'type': 'technosphere'},\n",
    "            {'input': ('bio', 'co2'), 'amount': 1,  'type': 'biosphere'},\n",
    "        ]},\n",
    "    ('db', 'fuel'): {\n",
    "        'name': 'Fuel production', 'unit': 'kilogram',\n",
    "        'exchanges': [\n",
    "            {'input': ('db', 'fuel'), 'amount': 100, 'type': 'production'},\n",
    "            {'input': ('bio', 'co2'), 'amount': 10,  'type': 'biosphere'},\n",
    "        ]},\n",
    "})\n",
    "print(len(bd.Database('db')), 'activities')"
  ]},
  {"cell_type": "code", "execution_count": null, "id": "c6", "metadata": {}, "outputs": [], "source": [
    "method = bd.Method(('demo', 'gwp'))\n",
    "method.register()\n",
    "method.write([(('bio', 'co2'), 1.0)])\n",
    "\n",
    "el = bd.get_activity(('db', 'el'))\n",
    "lca = bc.LCA({el: 1000}, ('demo', 'gwp'))\n",
    "lca.lci()    # trace the supply chain: what is emitted in total\n",
    "lca.lcia()   # weight those emissions by the impact method\n",
    "\n",
    "print(f'{lca.score:.1f} kg CO2-eq per 1000 kWh')   # expect 80.0"
  ]},
  {"cell_type": "markdown", "id": "c7", "metadata": {}, "source": [
    "If that printed **80.0**, the whole stack works.\n",
    "\n",
    "Now start your own work here, or ask the assistant:\n",
    "*\"Help me build a product system for ...\"*"
  ]}
 ],
 "metadata": {
  "kernelspec": {"display_name": "Python (bw25)", "language": "python", "name": "bw25"},
  "language_info": {"name": "python"}
 },
 "nbformat": 4, "nbformat_minor": 5
}
NOTEBOOK

    ok "Created $PROJECT_DIR/ with first_lca.ipynb"
fi

# The ecoinvent walkthrough lives in templates/ (my-project/ is gitignored,
# being the student's own work). Copy it in, without clobbering any edits.
if [ -f "$ROOT/templates/00_setup_ecoinvent.ipynb" ] \
   && [ ! -f "$PROJECT_DIR/00_setup_ecoinvent.ipynb" ]; then
    cp "$ROOT/templates/00_setup_ecoinvent.ipynb" "$PROJECT_DIR/"
    ok "Added $PROJECT_DIR/00_setup_ecoinvent.ipynb"
fi

fi

# ------------------------------------------------- 4b. Course notebooks

if [ "$MODE" = "course" ] || [ "$MODE" = "both" ]; then
    echo
    bold "Downloading the course notebooks"
    if [ -x "$ROOT/get-course-notebooks.sh" ] || [ -f "$ROOT/get-course-notebooks.sh" ]; then
        # Runs its own git clone and rewrites each notebook's kernel to bw25.
        bash "$ROOT/get-course-notebooks.sh" 2>&1 | sed -n '/Downloading/,/^$/p' | grep -E '✓|!' || true
    else
        fail "get-course-notebooks.sh is missing from this folder."
    fi
fi

# ------------------------------------------------------------------ Verify

echo
bold "Verifying"

if "$VPY" - <<'CHECK' 2>/dev/null
import bw2data, bw2calc, bw2io, stats_arrays, SALib
CHECK
then
    ok "All packages import correctly"
else
    fail "Something did not install. Try running setup.sh again."
    exit 1
fi

# Importing is not the same as calculating. This runs a tiny LCA end to end
# in a throwaway project, so a broken solver or biosphere shows up now rather
# than in the middle of someone's first exercise.
if "$VPY" - <<'CALC' >/dev/null 2>&1
import bw2data as bd, bw2calc as bc
bd.projects.set_current('__setup_selftest__')
bd.Database('bio').write({('bio','co2'): {'name':'CO2','type':'emission','categories':('air',)}})
bd.Database('db').write({
    ('db','el'): {'name':'E','unit':'kilowatt hour','exchanges':[
        {'input':('db','el'),'amount':10,'type':'production'},
        {'input':('bio','co2'),'amount':1,'type':'biosphere'}]}})
m = bd.Method(('t','gwp')); m.register(); m.write([(('bio','co2'), 1.0)])
lca = bc.LCA({bd.get_activity(('db','el')): 10}, ('t','gwp'))
lca.lci(); lca.lcia()
assert abs(lca.score - 1.0) < 1e-9, lca.score
bd.projects.delete_project('__setup_selftest__', delete_dir=True)
CALC
then
    ok "A test calculation ran correctly"
    INSTALL_OK=yes
else
    warn "Packages import, but a test calculation failed."
    warn "Brightway may still work — check with $PROJECT_DIR/first_lca.ipynb"
    INSTALL_OK=no
fi

# ------------------------------------------------------- ecoinvent (optional)
#
# Only offered once the install is known good — there is no point asking for a
# licence when the thing that would use it does not run. Skipped when stdin is
# not a terminal (piped/CI), so an unattended run cannot hang at a prompt.

EI_DONE=no

if [ "$INSTALL_OK" = "yes" ] && [ -t 0 ] && [ -z "${SKIP_ECOINVENT:-}" ]; then

    # Is it already somewhere on this machine?
    # Brightway logs to stdout, so tag our own lines and keep only those —
    # otherwise its log output is mistaken for database names.
    EI_EXISTING=$("$VPY" - <<'FIND' 2>/dev/null | sed -n 's/^EIFOUND://p' || true
import bw2data as bd
for p in bd.projects:
    bd.projects.set_current(p.name)
    for d in bd.databases:
        if 'ecoinvent' in d.lower() and 'biosphere' not in d.lower():
            print(f'EIFOUND:{p.name}\t{d}')
FIND
)

    echo
    bold "ecoinvent"

    if [ -n "$EI_EXISTING" ]; then
        ok "Already on this machine:"
        printf '%s\n' "$EI_EXISTING" | while IFS=$'\t' read -r proj db; do
            echo "      $db  (project: $proj)"
        done
        echo
        echo "  No need to download it again — $PROJECT_DIR/00_setup_ecoinvent.ipynb"
        echo "  can copy it into a new project in seconds."
        EI_DONE=skip
    else
        echo
        echo "  ecoinvent is the background database — the upstream data your own"
        echo "  model links to. It is optional now and can be done later."
        echo
        echo "  Two things must be true first:"
        echo "    1. You have your own ecoinvent username and password"
        echo "       (university SSO is often NOT the same thing)"
        echo "    2. You have logged in at ecoinvent.org in a browser at least once"
        echo "       and accepted the licence + personal-data agreements"
        echo
        warn "Without step 2, authentication fails from Python — and the error"
        warn "message says nothing about agreements. It is the biggest time sink."
        echo
        echo "  The download takes 10-30 minutes with no progress bar."
        echo
        printf "  Set up ecoinvent now? [y/N]: "
        read -r ei_answer

        case "${ei_answer:-n}" in
            y|Y|yes|YES)
                echo
                echo "  Which system model? This is a methodological choice, not a"
                echo "  setting — it becomes part of the database name, so changing"
                echo "  it later means re-downloading and rewriting every link."
                echo
                echo "    1) cutoff         most attributional studies (usual choice)"
                echo "    2) consequential  consequential LCA"
                echo "    3) apos           allocation at the point of substitution"
                echo
                printf "  Choose [1/2/3, default 1]: "
                read -r sm_answer
                case "${sm_answer:-1}" in
                    2) SYSTEM_MODEL=consequential ;;
                    3) SYSTEM_MODEL=apos ;;
                    *) SYSTEM_MODEL=cutoff ;;
                esac

                printf "  ecoinvent version [default 3.11]: "
                read -r ver_answer
                EI_VERSION="${ver_answer:-3.11}"

                printf "  Project name for it [default %s]: " "$KERNEL_NAME-project"
                read -r proj_answer
                EI_PROJECT="${proj_answer:-$KERNEL_NAME-project}"

                echo
                printf "  ecoinvent username: "
                read -r EI_USER
                printf "  ecoinvent password (not shown): "
                stty -echo 2>/dev/null || true
                read -r EI_PASS
                stty echo 2>/dev/null || true
                echo
                echo

                if [ -z "$EI_USER" ] || [ -z "$EI_PASS" ]; then
                    warn "No credentials given — skipping."
                    EI_DONE=no
                else
                    echo "  Downloading ecoinvent $EI_VERSION $SYSTEM_MODEL into '$EI_PROJECT'."
                    echo "  This takes 10-30 minutes. Do not interrupt it."
                    echo

                    # Credentials go through the environment, never the command
                    # line, so they stay out of the process list and shell history.
                    if EI_PROJECT="$EI_PROJECT" EI_VERSION="$EI_VERSION" \
                       EI_SYSTEM_MODEL="$SYSTEM_MODEL" \
                       EI_USER="$EI_USER" EI_PASS="$EI_PASS" \
                       "$VPY" - <<'IMPORT'
import os, sys
import bw2data as bd, bw2io as bi

bd.projects.set_current(os.environ['EI_PROJECT'])
try:
    bi.import_ecoinvent_release(
        version=os.environ['EI_VERSION'],
        system_model=os.environ['EI_SYSTEM_MODEL'],
        username=os.environ['EI_USER'],
        password=os.environ['EI_PASS'])
except Exception as exc:
    print(f'\n{type(exc).__name__}: {exc}', file=sys.stderr)
    sys.exit(1)

dbs = list(bd.databases)
ei = [d for d in dbs if 'ecoinvent' in d.lower() and 'biosphere' not in d.lower()]
bio = [d for d in dbs if 'biosphere' in d.lower()]
if not ei or not bio:
    print(f'\nImport finished but databases are missing: {dbs}', file=sys.stderr)
    sys.exit(1)

n_act, n_bio = len(bd.Database(ei[0])), len(bd.Database(bio[0]))
if min(n_act, n_bio, len(bd.methods)) < 10:
    print(f'\nImport looks incomplete: {n_act} activities, {n_bio} flows',
          file=sys.stderr)
    sys.exit(1)

print(f'   {ei[0]}: {n_act:,} activities', file=sys.stderr)
print(f'   {bio[0]}: {n_bio:,} biosphere flows', file=sys.stderr)
print(f'   {len(bd.methods):,} LCIA methods', file=sys.stderr)
IMPORT
                    then
                        ok "ecoinvent imported into project '$EI_PROJECT'"
                        EI_DONE=yes
                    else
                        echo
                        fail "The ecoinvent import did not complete."
                        echo
                        echo "  Most likely causes, in order:"
                        echo "    - Licence/personal-data agreement not accepted at ecoinvent.org"
                        echo "    - Username/password is a university SSO login, not an ecoinvent account"
                        echo "    - Your licence does not cover $EI_VERSION / $SYSTEM_MODEL"
                        echo
                        echo "  A half-imported project fails confusingly later. Delete it"
                        echo "  before retrying:"
                        echo "    .venv/bin/python -c \"import bw2data as bd; bd.projects.delete_project('$EI_PROJECT', delete_dir=True)\""
                        echo
                        echo "  Everything else is installed — this does not block the rest."
                        EI_DONE=failed
                    fi
                    unset EI_USER EI_PASS
                fi
                ;;
            *)
                echo
                ok "Skipped — run $PROJECT_DIR/00_setup_ecoinvent.ipynb when you are ready."
                EI_DONE=no
                ;;
        esac
    fi
fi

# ------------------------------------------------------------------- Done

echo
bold "Done."
echo
echo "  1. Open THIS folder in VS Code — not a single file, or the assistant"
echo "     will not be loaded:"
echo "       File → Open Folder… → $(basename "$ROOT")"
echo

if [ "$MODE" = "own" ] || [ "$MODE" = "both" ]; then
    echo "  2. Open $PROJECT_DIR/first_lca.ipynb"
    echo "  3. Kernel → Change Kernel → $KERNEL_LABEL"
    echo "  4. Run all cells. It should print 80.0"
    echo
fi

if [ "$MODE" = "course" ] || [ "$MODE" = "both" ]; then
    echo "  2. Open Course-material-bw25/ and start with 0-LCI-matrix.ipynb"
    echo "     The kernel is already set — just run the cells."
    echo
    echo "     Order:  Project_create_and_locate → 0 → 1 → 2 → 3 → 4"
    echo "                                             ↓"
    echo "                                             5 → 6"
    echo "                                             ↓"
    echo "                                             7 → 8"
    echo
fi

echo "  Check the assistant is active — ask your AI tool:"
echo "    \"How do I run a Monte Carlo in Brightway 2.5?\""
echo "    Correct: mentions use_distributions=True"
echo "    Wrong:   mentions MonteCarloLCA  (the folder is not open)"
echo

case "$EI_DONE" in
    yes)
        echo "  ecoinvent is ready in project '$EI_PROJECT'. Point your notebooks at it:"
        echo "    bd.projects.set_current('$EI_PROJECT')"
        ;;
    skip)
        echo "  ecoinvent is already on this machine — $PROJECT_DIR/00_setup_ecoinvent.ipynb"
        echo "  copies it into a new project without downloading again."
        ;;
    failed)
        echo "  ecoinvent did not import — see the causes listed above."
        echo "  Retry any time with $PROJECT_DIR/00_setup_ecoinvent.ipynb"
        ;;
    *)
        echo "  ecoinvent needs a licence and is not set up yet."
        echo "  Run $PROJECT_DIR/00_setup_ecoinvent.ipynb when you are ready,"
        echo "  or see GETTING-STARTED.md, step 4."
        ;;
esac
echo
