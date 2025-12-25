import SwiftUI
import SwiftData
import Supabase

/// Account settings view - shows auth state and sign in/out options
struct AccountView: View {
    @Environment(SupabaseAuthService.self) private var auth
    @EnvironmentObject private var repository: HybridPrismRepository
    @Environment(\.dismiss) private var dismiss

    @State private var showAuthSheet = false
    @State private var showSignOutConfirm = false

    var body: some View {
        List {
            // MARK: - Account Status
            Section {
                if auth.isAuthenticated {
                    authenticatedSection
                } else {
                    unauthenticatedSection
                }
            }
            .listRowBackground(PrismTheme.surface)

            // MARK: - Sync (only if authenticated)
            if auth.isAuthenticated {
                Section {
                    syncSection
                } header: {
                    Text("Sync")
                }
                .listRowBackground(PrismTheme.surface)
            }

            // MARK: - About
            Section {
                Link(destination: URL(string: "https://prism.app/help")!) {
                    Label("Help & Support", systemImage: "questionmark.circle")
                }

                Link(destination: URL(string: "https://prism.app/terms")!) {
                    Label("Terms of Service", systemImage: "doc.text")
                }

                Link(destination: URL(string: "https://prism.app/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
            }
            .listRowBackground(PrismTheme.surface)

            // MARK: - App Info
            Section {
                HStack {
                    Text("Version")
                        .foregroundStyle(PrismTheme.textSecondary)
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(PrismTheme.textSecondary)
                }
            }
            .listRowBackground(PrismTheme.surface)

            // MARK: - Sign Out
            if auth.isAuthenticated {
                Section {
                    Button(role: .destructive) {
                        showSignOutConfirm = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
                .listRowBackground(PrismTheme.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(PrismTheme.background)
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PrismTheme.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SyncStatusButton(
                    status: repository.syncStatus,
                    isAuthenticated: auth.isAuthenticated,
                    pendingCount: repository.pendingSyncIds.count,
                    onSync: { await repository.syncPendingPrisms() }
                )
            }
        }
        .sheet(isPresented: $showAuthSheet) {
            AuthView(showSkipOption: false)
        }
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirm) {
            Button("Sign Out", role: .destructive) {
                Task {
                    try? await auth.signOut()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your local Prisms will remain on this device.")
        }
    }

    // MARK: - Authenticated Section

    private var authenticatedSection: some View {
        HStack {
            // User avatar
            ZStack {
                Circle()
                    .fill(PrismTheme.glass)
                    .frame(width: 50, height: 50)

                Text(userInitials)
                    .font(.headline)
                    .foregroundStyle(PrismTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                if let name = userName {
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(PrismTheme.textPrimary)
                }
                if let email = userEmail {
                    Text(email)
                        .font(.subheadline)
                        .foregroundStyle(PrismTheme.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Sync Section

    private var syncSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                Task { try? await repository.pullFromCloud() }
            } label: {
                HStack {
                    Label("Pull from Cloud", systemImage: "icloud.and.arrow.down")
                    Spacer()
                    if isSyncing {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(PrismTheme.textPrimary)
            }
            .disabled(isSyncing)

            Text("Download prisms saved on other devices")
                .font(.caption)
                .foregroundStyle(PrismTheme.textTertiary)
        }
        .padding(.vertical, 4)
    }

    private var isSyncing: Bool {
        if case .syncing = repository.syncStatus { return true }
        return false
    }

    // MARK: - Unauthenticated Section

    private var unauthenticatedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(PrismTheme.glass)
                        .frame(width: 50, height: 50)

                    Image(systemName: "person.crop.circle")
                        .font(.title2)
                        .foregroundStyle(PrismTheme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Not Signed In")
                        .font(.headline)
                        .foregroundStyle(PrismTheme.textPrimary)
                    Text("Sign in to sync and share")
                        .font(.subheadline)
                        .foregroundStyle(PrismTheme.textSecondary)
                }
            }

            Button {
                showAuthSheet = true
            } label: {
                Text("Sign In")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.white)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private var userName: String? {
        if let data = auth.currentUser?.userMetadata,
           let name = data["full_name"]?.stringValue {
            return name
        }
        return nil
    }

    private var userEmail: String? {
        auth.currentUser?.email
    }

    private var userInitials: String {
        if let name = userName {
            let parts = name.split(separator: " ")
            let initials = parts.prefix(2).compactMap { $0.first }.map(String.init)
            return initials.joined()
        }
        if let email = userEmail {
            return String(email.prefix(1)).uppercased()
        }
        return "?"
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - JSON Value Extension

extension AnyJSON {
    var stringValue: String? {
        switch self {
        case .string(let value):
            return value
        default:
            return nil
        }
    }
}

#Preview("Signed Out") {
    let container = try! ModelContainer(for: PrismRecord.self, configurations: .init(isStoredInMemoryOnly: true))
    let auth = SupabaseAuthService()

    return NavigationStack {
        AccountView()
    }
    .environment(auth)
    .environmentObject(HybridPrismRepository(modelContainer: container, auth: auth))
    .preferredColorScheme(.dark)
}
