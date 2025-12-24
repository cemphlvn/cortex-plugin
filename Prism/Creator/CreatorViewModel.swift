import Foundation
import SwiftUI

// MARK: - Creator Message

struct CreatorMessage: Identifiable, Sendable, Equatable {
    enum Role: String, Sendable {
        case user
        case golden
    }

    let id: UUID
    let role: Role
    let text: String
    let timestamp: Date

    init(id: UUID = UUID(), role: Role, text: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
    }
}

// MARK: - Transcript Builder

func makeTranscript(_ messages: [CreatorMessage]) -> String {
    messages.map { "\($0.role.rawValue.uppercased()): \($0.text)" }
        .joined(separator: "\n")
}

// MARK: - Draft Diff (for highlighting changes)

struct DraftDiff: Equatable {
    var nameChanged: Bool = false
    var incidentChanged: Bool = false
    var sectionsAdded: Set<String> = []
    var sectionsRemoved: Set<String> = []
    var fieldsChanged: Set<String> = []  // "sectionId.fieldKey"

    var hasChanges: Bool {
        nameChanged || incidentChanged || !sectionsAdded.isEmpty ||
        !sectionsRemoved.isEmpty || !fieldsChanged.isEmpty
    }

    static func compute(old: PrismDefinition?, new: PrismDefinition?) -> DraftDiff {
        guard let new = new else { return DraftDiff() }
        guard let old = old else {
            // Everything is new
            return DraftDiff(
                nameChanged: true,
                incidentChanged: true,
                sectionsAdded: Set(new.refractedBeams.map(\.id))
            )
        }

        var diff = DraftDiff()

        // Name
        diff.nameChanged = old.name != new.name

        // Incident
        diff.incidentChanged = old.incidentBeam.description != new.incidentBeam.description

        // Sections
        let oldSectionIds = Set(old.refractedBeams.map(\.id))
        let newSectionIds = Set(new.refractedBeams.map(\.id))
        diff.sectionsAdded = newSectionIds.subtracting(oldSectionIds)
        diff.sectionsRemoved = oldSectionIds.subtracting(newSectionIds)

        // Fields in common sections
        let oldSections = Dictionary(uniqueKeysWithValues: old.refractedBeams.map { ($0.id, $0) })
        let newSections = Dictionary(uniqueKeysWithValues: new.refractedBeams.map { ($0.id, $0) })

        for sectionId in oldSectionIds.intersection(newSectionIds) {
            guard let oldSection = oldSections[sectionId],
                  let newSection = newSections[sectionId] else { continue }

            let oldFields = Dictionary(uniqueKeysWithValues: oldSection.fields.map { ($0.key, $0) })
            let newFields = Dictionary(uniqueKeysWithValues: newSection.fields.map { ($0.key, $0) })

            for (key, newField) in newFields {
                if let oldField = oldFields[key] {
                    if oldField.guide != newField.guide || oldField.valueType != newField.valueType {
                        diff.fieldsChanged.insert("\(sectionId).\(key)")
                    }
                } else {
                    diff.fieldsChanged.insert("\(sectionId).\(key)")
                }
            }
        }

        return diff
    }
}

// MARK: - Creator View Model

@MainActor
final class CreatorViewModel: ObservableObject {
    // MARK: - Published State

    @Published var messages: [CreatorMessage] = []
    @Published var input: String = ""
    @Published var draft: PrismDefinition? = nil
    @Published var lastGoodDraft: PrismDefinition? = nil
    @Published var isUpdatingDraft: Bool = false
    @Published var draftDiff: DraftDiff = DraftDiff()
    @Published var compileStatus: CompileStatus = .idle

    // Archetype hint (future-ready, not exposed in UI for MVP)
    var archetype: PrismArchetype = .general

    enum CompileStatus: Equatable {
        case idle
        case compiling
        case refining  // Error occurred, keeping last good draft
        case ready
    }

    // MARK: - Private

    private let golden = GoldenPrismAgent()
    private let prizmate = PrizmateCompiler()
    private var compileTask: Task<Void, Never>?

    // Debounce duration
    private let debounceNanos: UInt64 = 200_000_000 // 200ms

    // MARK: - User Actions

    func sendUser(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        input = ""
        messages.append(CreatorMessage(role: .user, text: trimmed))

        // Get GoldenPrism response (no auto-compile)
        Task {
            do {
                let reply = try await golden.reply(to: trimmed)
                await MainActor.run {
                    self.messages.append(CreatorMessage(role: .golden, text: reply))
                }
            } catch {
                await MainActor.run {
                    self.messages.append(CreatorMessage(
                        role: .golden,
                        text: "Could you rephrase that? I want to understand exactly what you need."
                    ))
                }
            }
        }
    }

    func clearDiff() {
        draftDiff = DraftDiff()
    }

    // MARK: - On-Demand PRIZMATE Compile

    func triggerPrizmate() {
        guard !messages.isEmpty else { return }

        compileTask?.cancel()
        compileTask = Task { [weak self] in
            guard let self = self else { return }

            await MainActor.run {
                self.isUpdatingDraft = true
                self.compileStatus = .compiling
            }

            let currentMessages = await MainActor.run { self.messages }
            let transcript = makeTranscript(currentMessages)

            do {
                let blueprint = try await self.prizmate.compileDraft(from: transcript)

                if Task.isCancelled { return }

                let newDraft = try blueprint.toPrismDefinition()

                await MainActor.run {
                    let oldDraft = self.draft
                    self.draftDiff = DraftDiff.compute(old: oldDraft, new: newDraft)
                    self.draft = newDraft
                    self.lastGoodDraft = newDraft
                    self.isUpdatingDraft = false
                    self.compileStatus = .ready
                }
            } catch {
                if Task.isCancelled { return }

                await MainActor.run {
                    self.isUpdatingDraft = false
                    self.compileStatus = .refining
                    self.compileError = error.localizedDescription
                }
            }
        }
    }

    @Published var compileError: String? = nil

    // MARK: - Finalize (PRIZMATE)

    func finalizeAndSave(repo: PrismRepositoryProtocol) async throws -> PrismDefinition? {
        guard let draft = draft else { return nil }

        // Final validation
        try PrismDefinitionValidator.validate(draft)

        // Save to repository
        try await repo.save(draft)

        return draft
    }

    // MARK: - Reset

    func reset() {
        compileTask?.cancel()
        messages = []
        input = ""
        draft = nil
        lastGoodDraft = nil
        isUpdatingDraft = false
        draftDiff = DraftDiff()
        compileStatus = .idle
    }
}
