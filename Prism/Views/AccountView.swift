import SwiftUI
import Supabase

/// Account settings view - shows auth state and sign in/out options
struct AccountView: View {
    @Environment(SupabaseAuthService.self) private var auth
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
        VStack(alignment: .leading, spacing: 8) {
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

            // Sync status
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Synced")
                    .font(.caption)
                    .foregroundStyle(PrismTheme.textSecondary)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
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
    NavigationStack {
        AccountView()
    }
    .environment(SupabaseAuthService())
    .preferredColorScheme(.dark)
}
