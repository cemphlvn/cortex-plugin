import SwiftUI
import SwiftData

@main
struct PrismApp: App {
    @State private var authService = SupabaseAuthService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
        }
        .modelContainer(for: PrismRecord.self)
    }
}

// MARK: - Root View (Onboarding Gate)

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    @State private var onboardingDestination: OnboardingLibraryView.OnboardingDestination?

    var body: some View {
        ContentView(initialTab: onboardingDestination == .creator ? .creator : .prisms)
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingContainerView { destination in
                    onboardingDestination = destination
                    hasCompletedOnboarding = true
                    showOnboarding = false
                }
            }
            .onAppear {
                if !hasCompletedOnboarding {
                    // Small delay to ensure smooth presentation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showOnboarding = true
                    }
                }
            }
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
            }
            .tabItem {
                Label("Prisms", systemImage: "triangle.fill")
            }
            .tag(AppTab.prisms)
        }
        .tint(.white)
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
