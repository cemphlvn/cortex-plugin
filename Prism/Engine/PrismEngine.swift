import Foundation
import FoundationModels

/// Runs a compiled PrismExecutable with user input
/// This is where C(I) = O happens
@available(iOS 26.0, *)
struct PrismEngine: Sendable {

    /// Run a Prism with the given input
    /// - Parameters:
    ///   - executable: Compiled Prism (contains instructions + schema + decoder)
    ///   - input: User's incident input (I)
    /// - Returns: Ordered beam outputs (O)
    func run(executable: PrismExecutable, input: String) async throws -> [BeamOutput] {
        // Create session with instructions (part of C)
        let session = LanguageModelSession(instructions: executable.instructions)

        // Guided generation: respond with schema constraint
        // Schema is the other part of C
        let response = try await session.respond(
            to: input,
            schema: executable.schema,
            includeSchemaInPrompt: true  // Bias model toward schema compliance
        )

        // Decode GeneratedContent → [BeamOutput] using the compiled decoder
        return try executable.decoder(response.content)
    }

    /// Run with streaming (for future UI enhancement)
    func streamRun(
        executable: PrismExecutable,
        input: String
    ) -> LanguageModelSession.ResponseStream<GeneratedContent> {
        let session = LanguageModelSession(instructions: executable.instructions)

        return session.streamResponse(
            to: input,
            schema: executable.schema,
            includeSchemaInPrompt: true
        )
    }
}

// MARK: - Errors

@available(iOS 26.0, *)
extension PrismEngine {
    enum RunError: Error, LocalizedError {
        case modelUnavailable(String)
        case generationFailed(String)

        var errorDescription: String? {
            switch self {
            case .modelUnavailable(let reason):
                return "Model unavailable: \(reason)"
            case .generationFailed(let reason):
                return "Generation failed: \(reason)"
            }
        }
    }
}
