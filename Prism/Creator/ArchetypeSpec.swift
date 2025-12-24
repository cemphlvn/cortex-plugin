import Foundation
import SwiftUI

// MARK: - Archetype Definition
// Each archetype has a distinct blueprint pattern optimized for its use case
// All archetypes compile to PrismDefinition → same engine

enum PrismArchetype: String, CaseIterable, Identifiable, Sendable {
    case analyzer
    case generator
    case transformer
    case extractor

    var id: String { rawValue }
}

// MARK: - Archetype Metadata

extension PrismArchetype {
    /// User-facing action verb
    var actionVerb: String {
        switch self {
        case .analyzer: return "Judge It"
        case .generator: return "Make It"
        case .transformer: return "Sort It"
        case .extractor: return "Find It"
        }
    }

    /// Technical name (for internal use)
    var displayName: String {
        switch self {
        case .analyzer: return "Analyzer"
        case .generator: return "Generator"
        case .transformer: return "Transformer"
        case .extractor: return "Extractor"
        }
    }

    var icon: String {
        switch self {
        case .analyzer: return "eye.circle"
        case .generator: return "sparkles"
        case .transformer: return "arrow.triangle.swap"
        case .extractor: return "magnifyingglass.circle"
        }
    }

    /// The question user is asking
    var userQuestion: String {
        switch self {
        case .analyzer: return "What do I think of this?"
        case .generator: return "What should I create?"
        case .transformer: return "How do I organize this?"
        case .extractor: return "What's hidden in here?"
        }
    }

    /// One-line description
    var tagline: String {
        switch self {
        case .analyzer: return "Get a verdict with reasoning"
        case .generator: return "Create new content from a seed"
        case .transformer: return "Turn chaos into structure"
        case .extractor: return "Pull specific info from content"
        }
    }

    /// Detailed description (internal)
    var description: String {
        switch self {
        case .analyzer:
            return "Takes input, analyzes it across dimensions, produces verdict with reasoning"
        case .generator:
            return "Takes seed input, creates new content with optional variants"
        case .transformer:
            return "Takes unstructured input, outputs organized structured format"
        case .extractor:
            return "Finds and pulls specific information from larger input"
        }
    }

    /// Example use cases
    var examples: [String] {
        switch self {
        case .analyzer: return ["Review analysis", "Code quality", "Resume screen"]
        case .generator: return ["Captions", "Emails", "Slogans"]
        case .transformer: return ["Meeting notes", "Recipe steps", "Log parsing"]
        case .extractor: return ["Dates", "Contacts", "Key facts"]
        }
    }

    /// Transformation hint (input → output)
    var transformationHint: String {
        switch self {
        case .analyzer: return "content → verdict"
        case .generator: return "idea → creation"
        case .transformer: return "chaos → structure"
        case .extractor: return "content → details"
        }
    }

    /// Single concrete example
    var concreteExample: String {
        switch self {
        case .analyzer: return "e.g., \"Is this email professional?\""
        case .generator: return "e.g., \"Write a caption for this photo\""
        case .transformer: return "e.g., \"Turn notes into action items\""
        case .extractor: return "e.g., \"Find all dates in this text\""
        }
    }

    /// Accent color for visual coding
    var accentColor: Color {
        switch self {
        case .analyzer: return Color(red: 0, green: 0.85, blue: 1)      // Cyan
        case .generator: return Color(red: 1, green: 0, blue: 0.84)     // Magenta
        case .transformer: return Color(red: 1, green: 0.72, blue: 0)   // Amber
        case .extractor: return Color(red: 0, green: 1, blue: 0.62)     // Emerald
        }
    }
}

// MARK: - Blueprint Patterns
// These define the IDEAL output structure per archetype

extension PrismArchetype {
    /// The mental model for this archetype
    var mentalModel: String {
        switch self {
        case .analyzer: return "Understand → Assess → Conclude"
        case .generator: return "Seed → Expand → Craft"
        case .transformer: return "Parse → Organize → Structure"
        case .extractor: return "Search → Filter → Extract"
        }
    }

