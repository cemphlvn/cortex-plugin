import Foundation
import FoundationModels

// MARK: - Blueprint Types (PRIZMATE Output)
// These are the structured outputs from PRIZMATE compiler
// They map 1:1 to PrismDefinition

@Generable
struct PrismBlueprintV1: Sendable {
    @Guide(description: "Short name (2-4 words)")
    var name: String

    @Guide(description: """
        Reusable session instructions for running the Prism.
        Keep concise. Do NOT include the user's specific example input.
        """)
    var instructions: String

    @Guide(description: "Example input the user might paste/type")
    var exampleInput: String?

    @Guide(description: "Short title for the input (1-2 words, e.g. 'Meeting Notes', 'Ingredients')")
    var incidentTitle: String

    @Guide(description: "What the user will paste/type. One sentence.")
    var incidentDescription: String

    @Guide(description: """
        Output sections shown on screen, in order.
        Each section has fields.
        """)
    var sections: [SectionBlueprint]

    @Guide(description: "Start at 1")
    var version: Int
}

@Generable
struct SectionBlueprint: Sendable {
    @Guide(description: "Schema-safe id: letters/numbers/underscore only")
    var id: String

    @Guide(description: "Title shown in UI")
    var title: String

    @Guide(description: "1-4 fields. Keep minimal.")
    var fields: [FieldBlueprint]
}

@Generable
struct FieldBlueprint: Sendable {
    @Guide(description: "Schema-safe key: letters/numbers/underscore only")
    var key: String

    @Guide(description: """
        How to fill this field. Be strict, short, testable.
        Prefer MUST/MUST NOT. Include length limits if needed.
        """)
    var guide: String

    var valueType: BlueprintValueType
}

@Generable
enum BlueprintValueType: String, Sendable {
    case string
    case stringArray
}

// MARK: - Archetype Hint (Future-Ready)

enum PrismArchetype: String, Sendable, CaseIterable {
    case general       // Default for MVP
    case analyzer      // Break down input into parts
    case generator     // Create content from input
    case transformer   // Convert input format
    case extractor     // Pull specific info from input
}

// MARK: - Blueprint to PrismDefinition Mapping

extension PrismBlueprintV1 {
    func toPrismDefinition() throws -> PrismDefinition {
        let prism = PrismDefinition(
            id: UUID(),
            name: name,
            instructions: instructions,
            incidentBeam: IncidentBeamSpec(
                type: "string",
                title: incidentTitle,
                description: incidentDescription
            ),
            refractedBeams: sections.map { section in
                BeamSpec(
                    id: section.id,
                    title: section.title,
                    description: nil,
                    fields: section.fields.map { field in
                        BeamFieldSpec(
                            key: field.key,
                            guide: field.guide,
                            valueType: field.valueType == .string ? .string : .stringArray
                        )
                    }
                )
            },
            version: version,
            exampleInput: exampleInput
        )
        try PrismDefinitionValidator.validate(prism)
        return prism
    }
}

// MARK: - Validation

enum PrismDefinitionValidator {
    enum ValidationError: Error, LocalizedError {
        case invalidId(String)
        case duplicateKeys(String)
        case emptyName
        case emptySections

        var errorDescription: String? {
            switch self {
            case .invalidId(let id): return "Invalid ID: \(id)"
            case .duplicateKeys(let beam): return "Duplicate keys in beam: \(beam)"
            case .emptyName: return "Name cannot be empty"
            case .emptySections: return "Must have at least one section"
            }
        }
    }

    static func validate(_ prism: PrismDefinition) throws {
        // Name check
        guard !prism.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ValidationError.emptyName
        }

        // Sections check
        guard !prism.refractedBeams.isEmpty else {
            throw ValidationError.emptySections
        }

        // ID format check
        let idPattern = #"^[A-Za-z0-9_]+$"#
        for beam in prism.refractedBeams {
            guard beam.id.range(of: idPattern, options: .regularExpression) != nil else {
                throw ValidationError.invalidId(beam.id)
            }

            // Field keys check
            var seenKeys = Set<String>()
            for field in beam.fields {
                guard field.key.range(of: idPattern, options: .regularExpression) != nil else {
                    throw ValidationError.invalidId(field.key)
                }
                guard !seenKeys.contains(field.key) else {
                    throw ValidationError.duplicateKeys(beam.id)
                }
                seenKeys.insert(field.key)
            }
        }
    }
}
