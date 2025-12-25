import Foundation
import SwiftData

/// Sync status for UI feedback
enum SyncStatus: Equatable {
    case idle
    case syncing
    case synced
    case pendingSync(count: Int)
    case error(String)
    case offline
}

// MARK: - HybridPrismRepository

/// Coordinates local-first persistence with optional cloud mirroring.
///
/// Guarantees:
/// - Does NOT block UI on network
/// - Does NOT perform merging (last-write-wins only)
/// - Treats SwiftData as source of truth
///
/// Behavior:
/// - All writes go to SwiftData immediately
/// - If authenticated, writes also go to Supabase (async, fire-and-forget)
/// - If offline or unauthenticated, prism IDs are queued for later sync
/// - Pending IDs are persisted across app launches
@MainActor
final class HybridPrismRepository: ObservableObject {

    // MARK: - Published State

    @Published private(set) var syncStatus: SyncStatus = .idle
    @Published private(set) var pendingSyncIds: Set<UUID> = [] {
        didSet { persistPendingIds() }
    }

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let auth: SupabaseAuthService
    private var cloudRepo: SupabasePrismRepository?

    // MARK: - Persistence Keys

    private static let pendingIdsKey = "HybridPrismRepository.pendingSyncIds"

    // MARK: - Init

    init(modelContainer: ModelContainer, auth: SupabaseAuthService) {
        self.modelContainer = modelContainer
        self.auth = auth

        // Load persisted pending IDs
        self.pendingSyncIds = Self.loadPendingIds()

        // Create cloud repo if already authenticated
        if auth.isAuthenticated {
            self.cloudRepo = SupabasePrismRepository()
        }

        updateSyncStatus()
    }

    // MARK: - Local Repository

    private func localRepo() -> PrismRepository {
        PrismRepository(modelContainer: modelContainer)
    }

    // MARK: - Fetch

    func fetchAll() async throws -> [PrismDefinition] {
        try await localRepo().fetchAll()
    }

    func fetch(id: UUID) async throws -> PrismDefinition? {
        try await localRepo().fetch(id: id)
    }

    // MARK: - Save

    func save(_ definition: PrismDefinition) async throws {
        // 1. Always save locally first (source of truth)
        try await localRepo().save(definition)

        // 2. If authenticated, sync to cloud (non-blocking)
        if auth.isAuthenticated {
            await syncToCloud(definition)
        } else {
            // Queue for later sync
            pendingSyncIds.insert(definition.id)
            updateSyncStatus()
        }
    }

    // MARK: - Delete

    func delete(id: UUID) async throws {
        // Delete locally (source of truth)
        try await localRepo().delete(id: id)

        // Delete from cloud if authenticated (non-blocking)
        if auth.isAuthenticated, let cloudRepo {
            Task {
                try? await cloudRepo.delete(id: id)
            }
        }

        // Remove from pending queue
        pendingSyncIds.remove(id)
        updateSyncStatus()
    }

    // MARK: - Seed Bundled

    func seedBundledPrisms() async throws {
        try await localRepo().seedBundledPrisms()
        // Bundled prisms are local-only, never sync
    }

    func needsSeeding() async throws -> Bool {
        try await localRepo().needsSeeding()
    }

    // MARK: - Cloud Sync

    private func syncToCloud(_ definition: PrismDefinition) async {
        guard let cloudRepo else { return }

        syncStatus = .syncing

        do {
            try await cloudRepo.save(definition)
            pendingSyncIds.remove(definition.id)
            syncStatus = .synced
            scheduleIdleReset()
        } catch {
            pendingSyncIds.insert(definition.id)
            syncStatus = .error(error.localizedDescription)
        }
    }

    /// Push all pending prisms to cloud
    func syncPendingPrisms() async {
        guard auth.isAuthenticated else { return }
        guard !pendingSyncIds.isEmpty else {
            syncStatus = .idle
            return
        }

        if cloudRepo == nil {
            cloudRepo = SupabasePrismRepository()
        }
        guard let cloudRepo else { return }

        syncStatus = .syncing

        let idsToSync = pendingSyncIds
        var failedIds: Set<UUID> = []

        for id in idsToSync {
            do {
                if let prism = try await localRepo().fetch(id: id) {
                    try await cloudRepo.save(prism)
                    pendingSyncIds.remove(id)
                }
            } catch {
                failedIds.insert(id)
            }
        }

        if failedIds.isEmpty && pendingSyncIds.isEmpty {
            syncStatus = .synced
            scheduleIdleReset()
        } else if !failedIds.isEmpty {
            syncStatus = .error("Failed to sync \(failedIds.count) prism(s)")
        } else {
            updateSyncStatus()
        }
    }

    /// Pull from cloud (user-initiated)
    func pullFromCloud() async throws {
        guard auth.isAuthenticated, let cloudRepo else { return }

        syncStatus = .syncing

        do {
            let cloudPrisms = try await cloudRepo.fetchAll()

            for cloudPrism in cloudPrisms {
                // Last-write-wins: cloud wins on pull (user chose to pull)
                try await localRepo().save(cloudPrism)
            }

            syncStatus = .synced
            scheduleIdleReset()
        } catch {
            syncStatus = .error(error.localizedDescription)
            throw error
        }
    }

    /// Push all local prisms to cloud (user-initiated)
    func pushAllToCloud() async throws {
        guard auth.isAuthenticated else { return }

        if cloudRepo == nil {
            cloudRepo = SupabasePrismRepository()
        }
        guard let cloudRepo else { return }

        syncStatus = .syncing

        do {
            let localPrisms = try await localRepo().fetchAll()

            for prism in localPrisms {
                try await cloudRepo.save(prism)
            }

            pendingSyncIds.removeAll()
            syncStatus = .synced
            scheduleIdleReset()
        } catch {
            syncStatus = .error(error.localizedDescription)
            throw error
        }
    }

    // MARK: - Auth State Changes

    func onAuthStateChanged() {
        if auth.isAuthenticated {
            cloudRepo = SupabasePrismRepository()
            Task {
                await syncPendingPrisms()
            }
        } else {
            cloudRepo = nil
            syncStatus = .idle
        }
    }

    // MARK: - Helpers

    private func updateSyncStatus() {
        if pendingSyncIds.isEmpty {
            syncStatus = .idle
        } else {
            syncStatus = .pendingSync(count: pendingSyncIds.count)
        }
    }

    private func scheduleIdleReset() {
        Task {
            try? await Task.sleep(for: .seconds(2))
            if case .synced = syncStatus {
                syncStatus = .idle
            }
        }
    }

    // MARK: - Pending IDs Persistence

    private func persistPendingIds() {
        let strings = pendingSyncIds.map { $0.uuidString }
        UserDefaults.standard.set(strings, forKey: Self.pendingIdsKey)
    }

    private static func loadPendingIds() -> Set<UUID> {
        guard let strings = UserDefaults.standard.stringArray(forKey: pendingIdsKey) else {
            return []
        }
        return Set(strings.compactMap { UUID(uuidString: $0) })
    }
}
