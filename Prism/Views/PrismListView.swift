import SwiftUI
import SwiftData

struct PrismListView: View {
    @Environment(SupabaseAuthService.self) private var auth
    @Environment(EntitlementStore.self) private var entitlementStore
    @EnvironmentObject private var repository: HybridPrismRepository

    // MARK: - State (all in one place)
    @State private var prisms: [PrismDefinition] = []
    @State private var isLoading = true
    @State private var loadError: Error?
    @State private var selectedPrism: PrismDefinition?
    @State private var prismToEdit: PrismDefinition?
    @State private var showDeleteAlert = false
    @State private var prismToDelete: PrismDefinition?
    @State private var showAccount = false
    @State private var showPaywall = false
    @State private var paywallTrigger: PaywallTrigger = .syncPrisms

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
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PrismTheme.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await loadPrisms()
        }
        .refreshable {
            await loadPrisms()
        }
        .alert("Delete Prism?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                prismToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let prism = prismToDelete {
                    let idToDelete = prism.id
                    Task { await deletePrism(id: idToDelete) }
                }
            }
        } message: {
            if let prism = prismToDelete {
                Text("\"\(prism.name)\" will be permanently deleted.")
            }
        }
        // All navigation destinations at same level
        .navigationDestination(item: $selectedPrism) { prism in
            PrismRunView(prism: prism)
        }
        .navigationDestination(item: $prismToEdit) { prism in
            PrismEditView(prism: prism) { updated in
                Task { await savePrism(updated) }
            }
        }
        .navigationDestination(isPresented: $showAccount) {
            AccountView()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                SyncStatusButton(
                    status: repository.syncStatus,
                    isAuthenticated: auth.isAuthenticated,
                    pendingCount: repository.pendingSyncIds.count,
                    hasPro: entitlementStore.hasPro,
                    onSync: {
                        if repository.canSync {
                            await repository.syncPendingPrisms()
                        } else {
                            paywallTrigger = .syncPrisms
                            showPaywall = true
                        }
                    }
                )
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    // Prism count badge (only show for free users)
                    if !entitlementStore.hasPro {
                        PrismCountBadge(
                            count: repository.userCreatedCount,
                            limit: EntitlementStore.freePrismLimit
                        )
                    }

                    Button {
                        showAccount = true
                    } label: {
                        if auth.isAuthenticated {
                            // Signed in: show user avatar
                            Circle()
                                .fill(PrismTheme.glass)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Text(userInitials)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(PrismTheme.textPrimary)
                                )
                        } else {
                            // Not signed in: show person icon
                            Image(systemName: "person.circle")
                                .font(.title3)
                                .foregroundStyle(PrismTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PrismPaywallView(trigger: paywallTrigger)
        }
    }

    // MARK: - User Initials

    private var userInitials: String {
        if let data = auth.currentUser?.userMetadata,
           let name = data["full_name"]?.stringValue {
            let parts = name.split(separator: " ")
            let initials = parts.prefix(2).compactMap { $0.first }.map(String.init)
            return initials.joined()
        }
        if let email = auth.currentUser?.email {
            return String(email.prefix(1)).uppercased()
        }
        return "?"
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
        List {
            ForEach(prisms) { prism in
                PrismCardRow(
                    prism: prism,
                    isAvailable: {
                        if #available(iOS 26.0, *) {
                            return ModelAvailability.shared.status.isAvailable
                        }
                        return false
                    }(),
                    onTap: { selectedPrism = prism },
                    onEdit: { prismToEdit = prism },
                    onDelete: {
                        prismToDelete = prism
                        showDeleteAlert = true
                    }
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(PrismTheme.background)
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

    // MARK: - Delete Prism

    private func deletePrism(id: UUID) async {
        do {
            try await repository.delete(id: id)

            await MainActor.run {
                prisms.removeAll { $0.id == id }
                prismToDelete = nil
            }
        } catch {
            // Silently fail for now; could show error toast
        }
    }

    // MARK: - Save Prism

    private func savePrism(_ prism: PrismDefinition) async {
        do {
            try await repository.save(prism)

            await MainActor.run {
                if let index = prisms.firstIndex(where: { $0.id == prism.id }) {
                    prisms[index] = prism
                }
                prismToEdit = nil
            }
        } catch {
            // Silently fail for now
        }
    }
}

// MARK: - Prism Card Row (with swipe actions, no chevron)

private struct PrismCardRow: View {
    let prism: PrismDefinition
    let isAvailable: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            PrismCard(prism: prism, isAvailable: isAvailable)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash.fill")
            }
            .tint(.red)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: onEdit) {
                Label("Settings", systemImage: "slider.horizontal.3")
            }
            .tint(.gray)
        }
    }
}

