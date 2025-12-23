---
name: foundation-models
description: "Apple Foundation Models framework patterns"
---

# Foundation Models

## Purpose

Knowledge about Apple's Foundation Models framework for on-device AI with guided generation.

## Key APIs

### LanguageModelSession
```swift
let session = LanguageModelSession(instructions: "...")
let response = try await session.respond(to: prompt, schema: schema)
```

### DynamicGenerationSchema
Build schemas at runtime:
```swift
// Primitives
let string = DynamicGenerationSchema(type: String.self)
let int = DynamicGenerationSchema(type: Int.self)
let bool = DynamicGenerationSchema(type: Bool.self)

// Arrays
let stringArray = DynamicGenerationSchema(arrayOf: string, minimumElements: 0, maximumElements: 10)

// Objects with properties
let obj = DynamicGenerationSchema(
  name: "MyObject",
  description: "What this object represents",
  properties: [
    .init(name: "field1", description: "Field meaning", schema: string),
    .init(name: "field2", description: "Field meaning", schema: stringArray)
  ]
)

// References (for reuse)
let ref = DynamicGenerationSchema(referenceTo: "MyObject")
```

### GenerationSchema
Validates dynamic schema graph:
```swift
let schema = try GenerationSchema(root: rootSchema, dependencies: [dep1, dep2])
```

### GeneratedContent
Dynamic decoding:
```swift
let value = try content.value(String.self, forProperty: "fieldName")
let nested = try content.value(GeneratedContent.self, forProperty: "objectField")
```

## Guided Generation

Schema constrains model output format. No JSON-in-prompt needed.

Options:
- `includeSchemaInPrompt: true` — injects schema into prompt for stricter adherence

## Patterns

### Property Descriptions = Semantics
Schema property descriptions guide the model. This is where meaning lives.

### One Engine, Many Schemas
Don't create Swift types per schema. Build schemas dynamically.

## References

- Apple Developer: Foundation Models Framework
- WWDC sessions on Apple Intelligence
