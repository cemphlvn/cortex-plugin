#!/bin/bash
# bootstrap.sh - Load 4-section agent context

AGENT="${1:-.}"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
PLUGIN="$(dirname "$SCRIPT_DIR")"

[[ -d "$AGENT" ]] || AGENT="$PLUGIN/$AGENT"
AGENT="$(realpath "$AGENT" 2>/dev/null || echo "$AGENT")"

echo "╔═══════════════════════════════════════════════════════╗"
echo "║              AGENT BOOTSTRAP                          ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

echo "─── 1. SYSTEM ONTOLOGY ───"
[[ -f "$PLUGIN/references/CORTEX.md" ]] && cat "$PLUGIN/references/CORTEX.md" || echo "[none]"
echo ""

echo "─── 2. AGENT IDENTITY ───"
[[ -f "$AGENT/AGENT.md" ]] && cat "$AGENT/AGENT.md" || echo "[none]"
echo ""

echo "─── 3. LOCATION CONTEXT ───"
DIR="$AGENT"
while [[ "$DIR" == "$PLUGIN"* ]]; do
    [[ -f "$DIR/context.md" ]] && echo "[$DIR]" && cat "$DIR/context.md" && echo ""
    DIR="$(dirname "$DIR")"
    [[ "$DIR" == "$(dirname "$DIR")" ]] && break
done
echo ""

echo "─── 4. CURRENT STATE ───"
[[ -f "$AGENT/state.jsonl" ]] && tail -5 "$AGENT/state.jsonl" || echo "[none]"
echo ""

echo "═══════════════════════════════════════════════════════"
echo "  Identity ≠ Location. Prompt ≠ Position.             "
echo "═══════════════════════════════════════════════════════"
