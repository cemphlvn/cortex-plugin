# Cortex Ontology

## Axioms

1. **Structure = Ontology** - Filesystem IS knowledge graph
2. **Identity ≠ Location** - Agents know what vs where
3. **Bootstrap First** - Load 4-section context before acting
4. **Append-Only State** - state.jsonl tracks history

## Files

- `context.md` - WHAT this folder IS
- `state.jsonl` - WHAT HAS HAPPENED

## Agent Context (4 Sections)

| Section | Source | Answers |
|---------|--------|---------|
| System Ontology | CORTEX.md | Rules |
| Agent Identity | AGENT.md | What I do |
| Location | context.md chain | Where I am |
| State | state.jsonl | What happened |

## Structure

```
.claude/
├── agents/         # All agents
├── worlds/         # Child cortexes
├── context.md      # Project ontology
├── state.jsonl     # History
└── manifest.json   # Registry
```
