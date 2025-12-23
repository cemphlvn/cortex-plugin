import Foundation
import FoundationModels

/// Runtime representation of a compiled Prism
/// Created from PrismDefinition, contains schema + decoder
struct PrismExecutable: Sendable {
    /// Original Prism ID
    let prismId: UUID
    /// Version at compile time
    let version: Int
    /// Instructions for the model
    let instructions: String
    /// Compiled generation schema
    let schema: GenerationSchema
    /// Decoder to extract BeamOutputs from GeneratedContent
    let decoder: @Sendable (GeneratedContent) throws -> [BeamOutput]
}
