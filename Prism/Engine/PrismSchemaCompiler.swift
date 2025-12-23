import Foundation
import FoundationModels

/// Compiles PrismDefinition into PrismExecutable
/// This is the "data → code" bridge
enum PrismSchemaCompiler {

    /// Compile a PrismDefinition into an executable
    static func compile(_ prism: PrismDefinition) throws -> PrismExecutable {
        let schema = try buildSchema(prism)
        let decoder: @Sendable (GeneratedContent) throws -> [BeamOutput] = { content in
            try decode(content, prism: prism)
        }

        return PrismExecutable(
            prismId: prism.id,
            version: prism.version,
            instructions: prism.instructions,
            schema: schema,
            decoder: decoder
        )
    }

    // MARK: - Private

    private static func buildSchema(_ prism: PrismDefinition) throws -> GenerationSchema {
        let string = DynamicGenerationSchema(type: String.self)
        let stringArray = DynamicGenerationSchema(arrayOf: string, minimumElements: 0, maximumElements: 10)

        var dependencies: [DynamicGenerationSchema] = []
        var rootProps: [DynamicGenerationSchema.Property] = []

        for beam in prism.refractedBeams {
            var fieldProps: [DynamicGenerationSchema.Property] = []

            for field in beam.fields {
                let fieldSchema: DynamicGenerationSchema = (field.valueType == .string) ? string : stringArray
                fieldProps.append(
                    .init(
                        name: field.key,
                        description: field.guide,
                        schema: fieldSchema
                    )
                )
            }

            let beamSchemaName = "beam_\(beam.id)"
            let beamSchema = DynamicGenerationSchema(
                name: beamSchemaName,
                description: beam.description ?? beam.title,
                properties: fieldProps
            )

            dependencies.append(beamSchema)

            rootProps.append(
                .init(
                    name: beam.id,
                    description: beam.title,
                    schema: DynamicGenerationSchema(referenceTo: beamSchemaName)
                )
            )
        }

        let root = DynamicGenerationSchema(
            name: "PrismOutput",
            description: "Output for prism \(prism.name)",
            properties: rootProps
        )

        return try GenerationSchema(root: root, dependencies: dependencies)
    }

    private static func decode(_ content: GeneratedContent, prism: PrismDefinition) throws -> [BeamOutput] {
        var outputs: [BeamOutput] = []
        outputs.reserveCapacity(prism.refractedBeams.count)

        for beam in prism.refractedBeams {
            let beamContent = try content.value(GeneratedContent.self, forProperty: beam.id)

            var fields: [FieldOutput] = []
            fields.reserveCapacity(beam.fields.count)

            for f in beam.fields {
                let value: BeamValue
                switch f.valueType {
                case .string:
                    value = .string(try beamContent.value(String.self, forProperty: f.key))
                case .stringArray:
                    value = .stringArray(try beamContent.value([String].self, forProperty: f.key))
                }
                fields.append(FieldOutput(key: f.key, value: value))
            }

            outputs.append(BeamOutput(id: beam.id, fields: fields))
        }

        return outputs
    }
}