    /// Blueprint guidance for PRIZMATE
    var blueprintSpec: ArchetypeBlueprintSpec {
        switch self {
        case .analyzer: return .analyzer
        case .generator: return .generator
        case .transformer: return .transformer
        case .extractor: return .extractor
        }
    }
}

// MARK: - Archetype Blueprint Specifications

struct ArchetypeBlueprintSpec: Sendable {
    let sectionPatterns: [SectionPattern]
    let fieldGuidance: String
    let prizmateHints: String

    struct SectionPattern: Sendable {
        let suggestedId: String
        let purpose: String
        let typicalFields: [FieldPattern]
        let required: Bool
    }

    struct FieldPattern: Sendable {
        let suggestedKey: String
        let valueType: BlueprintValueType
        let guidance: String
    }
}

extension ArchetypeBlueprintSpec {

    // MARK: - ANALYZER
    // Input → Verdict + Breakdown + Evidence

    static let analyzer = ArchetypeBlueprintSpec(
        sectionPatterns: [
            SectionPattern(
                suggestedId: "assessment",
                purpose: "Overall verdict and confidence",
                typicalFields: [
                    FieldPattern(suggestedKey: "verdict", valueType: .string,
                                guidance: "Clear assessment: Positive/Neutral/Negative or domain-specific rating"),
                    FieldPattern(suggestedKey: "confidence", valueType: .string,
                                guidance: "Confidence level: High/Medium/Low")
                ],
                required: true
            ),
            SectionPattern(
                suggestedId: "breakdown",
                purpose: "Analysis across dimensions",
                typicalFields: [
                    FieldPattern(suggestedKey: "strengths", valueType: .stringArray,
                                guidance: "Positive aspects identified. Max 4."),
                    FieldPattern(suggestedKey: "weaknesses", valueType: .stringArray,
                                guidance: "Negative aspects identified. Max 4.")
                ],
                required: true
            ),
            SectionPattern(
                suggestedId: "summary",
                purpose: "Concise takeaway",
                typicalFields: [
                    FieldPattern(suggestedKey: "one_liner", valueType: .string,
                                guidance: "One sentence summary of the analysis.")
                ],
                required: false
            )
        ],
        fieldGuidance: """
            Analyzer outputs should be evaluative. Use clear verdict language.
            Breakdowns should cover multiple dimensions of the input.
            Evidence should be traceable to input content.
            """,
        prizmateHints: """
            Structure: assessment section (verdict + confidence), breakdown section (strengths/weaknesses or domain aspects), optional summary.
            The first section MUST contain a clear verdict field.
            Use stringArray for lists of aspects/points.
            """
    )

    // MARK: - GENERATOR
    // Seed → Primary Content + Variants

    static let generator = ArchetypeBlueprintSpec(
        sectionPatterns: [
            SectionPattern(
                suggestedId: "creation",
                purpose: "The primary generated content",
                typicalFields: [
                    FieldPattern(suggestedKey: "content", valueType: .string,
                                guidance: "The main generated output. Creative and polished.")
                ],
                required: true
            ),
            SectionPattern(
                suggestedId: "variants",
                purpose: "Alternative versions",
                typicalFields: [
                    FieldPattern(suggestedKey: "alternatives", valueType: .stringArray,
                                guidance: "2-3 alternative versions with different tones/angles.")
                ],
                required: false
            ),
            SectionPattern(
                suggestedId: "metadata",
                purpose: "Style/tone information",
                typicalFields: [
                    FieldPattern(suggestedKey: "tone", valueType: .string,
                                guidance: "The tone used: casual/formal/playful/etc."),
                    FieldPattern(suggestedKey: "tags", valueType: .stringArray,
                                guidance: "Relevant tags or hashtags.")
                ],
                required: false
            )
        ],
        fieldGuidance: """
            Generator outputs should be creative and ready-to-use.
            Primary content is the hero - make it shine.
            Variants offer different angles, not just rewording.
            """,
        prizmateHints: """
            Structure: creation section (primary content), optional variants section, optional metadata.
            The first section MUST contain the main generated content.
            Keep primary content polished and ready to copy/use directly.
            Variants should offer meaningfully different approaches.
            """
    )

