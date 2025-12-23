import Foundation
import FoundationModels

/// Compiles PrismDefinition into PrismExecutable
/// This is the "data → code" bridge
@available(iOS 26.0, *)
enum PrismSchemaCompiler {

    /// Compile a PrismDefinition into an executable
    static func compile(_ prism: PrismDefinition) throws -> PrismExecutable {
        let schema = try buildSchema(prism)

        // Capture prism for decoder closure
        let capturedPrism = prism
        let decoder: @Sendable (GeneratedContent) throws -> [BeamOutput] = { content in
            try decode(content, prism: capturedPrism)
        }

        return PrismExecutable(
            prismId: prism.id,
            version: prism.version,
            instructions: prism.instructions,
            schema: schema,
            decoder: decoder
        )
    }

    // MARK: - Schema Building

    private static func buildSchema(_ prism: PrismDefinition) throws -> GenerationSchema {
        // Base type schemas
        let stringSchema = DynamicGenerationSchema(type: String.self)
        let stringArraySchema = DynamicGenerationSchema(
            arrayOf: stringSchema,
            minimumElements: 0,
            maximumElements: 10
        )

        var dependencies: [DynamicGenerationSchema] = []
        var rootProperties: [DynamicGenerationSchema.Property] = []

        // Build schema for each beam
        for beam in prism.refractedBeams {
            var fieldProperties: [DynamicGenerationSchema.Property] = []

            for field in beam.fields {
                let fieldSchema: DynamicGenerationSchema
                switch field.valueType {
                case .string:
                    fieldSchema = stringSchema
                case .stringArray:
                    fieldSchema = stringArraySchema
                }

                fieldProperties.append(
                    DynamicGenerationSchema.Property(
                        name: field.key,
                        description: field.guide,
                        schema: fieldSchema
                    )
                )
            }

            // Create beam object schema
            let beamSchemaName = "beam_\(beam.id)"
            let beamSchema = DynamicGenerationSchema(
                name: beamSchemaName,
                description: beam.description ?? beam.title,
                properties: fieldProperties
            )
            dependencies.append(beamSchema)

            // Add reference to root
            rootProperties.append(
                DynamicGenerationSchema.Property(
                    name: beam.id,
                    description: beam.title,
                    schema: DynamicGenerationSchema(referenceTo: beamSchemaName)
                )
            )
        }

        // Create root schema
        let rootSchema = DynamicGenerationSchema(
            name: "PrismOutput",
            description: "Output for prism: \(prism.name)",
            properties: rootProperties
        )

        // Build validated GenerationSchema
        return try GenerationSchema(root: rootSchema, dependencies: dependencies)
    }

    // MARK: - Decoding

    private static func decode(_ content: GeneratedContent, prism: PrismDefinition) throws -> [BeamOutput] {
        var outputs: [BeamOutput] = []
        outputs.reserveCapacity(prism.refractedBeams.count)

        // Iterate in definition order (UI contract)
        for beam in prism.refractedBeams {
            // Get nested content for this beam
            let beamContent = try content.value(GeneratedContent.self, forProperty: beam.id)

            var fields: [FieldOutput] = []
            fields.reserveCapacity(beam.fields.count)

            for field in beam.fields {
                let value: BeamValue
                switch field.valueType {
                case .string:
                    let stringValue = try beamContent.value(String.self, forProperty: field.key)
                    value = .string(stringValue)

                case .stringArray:
                    let arrayValue = try beamContent.value([String].self, forProperty: field.key)
                    value = .stringArray(arrayValue)
                }
                fields.append(FieldOutput(key: field.key, value: value))
            }

            outputs.append(BeamOutput(id: beam.id, fields: fields))
        }

        return outputs
    }
}

// MARK: - Errors

@available(iOS 26.0, *)
extension PrismSchemaCompiler {
    enum CompileError: Error, LocalizedError {
        case invalidSchema(String)
        case decodingFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidSchema(let detail):
                return "Schema compilation failed: \(detail)"
            case .decodingFailed(let detail):
                return "Output decoding failed: \(detail)"
            }
        }
    }
}
