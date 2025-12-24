import SwiftUI
import SwiftData

@main
struct PrismApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: PrismRecord.self)
    }
}

// MARK: - Tab Selection

enum AppTab: String, CaseIterable {
    case prisms
    case creator
}

// MARK: - Content View

struct ContentView: View {
    @State private var selectedTab: AppTab = .prisms
    @State private var prismPath = NavigationPath()
    @State private var createdPrismToShow: PrismDefinition?

    var body: some View {
        TabView(selection: $selectedTab) {
            // Prisms Tab
            NavigationStack(path: $prismPath) {
                PrismListView()
            }
            .tabItem {
                Label("Prisms", systemImage: "triangle.fill")
            }
            .tag(AppTab.prisms)

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