    // MARK: - TRANSFORMER
    // Chaos → Structured Sections

    static let transformer = ArchetypeBlueprintSpec(
        sectionPatterns: [
            SectionPattern(
                suggestedId: "overview",
                purpose: "High-level structure",
                typicalFields: [
                    FieldPattern(suggestedKey: "title", valueType: .string,
                                guidance: "Brief title for the structured output."),
                    FieldPattern(suggestedKey: "summary", valueType: .string,
                                guidance: "One paragraph overview.")
                ],
                required: true
            ),
            SectionPattern(
                suggestedId: "structured",
                purpose: "Domain-specific structured fields",
                typicalFields: [
                    FieldPattern(suggestedKey: "items", valueType: .stringArray,
                                guidance: "Key items extracted and organized."),
                    FieldPattern(suggestedKey: "categories", valueType: .stringArray,
                                guidance: "Grouped categories if applicable.")
                ],
                required: true
            ),
            SectionPattern(
                suggestedId: "actions",
                purpose: "Actionable items if applicable",
                typicalFields: [
                    FieldPattern(suggestedKey: "next_steps", valueType: .stringArray,
                                guidance: "Action items or next steps. Max 5.")
                ],
                required: false
            )
        ],
        fieldGuidance: """
            Transformer outputs impose order on chaos.
            Structure should match the domain (meeting→actions, recipe→steps).
            Use arrays for lists, strings for summaries.
            """,
        prizmateHints: """
            Structure: overview section (title + summary), one or more structured sections with domain fields.
            The output structure should feel like a natural organization of the messy input.
            Use stringArray for lists of items (tasks, steps, points).
            Section names should reflect the domain (e.g., "action_items" for meetings).
            """
    )

    // MARK: - EXTRACTOR
    // Haystack → Needles + Context

    static let extractor = ArchetypeBlueprintSpec(
        sectionPatterns: [
            SectionPattern(
                suggestedId: "extracted",
                purpose: "The found items",
                typicalFields: [
                    FieldPattern(suggestedKey: "items", valueType: .stringArray,
                                guidance: "The extracted items/entities/values.")
                ],
                required: true
            ),
            SectionPattern(
                suggestedId: "context",
                purpose: "Source and confidence info",
                typicalFields: [
                    FieldPattern(suggestedKey: "source_hints", valueType: .stringArray,
                                guidance: "Where each item was found, if relevant."),
                    FieldPattern(suggestedKey: "completeness", valueType: .string,
                                guidance: "Complete/Partial/Uncertain - did we find everything?")
                ],
                required: false
            )
        ],
        fieldGuidance: """
            Extractor outputs are focused and precise.
            Primary output is the extracted items - this is the value.
            Context helps user understand source and confidence.
            """,
        prizmateHints: """
            Structure: extracted section (items array), optional context section.
            The first section MUST contain the extracted items as stringArray.
            Keep extraction focused on what user asked for - no extras.
            If confidence/completeness matters, add context section.
            """
    )
}

// MARK: - PRIZMATE Instructions Generator

extension PrismArchetype {
    /// Full PRIZMATE instructions for this archetype
    var prizmateInstructions: String {
        let spec = blueprintSpec

        return """
            You are an agent that converts conversations into Prisms. Prism can be anything that helps user automate a micro-task. Prisms do that by having a clear and dynamic input type and structured output beams. Each beam is basically an output structure. Prism encapsulates this.

            We prewarmed the user to articulate what kind of a Prism they want and what might they use it for, what input variables they could have, and what are the output structures would be desirable to them.

            You are given that conversation transcript with the user. Create the Prism that would solve their issues and can become a repetitive artifact they can use again and again.

            ---

            This is a \(displayName.uppercased()) Prism.
            Mental model: \(mentalModel)

            \(spec.prizmateHints)

            \(spec.fieldGuidance)
            """
    }
}
