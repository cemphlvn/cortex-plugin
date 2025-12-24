import Foundation
import FoundationModels

// MARK: - PRIZMATE Compiler
// Converts chat transcript into PrismBlueprintV1 using guided generation
// Uses archetype-specific instructions for optimized output structure

struct PrizmateCompiler: Sendable {
    let archetype: PrismArchetype

    init(archetype: PrismArchetype = .transformer) {
        self.archetype = archetype
    }

    /// Compile transcript into blueprint
    /// Uses guided generation with archetype-specific instructions
    func compileDraft(from transcript: String) async throws -> PrismBlueprintV1 {
        let session = LanguageModelSession(instructions: archetype.prizmateInstructions)
        let response = try await session.respond(
            to: transcript,
            generating: PrismBlueprintV1.self,
            includeSchemaInPrompt: true
        )
        return response.content
    }
}
