import Foundation
import FoundationModels

// MARK: - GoldenPrism Agent
// Conversational AI that helps users articulate their Prism
// DOES NOT produce PrismDefinition - that's PRIZMATE's job

@available(iOS 26.0, *)
struct GoldenPrismAgent: Sendable {
    private let session: LanguageModelSession

    init() {
        self.session = LanguageModelSession(instructions: Self.instructions)
    }

    static let instructions = """
        In your first message, ALWAYS START with "Let's co-create your Prism!".
        Your goal is to slowly make these clear: what is the dynamic input and what is the output format. Each Prism is a input-output shape and it converts inputs to a structured outputs called "Beams". In most cases it automatizes a repetitive micro-task.
        Your job is to ask questions that converge the conversation to the the Prism user has at mind. You can explore the following dimensions: what their problem is, desired inputs and outputs, context, constraints, edge cases, etc. Communicate these in a context-aligned user-friendly way.
        You can sacrifice grammar for concision. Keep responses 5-15 words long. In your responses remain context-expanding and open-ended. Make it easy for the user to provide more information.

        Keep the language from user's perspective:
        - Use
        """

    /// Reply to user message with error handling
    /// - Parameter userText: User's input message
    /// - Returns: Agent's response
    /// - Throws: PrismError with user-friendly messages
    func reply(to userText: String) async throws -> String {
        // Check availability first
        let model = SystemLanguageModel.default
        if let error = PrismError.from(availability: model.availability) {
            throw error
        }

        do {
            let response = try await session.respond(to: userText)
            return response.content
        } catch let error as LanguageModelSession.GenerationError {
            throw mapGenerationError(error)
        } catch {
            throw PrismError.from(error)
        }
    }

    private func mapGenerationError(_ error: LanguageModelSession.GenerationError) -> PrismError {
        switch error {
        case .refusal:
            return .refusal(explanation: nil)
        case .guardrailViolation:
            return .guardrailViolation
        case .concurrentRequests:
            return .concurrentRequests
        case .assetsUnavailable:
            return .assetsUnavailable
        case .unsupportedLanguageOrLocale:
            return .unsupportedLanguage(nil)
        case .decodingFailure(let ctx):
            return .decodingFailure(ctx.debugDescription)
        case .exceededContextWindowSize:
            return .contextOverflow
        case .unsupportedGuide(let ctx):
            return .unsupportedGuide(ctx.debugDescription)
        case .rateLimited:
            return .rateLimited
        @unknown default:
            return .serviceUnavailable(code: nil)
        }
    }
}
