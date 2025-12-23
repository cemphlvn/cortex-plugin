import SwiftUI
import FoundationModels

struct PrismRunView: View {
    let prism: PrismDefinition

    @State private var input: String = ""
    @State private var outputs: [BeamOutput] = []
    @State private var isRunning: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Availability check
                if #available(iOS 26.0, *) {
                    availabilityAwareContent
                } else {
                    unsupportedOSView
                }
            }
            .padding()
        }
        .navigationTitle(prism.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Content Views

    @available(iOS 26.0, *)
    @ViewBuilder
    private var availabilityAwareContent: some View {
        let availability = ModelAvailability.shared

        switch availability.status {
        case .available:
            inputSection
            runButton
            errorView
            outputsSection

        case .unavailable(let reason):
            unavailableView(reason: reason)

        case .checking:
            ProgressView("Checking availability...")
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Input")
                .font(.headline)

            Text(prism.incidentBeam.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("Enter your input...", text: $input, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...8)
        }
    }

    private var runButton: some View {
        Button(action: runPrism) {
            Group {
                if isRunning {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(.white)
                        Text("Running...")
                    }
                } else {
                    Text("Run Prism")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isRunning)
    }

    @ViewBuilder
    private var errorView: some View {
        if let errorMessage {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(errorMessage)
                    .font(.callout)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private var outputsSection: some View {
        if !outputs.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("Output")
                    .font(.headline)

                ForEach(outputs) { beam in
                    BeamOutputView(
                        beam: beam,
                        spec: prism.refractedBeams.first { $0.id == beam.id }
                    )
                }
            }
        }
    }

    private func unavailableView(reason: ModelAvailability.UnavailableReason) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "cpu")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Apple Intelligence Required")
                .font(.headline)

            Text(reason.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if case .appleIntelligenceNotEnabled = reason {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
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

            Text("Prism requires iOS 26 or later to run on-device AI models.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Engine Integration

    private func runPrism() {
        guard #available(iOS 26.0, *) else { return }

        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }

        isRunning = true
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
                isRunning = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isRunning = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        PrismRunView(prism: PrismDefinition(
            name: "Test Prism",
            instructions: "Test instructions",
            incidentBeam: IncidentBeamSpec(type: "string", description: "Enter something"),
            refractedBeams: [
                BeamSpec(id: "test_beam", title: "Test", fields: [
                    BeamFieldSpec(key: "output", guide: "Test output", valueType: .string)
                ])
            ]
        ))
    }
}
