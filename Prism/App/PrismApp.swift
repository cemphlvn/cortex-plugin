import SwiftUI
import SwiftData
import UIKit
import RevenueCat

@main
struct PrismApp: App {
    @State private var authService = SupabaseAuthService()
    @State private var entitlementStore = EntitlementStore()
    @StateObject private var repository: HybridPrismRepository

    let modelContainer: ModelContainer

    init() {
        do {
            let container = try ModelContainer(for: PrismRecord.self)
            self.modelContainer = container

            // Create auth service and repository
            let auth = SupabaseAuthService()
            _authService = State(initialValue: auth)
            _repository = StateObject(wrappedValue: HybridPrismRepository(
                modelContainer: container,
                auth: auth
            ))

            // Configure RevenueCat
            EntitlementStore.configure()

            // Configure UIKit appearances for dark theme
            configureAppearance()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    private func configureAppearance() {
        // Fix white background flash during List swipe actions
        let darkBg = UIColor(white: 0.06, alpha: 1.0)

        UITableView.appearance().backgroundColor = darkBg
        UITableViewCell.appearance().backgroundColor = .clear

        // Modern SwiftUI Lists use UICollectionView
        UICollectionView.appearance().backgroundColor = darkBg

        // Ensure all contained views also have correct background
        UIView.appearance(whenContainedInInstancesOf: [UITableView.self]).backgroundColor = .clear
        UIView.appearance(whenContainedInInstancesOf: [UICollectionView.self]).backgroundColor = .clear
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .environment(entitlementStore)
                .environmentObject(repository)
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - Root View (Onboarding Gate)

struct RootView: View {
    @Environment(SupabaseAuthService.self) private var auth
    @Environment(EntitlementStore.self) private var entitlementStore
    @EnvironmentObject private var repository: HybridPrismRepository

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appOpenCount") private var appOpenCount = 0
    @AppStorage("hasSeenSessionPaywall") private var hasSeenSessionPaywall = false
    @State private var onboardingDestination: OnboardingLibraryView.OnboardingDestination?
    @State private var hasSyncedOnLaunch = false
    @State private var showSessionPaywall = false

    var body: some View {
        ContentView(initialTab: onboardingDestination == .creator ? .creator : .prisms)
            .fullScreenCover(isPresented: shouldShowOnboarding) {
                OnboardingContainerView { destination in
                    onboardingDestination = destination
                    hasCompletedOnboarding = true
                }
            }
            .fullScreenCover(isPresented: $showSessionPaywall) {
                PrismPaywallView(trigger: .generic)
            }
            .task {
                // Wire entitlement store to repository
                repository.setEntitlementStore(entitlementStore)

                // Fetch offerings on launch
                await entitlementStore.fetchOfferings()

                // Track app opens for session-based paywall trigger
                if hasCompletedOnboarding && !entitlementStore.hasPro && !hasSeenSessionPaywall {
                    appOpenCount += 1
                    // Show paywall on 3rd open
                    if appOpenCount >= 3 {
                        hasSeenSessionPaywall = true
                        // Brief delay so app loads first
                        try? await Task.sleep(for: .seconds(1))
                        await MainActor.run {
                            showSessionPaywall = true
                        }
                    }
                }

                // Auto-sync once on launch (not on every appear)
                guard !hasSyncedOnLaunch else { return }
                hasSyncedOnLaunch = true
                if auth.isAuthenticated && entitlementStore.hasPro {
                    await repository.syncPendingPrisms()
                }
            }
            .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
                repository.onAuthStateChanged()
                if isAuthenticated && entitlementStore.hasPro {
                    Task { await repository.syncPendingPrisms() }
                }
            }
    }

    /// Binding derived directly from persisted state — no intermediate @State
    private var shouldShowOnboarding: Binding<Bool> {
        Binding(
            get: { !hasCompletedOnboarding },
            set: { newValue in
                if !newValue {
                    hasCompletedOnboarding = true
                }
            }
        )
    }
}

// MARK: - Tab Selection

enum AppTab: String, CaseIterable {
    case creator
    case prisms
}

// MARK: - Content View

struct ContentView: View {
    var initialTab: AppTab = .prisms

    @State private var selectedTab: AppTab = .prisms
    @State private var prismPath = NavigationPath()
    @State private var createdPrismToShow: PrismDefinition?

    init(initialTab: AppTab = .prisms) {
        self.initialTab = initialTab
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Creator Tab
            NavigationStack {
                CreatorView(onPrismCreated: { prism in
                    // Switch to Prisms tab and navigate to the new prism
                    createdPrismToShow = prism
                    selectedTab = .prisms
                })
            }
            .tabItem {
                Label("Creator", systemImage: "sparkles")
            }
            .tag(AppTab.creator)

            // Prisms Tab
            NavigationStack(path: $prismPath) {
                PrismListView()
                    .navigationDestination(for: PrismDefinition.self) { prism in
                        PrismRunView(prism: prism)
                    }
            }
            .tabItem {
                Label("Prisms", systemImage: "triangle.fill")
            }
            .tag(AppTab.prisms)
        }
        .tint(.white)
        .background(PrismTheme.background)
        .preferredColorScheme(.dark)
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .prisms, let prism = createdPrismToShow {
                // Navigate to the created prism after tab switch
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000) // Brief delay for animation
                    await MainActor.run {
                        prismPath.append(prism)
                        createdPrismToShow = nil
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: PrismRecord.self, inMemory: true)
}
