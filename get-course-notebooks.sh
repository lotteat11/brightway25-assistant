#!/usr/bin/env bash
#
# Downloads the Advanced LCA course notebooks and points them at the bw25 kernel.
#
#     bash get-course-notebooks.sh
#
# The notebooks live in Massimo Pizzol's repository:
#     https://github.com/massimopizzol/advanced-lca-notebooks
#
# They are placed in Course-material-bw25/ inside this folder, kept together —
# notebooks 4, 7 and 8 import lci_to_bw2.py and read CSV files from their own
# directory, so the folder cannot be split up.
#
# Run again any time to pick up upstream changes. Your own edits to a notebook
# would be overwritten, so the script asks first.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

UPSTREAM="https://github.com/massimopizzol/advanced-lca-notebooks.git"
FOLDER="Course-material-bw25"
KERNEL_NAME="bw25"
KERNEL_LABEL="Python (bw25)"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1" >&2; }

echo
bold "Advanced LCA course notebooks"
echo

command -v git >/dev/null 2>&1 || { fail "git is not installed."; exit 1; }

if [ -d "$FOLDER" ]; then
    warn "$FOLDER/ already exists."
    printf "  Replace it? Any changes you made will be lost. [y/N] "
    read -r reply
    case "$reply" in
        [yY]*) rm -rf "$FOLDER" ;;
        *) echo; echo "  Left alone. Nothing downloaded."; echo; exit 0 ;;
    esac
fi

echo "  Downloading..."
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

git clone --quiet --depth 1 --filter=blob:none --sparse "$UPSTREAM" "$TMP/repo"
git -C "$TMP/repo" sparse-checkout set "$FOLDER" --quiet 2>/dev/null \
    || git -C "$TMP/repo" sparse-checkout set "$FOLDER"

[ -d "$TMP/repo/$FOLDER" ] || { fail "Could not find $FOLDER upstream."; exit 1; }

mkdir -p "$FOLDER"
# Notebooks, data and the helper module. The .html renders are ~3.8 MB of
# duplicates of the notebooks, so they are skipped.
for pattern in '*.ipynb' '*.csv' '*.xlsx' '*.png' '*.py'; do
    find "$TMP/repo/$FOLDER" -maxdepth 1 -name "$pattern" -exec cp {} "$FOLDER/" \; 2>/dev/null || true
done

count=$(find "$FOLDER" -maxdepth 1 -name '*.ipynb' | wc -l | tr -d ' ')
ok "$count notebooks, plus data files and lci_to_bw2.py"

# The upstream notebooks carry kernelspec "python3", which points at whatever
# Python Jupyter defaults to — not the environment set up here. Without this,
# every notebook fails on its first import until the student changes the kernel
# by hand, which is the step people miss.
PY_BIN="$ROOT/.venv/bin/python"
[ -x "$PY_BIN" ] || PY_BIN="$ROOT/.venv/Scripts/python.exe"
[ -x "$PY_BIN" ] || PY_BIN="$(command -v python3 || command -v python)"

"$PY_BIN" - "$FOLDER" "$KERNEL_NAME" "$KERNEL_LABEL" <<'PYEOF'
import json, pathlib, sys

folder, name, label = sys.argv[1], sys.argv[2], sys.argv[3]
changed = 0

for nb_path in sorted(pathlib.Path(folder).glob("*.ipynb")):
    nb = json.loads(nb_path.read_text(encoding="utf-8"))
    ks = nb.setdefault("metadata", {}).get("kernelspec", {})
    if ks.get("name") != name:
        nb["metadata"]["kernelspec"] = {
            "display_name": label,
            "language": "python",
            "name": name,
        }
        nb_path.write_text(json.dumps(nb, indent=1, ensure_ascii=False), encoding="utf-8")
        changed += 1

print(f"  \033[32m✓\033[0m Kernel set to \"{label}\" in {changed} notebook(s)")
PYEOF

echo
bold "Done."
echo
echo "  The notebooks are in $FOLDER/"
echo
echo "  Suggested order:"
echo "    Project_create_and_locate  →  0  →  1  →  2  →  3  →  4"
echo "                                          ↓"
echo "                                          5  →  6"
echo "                                          ↓"
echo "                                          7  →  8"
echo
echo "  Notebook 3 needs an ecoinvent licence. Notebooks 5-8 only need 1-2, so a"
echo "  missing licence does not block the uncertainty and sensitivity material."
echo
echo "  Keep the folder together — notebooks 4, 7 and 8 read lci_to_bw2.py and"
echo "  CSV files from their own directory."
echo
