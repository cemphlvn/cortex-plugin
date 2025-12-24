import Foundation
import FoundationModels

// MARK: - GoldenPrism Agent
// Conversational AI that helps users articulate their Prism
// DOES NOT produce PrismDefinition - that's PRIZMATE's job

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

    func reply(to userText: String) async throws -> String {
        let response = try await session.respond(to: userText)
        return response.content
    }
}
