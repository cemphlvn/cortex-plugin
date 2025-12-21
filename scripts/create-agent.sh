#!/bin/bash
NAME="${1:-}"
DOMAIN="${2:-general}"

[[ -z "$NAME" ]] && echo "Usage: create-agent.sh <name> [domain]" && exit 1

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
PLUGIN="$(dirname "$SCRIPT_DIR")"
AGENT="$PLUGIN/agents/$NAME"

[[ -d "$AGENT" ]] && echo "Exists: $AGENT" && exit 1

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
mkdir -p "$AGENT"

cat > "$AGENT/AGENT.md" << EOF
---
name: "$NAME"
description: "[EDIT: When to use this agent]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# FIRST: Bootstrap

\`\`\`bash
\${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap.sh "\${CLAUDE_PLUGIN_ROOT}/agents/$NAME"
\`\`\`

---

# $NAME

## What I Do

[EDIT]

## Identity ≠ Location

This file = IDENTITY. context.md = LOCATION.
EOF

cat > "$AGENT/context.md" << EOF
# Context: $NAME

- **Type**: Agent
- **Domain**: $DOMAIN
- **Path**: .claude/agents/$NAME
EOF

echo "{\"ts\":\"$TS\",\"event\":\"created\",\"actor\":\"create-agent\",\"data\":{\"domain\":\"$DOMAIN\"}}" > "$AGENT/state.jsonl"

echo "Created: $AGENT"
