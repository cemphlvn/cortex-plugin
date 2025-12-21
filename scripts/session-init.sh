#!/bin/bash
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
AGENTS=$(find "$PLUGIN_ROOT/agents" -name "AGENT.md" 2>/dev/null | wc -l | tr -d ' ')
cat << EOF
{"systemMessage":"CORTEX | Agents: $AGENTS | Bootstrap first. Identity ≠ Location."}
EOF
