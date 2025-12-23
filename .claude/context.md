# Prism

## Domain

- **Type**: iOS App
- **Stack**: Swift, SwiftUI, Apple Foundation Models Framework
- **Purpose**: Dynamic structured output generator using on-device AI

## Core Equation

```
C(I) = O

Where:
  I = user input (string)
  C = instructions + GenerationSchema
  O = ordered BeamOutputs
```

## Architecture Flow

```
PrismDefinition (data) → compile → PrismExecutable (runtime) → run → BeamOutputs (UI)
```

## Goals

1. Enable users to create custom "Prisms" that generate structured outputs
2. Run entirely on-device via Apple Foundation Models
3. Universal engine: any PrismDefinition runs without app updates

## Constraints

- **No compile-time codegen**: user Prisms work without app updates
- **Schema-safe identifiers**: beam IDs and field keys must be snake_case `[A-Za-z0-9_]+`
- **MVP input**: single string incident
- **MVP output types**: string, stringArray only

## Key Types

| Type | Role |
|------|------|
| `PrismDefinition` | Pure data (stored) |
| `PrismExecutable` | Runtime plan (schema + decoder) |
| `BeamOutput` | UI output |
| `PrismSchemaCompiler` | Data → executable |
| `PrismEngine` | Runs executable with input |
| `PrismExecutableCache` | Caches compiled executables |

## Structure

```
Prism/
├── App/
│   └── PrismApp.swift
├── Models/
│   ├── PrismDefinition.swift
│   ├── BeamSpec.swift
│   ├── BeamOutput.swift
│   └── BeamValue.swift
├── Engine/
│   ├── PrismSchemaCompiler.swift
│   ├── PrismExecutable.swift
│   ├── PrismEngine.swift
│   └── PrismExecutableCache.swift
├── Views/
│   ├── PrismListView.swift
│   ├── PrismRunView.swift
│   └── BeamOutputView.swift
└── Resources/
```

## Agents

| Agent | Purpose |
|-------|---------|
| meta-agent | Bootstrap, structure, orchestration |
| ios-agent | SwiftUI, iOS patterns, UI implementation |
| models-agent | Foundation Models, schema compilation, engine |

## Evolution

See `state.jsonl` for history.
