import SwiftUI

@main
struct PrismApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            PrismListView()
        }
    }
}
