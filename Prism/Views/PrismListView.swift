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

    private var loadingView: some View {
        VStack {
            ProgressView()
                .tint(PrismTheme.textSecondary)
            Text("Loading Prisms...")
                .font(.subheadline)
                .foregroundStyle(PrismTheme.textSecondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var prismList: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(prisms) { prism in
                        NavigationLink(value: prism) {
                            if #available(iOS 26.0, *) {
                                PrismRowView(
                                    prism: prism,
                                    isAvailable: ModelAvailability.shared.status.isAvailable
                                )
                            } else {
                                PrismRowView(prism: prism, isAvailable: false)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .frame(width: geometry.size.width)
            }
        }
        .navigationDestination(for: PrismDefinition.self) { prism in
            PrismRunView(prism: prism)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(PrismTheme.textTertiary)

            Text("No Prisms")
                .font(.headline)
                .foregroundStyle(PrismTheme.textPrimary)

            Text("Create your first Prism to get started.")
                .font(.subheadline)
                .foregroundStyle(PrismTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(PrismTheme.error)

            Text("Error Loading")
                .font(.headline)
                .foregroundStyle(PrismTheme.textPrimary)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(PrismTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

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

struct PrismRowView: View {
    let prism: PrismDefinition
    var isAvailable: Bool = true

    /// Beam names joined for preview (e.g., "Caption • Hashtags")
    private var beamPreview: String {
        prism.refractedBeams
            .map { $0.title }
            .joined(separator: " • ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(prism.name)
                    .font(.headline)
                    .foregroundStyle(PrismTheme.textPrimary)

                Spacer()

                if !isAvailable {
                    Label("Requires AI", systemImage: "brain")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .labelStyle(.titleAndIcon)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(PrismTheme.textTertiary)
            }

            Text(prism.incidentBeam.description)
                .font(.subheadline)
                .foregroundStyle(PrismTheme.textSecondary)
                .lineLimit(2)

            Text(beamPreview)
                .font(.caption)
                .foregroundStyle(PrismTheme.textTertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .darkGlassCard()
        .opacity(isAvailable ? 1.0 : 0.7)
    }
}

#Preview {
    NavigationStack {
        PrismListView()
    }
    .modelContainer(for: PrismRecord.self, inMemory: true)
    .preferredColorScheme(.dark)
}
