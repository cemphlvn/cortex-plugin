import SwiftUI
import SwiftData

// MARK: - Creator View

struct CreatorView: View {
    @StateObject private var vm = CreatorViewModel()
    @EnvironmentObject private var repository: HybridPrismRepository
    @State private var showPrizmateSuccess = false
    @State private var createdPrism: PrismDefinition?
    @State private var archetypeSelected = false
    @State private var showHelp = false

    // Callback when prism is created (for navigation)
    var onPrismCreated: ((PrismDefinition) -> Void)?

    var body: some View {
        ZStack {
            if !archetypeSelected {
                // Step 1: Pick archetype
                ArchetypePickerView(
                    onSelect: { archetype in
                        vm.archetype = archetype
                        // Picker handles its own exit animation
                        withAnimation(.easeOut(duration: 0.25)) {
                            archetypeSelected = true
                        }
                    },
                    onHelp: { showHelp = true },
                    onNotSure: {
                        vm.archetype = .transformer
                        withAnimation(.easeOut(duration: 0.25)) {
                            archetypeSelected = true
                        }
                    }
                )
                .zIndex(1)
                .transition(.opacity)
            }

            if archetypeSelected {
                // Step 2: Chat flow
                chatFlow
                    .zIndex(2)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .offset(x: -50)).animation(.easeOut(duration: 0.3)),
                            removal: .opacity.combined(with: .offset(x: -50))
                        )
                    )
            }
        }
        .background(PrismTheme.background)
        .navigationTitle(archetypeSelected ? vm.archetype.actionVerb : "Creator")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if archetypeSelected {
                    Button("Reset") {
                        withAnimation(.smooth(duration: 0.35)) {
                            vm.reset()
                            archetypeSelected = false
                        }
                    }
                    .foregroundStyle(PrismTheme.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showHelp) {
            ArchetypeHelpSheet()
        }
        .alert("Prism Created!", isPresented: $showPrizmateSuccess) {
            Button("View Prism") {
                if let prism = createdPrism {
                    onPrismCreated?(prism)
                }
            }
            Button("Create Another") {
                withAnimation(.smooth(duration: 0.35)) {
                    vm.reset()
                    archetypeSelected = false
                }
            }
        } message: {
            if let prism = createdPrism {
                Text("\"\(prism.name)\" has been saved to your Prisms.")
            }
        }
    }

    // MARK: - Chat Flow

    private var chatFlow: some View {
        VStack(spacing: 0) {
            // Atelier Panel (appears after first message)
            if !vm.messages.isEmpty {
                AtelierPanel(
                    draft: vm.draft,
                    isBuilding: vm.isUpdatingDraft,
                    compileStatus: vm.compileStatus,
                    compileError: vm.compileError,
                    onPrizmate: prizmate
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Chat Panel
            ChatPanel(
                messages: vm.messages,
                input: $vm.input,
                onSend: { vm.sendUser(vm.input) }
            )
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: vm.messages.count)
    }

    private func prizmate() {
        // Two-step flow:
        // 1. No draft? → Compile from transcript
        // 2. Draft exists? → Save it
        if vm.draft == nil {
            vm.triggerPrizmate()
        } else {
            saveDraft()
        }
    }

    private func saveDraft() {
        Task {
            do {
                if let prism = try await vm.finalizeAndSave(repo: repository) {
                    await MainActor.run {
                        createdPrism = prism
                        showPrizmateSuccess = true
                        PrismHaptics.success()
                    }
                }
            } catch {
                print("Save failed: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview("Creator - Empty") {
    let container = try! ModelContainer(for: PrismRecord.self, configurations: .init(isStoredInMemoryOnly: true))
    let auth = SupabaseAuthService()

    return NavigationStack {
        CreatorView()
    }
    .modelContainer(container)
    .environmentObject(HybridPrismRepository(modelContainer: container, auth: auth))
}

#Preview("Creator - With Messages") {
    let container = try! ModelContainer(for: PrismRecord.self, configurations: .init(isStoredInMemoryOnly: true))
    let auth = SupabaseAuthService()

    return NavigationStack {
        CreatorViewPreview()
    }
    .modelContainer(container)
    .environmentObject(HybridPrismRepository(modelContainer: container, auth: auth))
}

private struct CreatorViewPreview: View {
    @StateObject private var vm = CreatorViewModel()

    var body: some View {
        CreatorView()
            .onAppear {
                // Simulate conversation
                vm.messages = [
                    CreatorMessage(role: .user, text: "I want to extract action items from meeting notes"),
                    CreatorMessage(role: .golden, text: "Can you show me an example of your meeting notes?"),
                    CreatorMessage(role: .user, text: "Team sync: Discussed Q1 roadmap. John to finalize budget by Friday. Sarah will reach out to vendors."),
                    CreatorMessage(role: .golden, text: "What should the output look like? Just a list of tasks, or include who's responsible?")
                ]
            }
    }
}
