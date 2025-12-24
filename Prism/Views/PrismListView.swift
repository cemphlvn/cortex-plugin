import SwiftUI
import SwiftData

struct PrismListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var prisms: [PrismDefinition] = []
    @State private var isLoading = true
    @State private var loadError: Error?

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let error = loadError {
                errorView(error)
            } else if prisms.isEmpty {
                emptyState
            } else {
                prismList
            }
        }
        .background(PrismTheme.background)
        .navigationTitle("Prisms")
        .toolbarBackground(PrismTheme.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await loadPrisms()
        }
        .refreshable {
            await loadPrisms()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ZStack {
                TrianglePrism()
                    .fill(PrismTheme.glass)
                    .frame(width: 60, height: 60)

                TriangleSpectralRing(intensity: 0.6, lineWidth: 2)
                    .frame(width: 66, height: 66)
            }
            .scaleEffect(1.0)

            Text("Loading Prisms...")
                .font(.subheadline)
                .foregroundStyle(PrismTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Prism List

    private var prismList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(prisms) { prism in
                    NavigationLink(value: prism) {
                        if #available(iOS 26.0, *) {
                            PrismCard(
                                prism: prism,
                                isAvailable: ModelAvailability.shared.status.isAvailable
                            )
                        } else {
                            PrismCard(prism: prism, isAvailable: false)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationDestination(for: PrismDefinition.self) { prism in
            PrismRunView(prism: prism)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            // Prism with dispersed light
            ZStack {
                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                // Prism triangle
                TrianglePrism()
                    .fill(PrismTheme.glass)
                    .frame(width: 70, height: 70)
                    .overlay(
                        TrianglePrism()
                            .strokeBorder(PrismTheme.border, lineWidth: 1)
                    )

                TriangleSpectralRing(intensity: 0.4, lineWidth: 2)
                    .frame(width: 76, height: 76)
            }

            VStack(spacing: 8) {
                Text("No Prisms Yet")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(PrismTheme.textPrimary)

                Text("Create your first Prism in the Creator tab")
                    .font(.subheadline)
                    .foregroundStyle(PrismTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Error View

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(spacing: 8) {
                Text("Unable to Load")
                    .font(.headline)
                    .foregroundStyle(PrismTheme.textPrimary)

                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(PrismTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await loadPrisms() }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(PrismTheme.glass)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Load Prisms

    private func loadPrisms() async {
        isLoading = true
        loadError = nil

        do {
            let repository = PrismRepository(modelContainer: modelContext.container)

            // Seed bundled prisms if needed
            if try await repository.needsSeeding() {
                try await repository.seedBundledPrisms()
            }

            let loaded = try await repository.fetchAll()

            await MainActor.run {
                prisms = loaded
                isLoading = false
            }
        } catch {
            await MainActor.run {
                loadError = error
                isLoading = false
            }
        }
    }
}

// MARK: - Prism Card

struct PrismCard: View {
    let prism: PrismDefinition
    var isAvailable: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Name + Status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prism.name)
                        .font(.headline)
                        .foregroundStyle(PrismTheme.textPrimary)

                    if let title = prism.incidentBeam.title {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.blue.opacity(0.8))
                            Text(title)
                                .font(.caption)
                                .foregroundStyle(PrismTheme.textSecondary)
                        }
                    }
                }

                Spacer()

                if !isAvailable {
                    Label("AI Required", systemImage: "brain")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            // Mini I → O flow
            HStack(spacing: 8) {
                // Input indicator
                Circle()
                    .fill(.blue.opacity(0.3))
                    .frame(width: 6, height: 6)

                // Flow line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)

                // Mini prism
                TrianglePrism()
                    .fill(PrismTheme.glass)
                    .frame(width: 14, height: 14)

                // Output flow (rainbow)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.red.opacity(0.3), .orange.opacity(0.3), .yellow.opacity(0.3), .green.opacity(0.3), .blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)

                // Output beams
                HStack(spacing: 3) {
                    ForEach(prism.refractedBeams.prefix(3)) { beam in
                        Circle()
                            .fill(beamColor(for: beam.id))
                            .frame(width: 6, height: 6)
                    }
                    if prism.refractedBeams.count > 3 {
                        Text("+\(prism.refractedBeams.count - 3)")
                            .font(.system(size: 8))
                            .foregroundStyle(PrismTheme.textTertiary)
                    }
                }
            }
            .padding(.vertical, 4)

            // Output beam titles
            HStack(spacing: 6) {
                ForEach(prism.refractedBeams.prefix(3)) { beam in
                    Text(beam.title)
                        .font(.caption2)
                        .foregroundStyle(PrismTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(PrismTheme.glass)
                        .clipShape(Capsule())
                }
                if prism.refractedBeams.count > 3 {
                    Text("+\(prism.refractedBeams.count - 3)")
                        .font(.caption2)
                        .foregroundStyle(PrismTheme.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(PrismTheme.textTertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PrismTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(PrismTheme.border, lineWidth: 0.5)
        )
        .opacity(isAvailable ? 1.0 : 0.7)
    }

    private func beamColor(for id: String) -> Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple]
        let index = abs(id.hashValue) % colors.count
        return colors[index].opacity(0.6)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrismListView()
    }
    .modelContainer(for: PrismRecord.self, inMemory: true)
    .preferredColorScheme(.dark)
}

#Preview("With Prisms") {
    NavigationStack {
        PrismListPreview()
    }
    .preferredColorScheme(.dark)
}

private struct PrismListPreview: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                PrismCard(prism: PrismDefinition(
                    name: "Caption Creator",
                    instructions: "Create captions",
                    incidentBeam: IncidentBeamSpec(type: "string", title: "Your Moment", description: "A scene to caption"),
                    refractedBeams: [
                        BeamSpec(id: "caption", title: "Caption", fields: []),
                        BeamSpec(id: "hashtags", title: "Hashtags", fields: [])
                    ]
                ))

                PrismCard(prism: PrismDefinition(
                    name: "Meeting Notes",
                    instructions: "Extract notes",
                    incidentBeam: IncidentBeamSpec(type: "string", title: "Transcript", description: "Meeting transcript"),
                    refractedBeams: [
                        BeamSpec(id: "summary", title: "Summary", fields: []),
                        BeamSpec(id: "actions", title: "Actions", fields: []),
                        BeamSpec(id: "decisions", title: "Decisions", fields: [])
                    ]
                ))

                PrismCard(prism: PrismDefinition(
                    name: "Product Review",
                    instructions: "Analyze review",
                    incidentBeam: IncidentBeamSpec(type: "string", title: "Review", description: "Product review"),
                    refractedBeams: [
                        BeamSpec(id: "sentiment", title: "Sentiment", fields: []),
                        BeamSpec(id: "pros", title: "Pros", fields: []),
                        BeamSpec(id: "cons", title: "Cons", fields: []),
                        BeamSpec(id: "summary", title: "Summary", fields: [])
                    ]
                ), isAvailable: false)
            }
            .padding()
        }
        .background(PrismTheme.background)
        .navigationTitle("Prisms")
    }
}
