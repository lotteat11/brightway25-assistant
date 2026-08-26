#!/usr/bin/env bash
# Place the tool-neutral instructions where each AI tool expects to find them.
#
# AGENTS.md in this folder is the single source of truth. Copilot and Cursor read
# from fixed paths, so this copies it there. Run after editing AGENTS.md.
#
#   bash ai-adapters/sync-adapters.sh
#
# Commit the generated files — students should not have to run anything.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/ai-adapters/AGENTS.md"

[ -f "$SRC" ] || { echo "error: $SRC not found" >&2; exit 1; }

# Root AGENTS.md — read by Claude Code, VS Code, Cursor, Codex and others
cp "$SRC" "$ROOT/AGENTS.md"
echo "  → AGENTS.md"

# GitHub Copilot
mkdir -p "$ROOT/.github"
cp "$SRC" "$ROOT/.github/copilot-instructions.md"
echo "  → .github/copilot-instructions.md"

# Cursor — needs MDC frontmatter to apply globally
mkdir -p "$ROOT/.cursor/rules"
{
    printf -- '---\ndescription: Advanced LCA course — Brightway 2.5 assistant and tutor\nalwaysApply: true\n---\n\n'
    cat "$SRC"
} > "$ROOT/.cursor/rules/brightway25.mdc"
echo "  → .cursor/rules/brightway25.mdc"

echo "done — commit the generated files."
