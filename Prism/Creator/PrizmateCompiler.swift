import Foundation
import FoundationModels

// MARK: - PRIZMATE Compiler
// Converts chat transcript into PrismBlueprintV1 using guided generation

struct PrizmateCompiler: Sendable {
    private let session: LanguageModelSession

    init() {
        self.session = LanguageModelSession(instructions: Self.instructions)
    }

    static let instructions = """
        You are an agent that converts conversations into Prisms. Prism can be anything that helps user automate a micro-task. Prisms do that by having a clear and dynamic input type and structured output beams. Each beam is basically an output structure. Prism encapsulates this.
        We prewarmed the user to articulate what kind of a Prism they want and what might they use it for, what input variables they could have, and what are the output structures would be desirable to them.
        You are given that conversation transcript with the user. Create the Prism that would solve their issues and can become a repetitive artifact they can use again and again.
        """

    /// Compile transcript into blueprint
    /// Uses guided generation for reliable structure
    func compileDraft(from transcript: String) async throws -> PrismBlueprintV1 {
        let response = try await session.respond(
            to: transcript,
            generating: PrismBlueprintV1.self,
            includeSchemaInPrompt: true
        )
        return response.content
    }
}
