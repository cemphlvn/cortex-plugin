import SwiftUI

struct PrismListView: View {
    // TODO: Add @State for prisms list

    var body: some View {
        List {
            Text("Prisms will appear here")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Prisms")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {}) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PrismListView()
    }
}
