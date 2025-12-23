import Foundation
import FoundationModels

/// Runs a compiled PrismExecutable with user input
struct PrismEngine: Sendable {

    /// Run a Prism with the given input
    /// - Parameters:
    ///   - executable: Compiled Prism
    ///   - input: User's incident input
    /// - Returns: Ordered beam outputs
    func run(executable: PrismExecutable, input: String) async throws -> [BeamOutput] {
        let session = LanguageModelSession(instructions: executable.instructions)

        let response = try await session.respond(
            to: input,
            schema: executable.schema
        )

        return try executable.decoder(response.content)
    }
}
