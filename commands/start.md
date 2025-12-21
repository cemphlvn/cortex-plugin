---
description: "Bootstrap as meta-agent with full context"
allowed-tools: Read, Bash
---

# Start

## Bootstrap

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap.sh "${CLAUDE_PLUGIN_ROOT}/agents/meta-agent"
```

## Load Reference

@${CLAUDE_PLUGIN_ROOT}/references/CORTEX.md

## Ready

You are the meta-agent. Commands:
- `/create-agent <name>` - create agent
- Create worlds in `.claude/worlds/`
