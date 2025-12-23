---
name: prism-architecture
description: "Prism app architecture and core types"
---

# Prism Architecture

## Purpose

Core architecture knowledge for the Prism structured output generator.

## Core Equation

```
C(I) = O

C = instructions + GenerationSchema (compiled from PrismDefinition)
I = user input string
O = [BeamOutput] (ordered, typed)
```

## Architecture Flow

```
PrismDefinition (data) → compile → PrismExecutable (runtime) → run → BeamOutputs (UI)
```

## Key Types

### PrismDefinition (Data Layer)
```swift
struct PrismDefinition: Codable, Identifiable, Sendable {
  let id: UUID
  var name: String
  var instructions: String
  var incidentBeam: IncidentBeamSpec
  var refractedBeams: [BeamSpec]
  var version: Int
}

struct BeamSpec: Codable, Identifiable, Sendable {
  let id: String          // snake_case, schema-safe
  var title: String       // human readable
  var description: String?
  var fields: [BeamFieldSpec]
}

struct BeamFieldSpec: Codable, Sendable {
  let key: String         // snake_case, schema-safe
  var guide: String       // becomes schema property description
  var valueType: BeamValueType
}

enum BeamValueType: String, Codable, Sendable {
  case string
  case stringArray
}
```

### PrismExecutable (Runtime)
```swift
struct PrismExecutable: Sendable {
  let prismId: UUID
  let version: Int
  let instructions: String
  let schema: GenerationSchema
  let decoder: @Sendable (GeneratedContent) throws -> [BeamOutput]
}
```

### BeamOutput (UI Layer)
```swift
struct BeamOutput: Identifiable, Sendable {
  let id: String
  var fields: [FieldOutput]
}

struct FieldOutput: Identifiable, Sendable {
  var id: String { key }
  let key: String
  let value: BeamValue
}

enum BeamValue: Sendable {
  case string(String)
  case stringArray([String])
}
```

## Schema Strategy

Beams and fields as named properties:
```
PrismOutput
├── beam_one (object)
│   ├── field_a : String
│   └── field_b : [String]
└── beam_two (object)
    └── field_c : String
```

**NOT** arrays of arbitrary objects.

## Invariants

1. **Output order = definition order** — UI relies on this
2. **No compile-time types per Prism** — users create without app updates
3. **Schema descriptions = semantics** — guides live in property descriptions
4. **IDs are snake_case** — `[A-Za-z0-9_]+` only

## Anti-Patterns

- Generating Swift structs per Prism
- JSON-in-prompt instead of schema
- Arbitrary keys in schema objects
- Relying on model to maintain order
