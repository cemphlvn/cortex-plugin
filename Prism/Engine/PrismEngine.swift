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
    /// - Throws: PrismError with detailed, user-actionable messages
    func run(executable: PrismExecutable, input: String) async throws -> [BeamOutput] {
        // Check model availability first
        let model = SystemLanguageModel.default
        if let availabilityError = PrismError.from(availability: model.availability) {
            throw availabilityError
        }

        // Create session with instructions (part of C)
        let session = LanguageModelSession(instructions: executable.instructions)

        do {
            // Guided generation: respond with schema constraint
            // Schema is the other part of C
            let response = try await session.respond(
                to: input,
                schema: executable.schema,
                includeSchemaInPrompt: true  // Bias model toward schema compliance
            )

            // Decode GeneratedContent → [BeamOutput] using the compiled decoder
            return try executable.decoder(response.content)

        } catch let error as LanguageModelSession.GenerationError {
            // Handle specific generation errors
            throw handleGenerationError(error)
        } catch let error as PrismError {
            throw error
        } catch {
            throw PrismError.from(error)
        }
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

    // MARK: - Error Handling

    private func handleGenerationError(_ error: LanguageModelSession.GenerationError) -> PrismError {
        switch error {
        case .refusal:
            return .refusal(explanation: nil)
        case .guardrailViolation:
            return .guardrailViolation
        case .decodingFailure(let context):
            return .decodingFailure(context.debugDescription)
        case .assetsUnavailable:
            return .assetsUnavailable
        case .unsupportedLanguageOrLocale(let context):
            return .unsupportedLanguage(context.debugDescription)
        case .concurrentRequests:
            return .concurrentRequests
        case .exceededContextWindowSize:
            return .contextOverflow
        case .unsupportedGuide(let context):
            return .unsupportedGuide(context.debugDescription)
        case .rateLimited:
            return .rateLimited
        @unknown default:
            return .serviceUnavailable(code: nil)
        }
    }
}

// MARK: - Legacy Errors (deprecated)

@available(iOS 26.0, *)
extension PrismEngine {
    @available(*, deprecated, renamed: "PrismError")
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
