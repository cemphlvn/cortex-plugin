import Foundation
import SwiftData

/// SwiftData model for persisting Prisms
/// Maps to/from PrismDefinition (the pure data type)
@Model
final class PrismRecord {
    /// Unique identifier (matches PrismDefinition.id)
    @Attribute(.unique)
    var prismId: UUID

    /// JSON-encoded PrismDefinition
    var definitionData: Data

    /// Version for cache invalidation
    var version: Int

    /// Creation timestamp
    var createdAt: Date

    /// Last modified timestamp
    var updatedAt: Date

    /// Is this a bundled (read-only) prism?
    var isBundled: Bool

    init(definition: PrismDefinition, isBundled: Bool = false) throws {
        self.prismId = definition.id
        self.definitionData = try JSONEncoder().encode(definition)
        self.version = definition.version
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isBundled = isBundled
    }

    /// Decode back to PrismDefinition
    func toDefinition() throws -> PrismDefinition {
        try JSONDecoder().decode(PrismDefinition.self, from: definitionData)
    }

    /// Update from a PrismDefinition
    func update(from definition: PrismDefinition) throws {
        self.definitionData = try JSONEncoder().encode(definition)
        self.version = definition.version
        self.updatedAt = Date()
    }
}
