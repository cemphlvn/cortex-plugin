import Foundation
import Supabase

/// DTO for Supabase prisms table
struct PrismDTO: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let definition: PrismDefinition
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case definition
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Insert/update DTO (excludes server-generated fields)
struct PrismInsertDTO: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let definition: PrismDefinition

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case definition
    }
}

/// Supabase implementation of PrismRepository
@MainActor
final class SupabasePrismRepository: PrismRepositoryProtocol {

    private var client: SupabaseClient { supabase }
    private let table = "prisms"

    /// Get current user ID or throw
    private func currentUserId() throws -> UUID {
        guard let user = client.auth.currentUser else {
            throw SupabasePrismError.notAuthenticated
        }
        return user.id
    }

    // MARK: - PrismRepositoryProtocol

    func fetchAll() async throws -> [PrismDefinition] {
        let userId = try currentUserId()

        let response: [PrismDTO] = try await client
            .from(table)
            .select()
            .eq("user_id", value: userId)
            .order("updated_at", ascending: false)
            .execute()
            .value

        return response.map { $0.definition }
    }

    func fetch(id: UUID) async throws -> PrismDefinition? {
        let userId = try currentUserId()

        let response: [PrismDTO] = try await client
            .from(table)
            .select()
            .eq("id", value: id)
            .eq("user_id", value: userId)
            .execute()
            .value

        return response.first?.definition
    }

    func save(_ definition: PrismDefinition) async throws {
        let userId = try currentUserId()

        let dto = PrismInsertDTO(
            id: definition.id,
            userId: userId,
            definition: definition
        )

        try await client
            .from(table)
            .upsert(dto, onConflict: "id")
            .execute()
    }

    func delete(id: UUID) async throws {
        let userId = try currentUserId()

        try await client
            .from(table)
            .delete()
            .eq("id", value: id)
            .eq("user_id", value: userId)
            .execute()
    }

    func seedBundledPrisms() async throws {
        // Bundled prisms are local-only, no-op for Supabase
    }

    // MARK: - Sharing (by ID)

    /// Fetch any prism by ID (for sharing via link)
    func fetchShared(id: UUID) async throws -> PrismDefinition {
        // Note: This bypasses user_id check - relies on RLS for public access
        // For MVP, sharing = knowing the UUID
        let response: [PrismDTO] = try await client
            .from(table)
            .select()
            .eq("id", value: id)
            .execute()
            .value

        guard let dto = response.first else {
            throw SupabasePrismError.notFound
        }

        return dto.definition
    }

    /// Copy a prism to user's library
    func copyPrism(id: UUID) async throws -> PrismDefinition {
        let original = try await fetchShared(id: id)

        let copy = PrismDefinition(
            id: UUID(),
            name: original.name,
            instructions: original.instructions,
            incidentBeam: original.incidentBeam,
            refractedBeams: original.refractedBeams,
            version: original.version,
            exampleInput: original.exampleInput
        )

        try await save(copy)
        return copy
    }
}

// MARK: - Errors

enum SupabasePrismError: Error, LocalizedError {
    case notAuthenticated
    case notFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not signed in"
        case .notFound:
            return "Prism not found"
        }
    }
}
