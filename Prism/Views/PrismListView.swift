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
                ProgressView("Loading Prisms...")
            } else if let error = loadError {
                errorView(error)
            } else if prisms.isEmpty {
                emptyState
            } else {
                prismList
            }
        }
        .navigationTitle("Prisms")
        .task {
            await loadPrisms()
        }
        .refreshable {
            await loadPrisms()
        }
    }

    private var prismList: some View {
        List(prisms) { prism in
            NavigationLink(value: prism) {
                PrismRowView(prism: prism)
            }
        }
        .navigationDestination(for: PrismDefinition.self) { prism in
            PrismRunView(prism: prism)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Prisms",
            systemImage: "sparkles",
            description: Text("Create your first Prism to get started.")
        )
    }

    private func errorView(_ error: Error) -> some View {
        ContentUnavailableView(
            "Error Loading",
            systemImage: "exclamationmark.triangle",
            description: Text(error.localizedDescription)
        )
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(prism.name)
                .font(.headline)

            Text(prism.incidentBeam.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 12) {
                Label("\(prism.refractedBeams.count)", systemImage: "arrow.triangle.branch")
                    .help("Beams")

                let fieldCount = prism.refractedBeams.reduce(0) { $0 + $1.fields.count }
                Label("\(fieldCount)", systemImage: "rectangle.3.group")
                    .help("Fields")
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        PrismListView()
    }
    .modelContainer(for: PrismRecord.self, inMemory: true)
}
