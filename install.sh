#!/bin/bash
# install.sh — Installs all claude-ai-workers agents and scripts into ~/.claude/
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

AGENTS_SRC="$REPO_DIR/agents"
SCRIPTS_SRC="$REPO_DIR/scripts"
AGENTS_DEST="$HOME/.claude/agents"
SCRIPTS_DEST="$HOME/.claude/scripts"

mkdir -p "$AGENTS_DEST" "$SCRIPTS_DEST"

echo "Installing agents..."
for f in "$AGENTS_SRC"/*.md; do
    cp "$f" "$AGENTS_DEST/"
    echo "  -> $AGENTS_DEST/$(basename "$f")"
done

echo "Installing scripts..."
for f in "$SCRIPTS_SRC"/*.sh; do
    cp "$f" "$SCRIPTS_DEST/"
    chmod +x "$SCRIPTS_DEST/$(basename "$f")"
    echo "  -> $SCRIPTS_DEST/$(basename "$f") (executable)"
done

echo ""
echo "Done. Verify with:"
echo "  ls ~/.claude/agents/"
echo "  ls ~/.claude/scripts/"
