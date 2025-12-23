import Foundation
import SwiftData

/// Repository protocol for Prism storage
/// Abstracts storage backend (SwiftData now, Supabase later)
protocol PrismRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [PrismDefinition]
    func fetch(id: UUID) async throws -> PrismDefinition?
    func save(_ definition: PrismDefinition) async throws
    func delete(id: UUID) async throws
    func seedBundledPrisms() async throws
}

/// SwiftData implementation of PrismRepository
@ModelActor
actor PrismRepository: PrismRepositoryProtocol {

    /// Fetch all prisms
    func fetchAll() throws -> [PrismDefinition] {
        let descriptor = FetchDescriptor<PrismRecord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let records = try modelContext.fetch(descriptor)
        return try records.compactMap { try $0.toDefinition() }
    }

    /// Fetch a single prism by ID
    func fetch(id: UUID) throws -> PrismDefinition? {
        let descriptor = FetchDescriptor<PrismRecord>(
            predicate: #Predicate { $0.prismId == id }
        )
        guard let record = try modelContext.fetch(descriptor).first else {
            return nil
        }
        return try record.toDefinition()
    }

    /// Save a prism (insert or update)
    func save(_ definition: PrismDefinition) throws {
        let descriptor = FetchDescriptor<PrismRecord>(
            predicate: #Predicate { $0.prismId == definition.id }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            try existing.update(from: definition)
        } else {
            let record = try PrismRecord(definition: definition)
            modelContext.insert(record)
        }

        try modelContext.save()
    }

    /// Delete a prism
    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<PrismRecord>(
            predicate: #Predicate { $0.prismId == id }
        )

        if let record = try modelContext.fetch(descriptor).first {
            modelContext.delete(record)
            try modelContext.save()
        }
    }

    /// Seed bundled prisms (only if not already present)
    func seedBundledPrisms() throws {
        let bundled = PrismLoader.loadBundledPrisms()

        for prism in bundled {
            let descriptor = FetchDescriptor<PrismRecord>(
                predicate: #Predicate { $0.prismId == prism.id }
            )

            if try modelContext.fetch(descriptor).isEmpty {
                let record = try PrismRecord(definition: prism, isBundled: true)
                modelContext.insert(record)
            }
        }

        try modelContext.save()
    }

    /// Check if bundled prisms need seeding
    func needsSeeding() throws -> Bool {
        let descriptor = FetchDescriptor<PrismRecord>()
        return try modelContext.fetch(descriptor).isEmpty
    }
}

// MARK: - Mock Repository for Previews/Testing

actor MockPrismRepository: PrismRepositoryProtocol {
    private var storage: [UUID: PrismDefinition] = [:]

    func fetchAll() async throws -> [PrismDefinition] {
        Array(storage.values).sorted { $0.name < $1.name }
    }

    func fetch(id: UUID) async throws -> PrismDefinition? {
        storage[id]
    }

    func save(_ definition: PrismDefinition) async throws {
        storage[definition.id] = definition
    }

    func delete(id: UUID) async throws {
        storage.removeValue(forKey: id)
    }

    func seedBundledPrisms() async throws {
        for prism in PrismLoader.loadBundledPrisms() {
            storage[prism.id] = prism
        }
    }
}
