import SwiftUI
import SwiftData

// MARK: - Creator View

struct CreatorView: View {
    @StateObject private var vm = CreatorViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showPrizmateSuccess = false
    @State private var createdPrism: PrismDefinition?

    // Callback when prism is created (for navigation)
    var onPrismCreated: ((PrismDefinition) -> Void)?

    var body: some View {
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
        .background(PrismTheme.background)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: vm.messages.count)
        .navigationTitle("Creator")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !vm.messages.isEmpty {
                    Button("Reset") {
                        withAnimation {
                            vm.reset()
                        }
                    }
                    .foregroundStyle(PrismTheme.textSecondary)
                }
            }
        }
        .alert("Prism Created!", isPresented: $showPrizmateSuccess) {
            Button("View Prism") {
                if let prism = createdPrism {
                    onPrismCreated?(prism)
                }
            }
            Button("Create Another") {
                withAnimation {
                    vm.reset()
                }
            }
        } message: {
            if let prism = createdPrism {
                Text("\"\(prism.name)\" has been saved to your Prisms.")
            }
        }
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
            let repo = PrismRepository(modelContainer: modelContext.container)
            do {
                if let prism = try await vm.finalizeAndSave(repo: repo) {
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
    NavigationStack {
        CreatorView()
    }
    .modelContainer(for: PrismRecord.self, inMemory: true)
}

#Preview("Creator - With Messages") {
    NavigationStack {
        CreatorViewPreview()
    }
    .modelContainer(for: PrismRecord.self, inMemory: true)
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