// MARK: - Prism Card

struct PrismCard: View {
    let prism: PrismDefinition
    var isAvailable: Bool = true

    private let spectrum: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple]

    // This prism's unique colors based on its beam count
    private var prismColors: [Color] {
        let count = prism.refractedBeams.count
        return (0..<count).map { spectrum[$0 % spectrum.count] }
    }

    private var accentColor: Color {
        prismColors.first ?? .purple
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Row 1: Title + Prism badge
            HStack(alignment: .center, spacing: 12) {
                Text(prism.name)
                    .font(.headline)
                    .foregroundStyle(PrismTheme.textPrimary)
                    .lineLimit(2)

                Spacer(minLength: 4)

                // Compact prism badge
                PrismVizBadge(colors: prismColors)
                    .scaleEffect(0.7)
                    .frame(width: 50, height: 50)
            }

            // Row 2: Description (full width)
            Text(prism.incidentBeam.description)
                .font(.subheadline)
                .foregroundStyle(PrismTheme.textSecondary)
                .lineLimit(2)

            // Row 3: Beam pills (flow layout, full width)
            FlowLayout(spacing: 6) {
                ForEach(Array(prism.refractedBeams.enumerated()), id: \.element.id) { index, beam in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(spectrum[index % spectrum.count])
                            .frame(width: 6, height: 6)
                        Text(beam.title)
                            .font(.caption)
                            .foregroundStyle(PrismTheme.textTertiary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(spectrum[index % spectrum.count].opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                // Base
                PrismTheme.surface

                // Subtle accent glow in corner
                RadialGradient(
                    colors: [accentColor.opacity(0.08), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 150
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.3),
                            PrismTheme.border.opacity(0.5),
                            PrismTheme.border.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .opacity(isAvailable ? 1.0 : 0.5)
    }
}

// MARK: - Prism Count Badge (n/3)

struct PrismCountBadge: View {
    let count: Int
    let limit: Int

    private var isAtLimit: Bool { count >= limit }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "triangle.fill")
                .font(.system(size: 10))
                .foregroundStyle(isAtLimit ? .orange : PrismTheme.textSecondary)

            Text("\(count)/\(limit)")
                .font(.caption.weight(.medium).monospacedDigit())
                .foregroundStyle(isAtLimit ? .orange : PrismTheme.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isAtLimit ? Color.orange.opacity(0.15) : PrismTheme.glass)
        )
    }
}

// MARK: - Prism Visualization Badge

private struct PrismVizBadge: View {
    let colors: [Color]

    private var glowColor: Color {
        colors.first ?? .purple
    }

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            glowColor.opacity(0.2),
                            glowColor.opacity(0.05),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)

            // Prism with gradient border matching beams
            TrianglePrism()
                .fill(
                    LinearGradient(
                        colors: [PrismTheme.glass, PrismTheme.glass.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    TrianglePrism()
                        .strokeBorder(
                            LinearGradient(
                                colors: colors.isEmpty ? [.white.opacity(0.3)] : colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )

            // Refracted beams - dynamic based on actual count
            ForEach(0..<colors.count, id: \.self) { index in
                let totalBeams = colors.count
                let spreadAngle = min(Double(totalBeams - 1) * 12.0, 50.0)
                let startAngle = -spreadAngle / 2
                let angle = totalBeams == 1 ? 0 : startAngle + (spreadAngle * Double(index) / Double(totalBeams - 1))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [colors[index], colors[index].opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 18, height: 2.5)
                    .offset(x: 26)
                    .rotationEffect(.degrees(angle))
            }
        }
        .frame(width: 72, height: 72)
    }
}


// MARK: - Preview

#Preview {
    let container = try! ModelContainer(for: PrismRecord.self, configurations: .init(isStoredInMemoryOnly: true))
    let auth = SupabaseAuthService()

    return NavigationStack {
        PrismListView()
    }
    .modelContainer(container)
    .environment(auth)
    .environmentObject(HybridPrismRepository(modelContainer: container, auth: auth))
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
