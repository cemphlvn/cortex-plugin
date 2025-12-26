import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - Customer Center Sheet Modifier

/// View modifier for presenting Customer Center as a sheet
struct CustomerCenterModifier: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                CustomerCenterView()
            }
    }
}

extension View {
    /// Present Customer Center as a sheet
    func customerCenterSheet(isPresented: Binding<Bool>) -> some View {
        modifier(CustomerCenterModifier(isPresented: isPresented))
    }
}

// MARK: - Manage Subscription Button

/// Button that opens Customer Center for subscription management.
struct ManageSubscriptionButton: View {
    @State private var showCustomerCenter = false

    var body: some View {
        Button {
            showCustomerCenter = true
        } label: {
            HStack {
                Label("Manage Subscription", systemImage: "creditcard")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(PrismTheme.textTertiary)
            }
            .foregroundStyle(PrismTheme.textPrimary)
        }
        .customerCenterSheet(isPresented: $showCustomerCenter)
    }
}
