import SwiftUI
import FoundationModels

struct PrismRunView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var prism: PrismDefinition
    @State private var input: String = ""
    @State private var outputs: [BeamOutput] = []
    @State private var runState: RunState = .idle
    @State private var errorMessage: String?
    @State private var navigateToEdit = false

    init(prism: PrismDefinition) {
        _prism = State(initialValue: prism)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    // Availability check
                    if #available(iOS 26.0, *) {
                        availabilityAwareContent
                    } else {
                        unsupportedOSView
                    }
                }
                .padding()
                .frame(width: geometry.size.width)
            }
        }
        .background(PrismTheme.background)
        .navigationTitle(prism.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PrismTheme.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    navigateToEdit = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.body)
                        .foregroundStyle(PrismTheme.textSecondary)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToEdit) {
            PrismEditView(prism: prism) { updated in
                Task { await savePrism(updated) }
            }
        }
    }

    private func savePrism(_ updated: PrismDefinition) async {
        do {
            let repository = PrismRepository(modelContainer: modelContext.container)
            try await repository.save(updated)

            await MainActor.run {
                prism = updated
            }
        } catch {
            // Silently fail
        }
    }

    // MARK: - Content Views

    @available(iOS 26.0, *)
    @ViewBuilder
    private var availabilityAwareContent: some View {
        let availability = ModelAvailability.shared

        switch availability.status {
        case .available:
            instrumentPanel

        case .unavailable(let reason):
            unavailableView(reason: reason)

        case .checking:
            ProgressView("Checking availability...")
                .tint(PrismTheme.textSecondary)
        }
    }

    /// Main instrument panel layout
    @available(iOS 26.0, *)
    private var instrumentPanel: some View {
        VStack(spacing: 28) {
            // Header: description
            Text(prism.incidentBeam.description)
                .font(.subheadline)
                .foregroundStyle(PrismTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Input area
            inputSection

            // Central Prism button
            PrismButton(
                state: runState,
                isEnabled: isInputValid
            ) {
                runPrism()
            }
            .padding(.vertical, 8)

            // Error (if any)
            errorView

            // Beam slots / outputs
            beamSection
        }
    }

    private var inputSection: some View {
        TextField(
            prism.inputPlaceholder,
            text: $input,
            axis: .vertical
        )
        .textFieldStyle(.plain)
        .padding()
        .foregroundStyle(PrismTheme.textPrimary)
        .background(PrismTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: PrismTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: PrismTheme.cornerRadius)
                .strokeBorder(PrismTheme.border, lineWidth: 0.5)
        )
        .lineLimit(3...8)
        .disabled(runState == .running)
    }

    @ViewBuilder
    private var errorView: some View {
        if let errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(PrismTheme.error)
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(PrismTheme.textPrimary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PrismTheme.error.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: PrismTheme.cornerRadius))
        }
    }

    @ViewBuilder
    private var beamSection: some View {
        VStack(spacing: 12) {
            switch runState {
            case .idle:
                // Show skeleton slots
                ForEach(prism.refractedBeams) { spec in
                    BeamSlotView(spec: spec)
                }

            case .running:
                // Show skeleton with subtle pulse
                ForEach(prism.refractedBeams) { spec in
                    BeamSlotView(spec: spec)
                        .opacity(0.6)
                }

            case .revealed:
                // Show actual outputs with stagger
                ForEach(Array(outputs.enumerated()), id: \.element.id) { index, beam in
                    BeamOutputView(
                        beam: beam,
                        spec: prism.refractedBeams.first { $0.id == beam.id },
                        index: index
                    )
                }
            }
        }
    }

    private func unavailableView(reason: ModelAvailability.UnavailableReason) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "cpu")
                .font(.system(size: 48))
                .foregroundStyle(PrismTheme.textTertiary)

            Text("Apple Intelligence Required")
                .font(.headline)
                .foregroundStyle(PrismTheme.textPrimary)

            Text(reason.message)
                .font(.subheadline)
                .foregroundStyle(PrismTheme.textSecondary)
                .multilineTextAlignment(.center)

            if case .appleIntelligenceNotEnabled = reason {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
                .tint(PrismTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var unsupportedOSView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("iOS 26 Required")
                .font(.headline)
                .foregroundStyle(PrismTheme.textPrimary)

            Text("Prism requires iOS 26 or later to run on-device AI models.")
                .font(.subheadline)
                .foregroundStyle(PrismTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - State

    private var isInputValid: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Engine Integration

    private func runPrism() {
        guard #available(iOS 26.0, *) else { return }

        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }

        runState = .running
        errorMessage = nil
        outputs = []

        Task {
            await executeRun(input: trimmedInput)
        }
    }

    @available(iOS 26.0, *)
    private func executeRun(input: String) async {
        do {
            // Compile (cached)
            let cache = PrismExecutableCache()
            let executable = try await cache.getOrCompile(prism)

            // Run
            let engine = PrismEngine()
            let result = try await engine.run(executable: executable, input: input)

            await MainActor.run {
                outputs = result
                runState = .revealed
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                runState = .idle
            }
        }
    }
}

#Preview {
    NavigationStack {
        PrismRunView(prism: PrismDefinition(
            name: "Caption Creator",
            instructions: "Create a short caption",
            incidentBeam: IncidentBeamSpec(type: "string", title: "Scene", description: "A scene to caption"),
            refractedBeams: [
                BeamSpec(id: "caption", title: "Caption", fields: [
                    BeamFieldSpec(key: "text", guide: "The caption text", valueType: .string),
                    BeamFieldSpec(key: "hashtags", guide: "Related hashtags", valueType: .stringArray)
                ])
            ],
            exampleInput: "sunset walk after a hard week"
        ))
    }
    .preferredColorScheme(.dark)
}
