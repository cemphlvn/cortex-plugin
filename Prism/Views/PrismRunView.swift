import SwiftUI

struct PrismRunView: View {
    let prism: PrismDefinition

    @State private var input: String = ""
    @State private var outputs: [BeamOutput] = []
    @State private var isRunning: Bool = false
    @State private var error: Error?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Input section
                VStack(alignment: .leading, spacing: 8) {
                    Text(prism.incidentBeam.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("Enter your input...", text: $input, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }

                // Run button
                Button(action: runPrism) {
                    if isRunning {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Run Prism")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(input.isEmpty || isRunning)

                // Error display
                if let error {
                    Text(error.localizedDescription)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                // Outputs
                ForEach(outputs) { beam in
                    BeamOutputView(beam: beam, spec: prism.refractedBeams.first { $0.id == beam.id })
                }
            }
            .padding()
        }
        .navigationTitle(prism.name)
    }

    private func runPrism() {
        // TODO: Implement with PrismEngine
    }
}
