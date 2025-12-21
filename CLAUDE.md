# Cortex

Hierarchical dynamic domain ontology system.

## Commands

- `/init` - Initialize project (creates context.md, state.jsonl)
- `/start` - Bootstrap as meta-agent
- `/create-agent <name>` - Create new agent

## Structure

```
.claude/
├── agents/           # All agents (meta-agent + your agents)
├── commands/         # Slash commands
├── scripts/          # Core mechanics
├── worlds/           # Child cortexes
├── context.md        # Project ontology
├── state.jsonl       # Project history
└── manifest.json     # Registry
```

## Core Concepts

1. **Structure = Ontology** - Filesystem IS knowledge graph
2. **Identity ≠ Location** - Agents know what they do vs where they are
3. **Every folder**: context.md + state.jsonl
4. **Bootstrap first** - Agents load 4-section context before acting
