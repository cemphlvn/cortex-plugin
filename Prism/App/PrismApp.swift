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

struct ContentView: View {
    var body: some View {
        NavigationStack {
            PrismListView()
        }
    }
}

#Preview {
    ContentView()
}
