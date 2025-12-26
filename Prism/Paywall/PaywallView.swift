import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - Native RevenueCat Paywall Wrapper

/// Custom Prism paywall with our own UI design.
/// Uses RevenueCat for purchase handling but custom SwiftUI for presentation.
struct PrismPaywallView: View {
    let trigger: PaywallTrigger

    var body: some View {
        CustomPaywallView(trigger: trigger)
    }
}

// MARK: - Paywall Presentation Modifier

/// View modifier for presenting paywall as a sheet
struct PaywallModifier: ViewModifier {
    @Binding var isPresented: Bool
    let trigger: PaywallTrigger

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                PrismPaywallView(trigger: trigger)
            }
    }
}

extension View {
    /// Present the Prism Pro paywall as a sheet
    func prismPaywall(isPresented: Binding<Bool>, trigger: PaywallTrigger = .generic) -> some View {
        modifier(PaywallModifier(isPresented: isPresented, trigger: trigger))
    }

    /// Present paywall only if user doesn't have the entitlement
    func presentPaywallIfNeeded() -> some View {
        self.presentPaywallIfNeeded(requiredEntitlementIdentifier: EntitlementStore.entitlementId)
    }
}

// MARK: - Inline Paywall (for embedding in views)

/// Embeddable paywall for inline display (not modal)
struct InlinePaywallView: View {
    var body: some View {
        PaywallView(displayCloseButton: false)
            .onPurchaseCompleted { _ in
                PrismHaptics.success()
            }
    }
}

// MARK: - Footer Paywall (for custom header + RC footer)

/// Custom header with RevenueCat's purchase footer
struct PaywallWithCustomHeader<Header: View>: View {
    let header: () -> Header

    var body: some View {
        VStack(spacing: 0) {
            header()
            Spacer()
        }
        .paywallFooter()
        .onPurchaseCompleted { _ in
            PrismHaptics.success()
        }
    }
}

// MARK: - Legacy Custom Paywall (Fallback)

/// Custom paywall UI - use when RC remote paywall not configured.
/// This serves as a fallback if you haven't set up paywalls in the RC dashboard.
struct CustomPaywallView: View {
    @Environment(EntitlementStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let trigger: PaywallTrigger

    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?

    private var triggerMessage: String {
        switch trigger {
        case .createPrism:
            return "You've used all 3 free Prisms"
        case .syncPrisms:
            return "Sync requires Prism Pro"
        case .sharePrism:
            return "Sharing requires Prism Pro"
        case .generic:
            return "Unlock the full Prism experience"
        }
    }

    var body: some View {
        ZStack {
            PrismTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(PrismTheme.textTertiary)
                    }
                    .padding()
                }

                ScrollView {
                    VStack(spacing: 32) {
                        headerSection
                        featuresSection

                        if let offering = store.currentOffering {
                            packagesSection(offering: offering)
                        } else if store.isLoading {
                            ProgressView()
                                .padding()
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        purchaseButton
                        restoreButton
                        termsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .task {
            await store.fetchOfferings()
            selectedPackage = store.annualPackage ?? store.monthlyPackage
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                TrianglePrism()
                    .fill(PrismTheme.glass)
                    .frame(width: 60, height: 60)
                    .overlay(
                        TrianglePrism()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            }

            VStack(spacing: 8) {
                Text("Prism Pro")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text(triggerMessage)
                    .font(.subheadline)
                    .foregroundStyle(PrismTheme.textSecondary)
            }
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureRow(icon: "infinity", title: "Unlimited Prisms", subtitle: "Create as many as you want")
            FeatureRow(icon: "icloud", title: "Cloud Sync", subtitle: "Access on all your devices")
            FeatureRow(icon: "square.and.arrow.up", title: "Share Prisms", subtitle: "Export and share with others")
        }
        .padding(20)
        .background(PrismTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Packages

    private func packagesSection(offering: Offering) -> some View {
        VStack(spacing: 12) {
            if let annual = offering.annual {
                PackageCard(
                    package: annual,
                    isSelected: selectedPackage?.identifier == annual.identifier,
                    isEmphasized: true,
                    badge: "Best Value"
                ) {
                    selectedPackage = annual
                }
            }

            if let monthly = offering.monthly {
                PackageCard(
                    package: monthly,
                    isSelected: selectedPackage?.identifier == monthly.identifier,
                    isEmphasized: false,
                    badge: nil
                ) {
                    selectedPackage = monthly
                }
            }
        }
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            guard let package = selectedPackage else { return }
            isPurchasing = true
            errorMessage = nil

            Task {
                do {
                    try await store.purchase(package)
                    PrismHaptics.success()
                    dismiss()
                } catch {
                    if (error as? RevenueCat.ErrorCode) != .purchaseCancelledError {
                        errorMessage = "Purchase failed. Please try again."
                    }
                }
                isPurchasing = false
            }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text("Start Free Trial")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.white)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(selectedPackage == nil || isPurchasing)
        .opacity(selectedPackage == nil ? 0.5 : 1)
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            isRestoring = true
            errorMessage = nil

            Task {
                do {
                    let info = try await store.restorePurchases()
                    if info.entitlements[EntitlementStore.entitlementId]?.isActive == true {
                        PrismHaptics.success()
                        dismiss()
                    } else {
                        errorMessage = "No active subscription found."
                    }
                } catch {
                    errorMessage = "Restore failed. Please try again."
                }
                isRestoring = false
            }
        } label: {
            if isRestoring {
                ProgressView()
                    .tint(PrismTheme.textSecondary)
            } else {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundStyle(PrismTheme.textSecondary)
            }
        }
        .disabled(isRestoring)
    }

    // MARK: - Terms

    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("7-day free trial, then auto-renews.")
                .font(.caption)
                .foregroundStyle(PrismTheme.textTertiary)

            HStack(spacing: 16) {
                Link("Terms", destination: URL(string: "https://prism.app/terms")!)
                Link("Privacy", destination: URL(string: "https://prism.app/privacy")!)
            }
            .font(.caption)
            .foregroundStyle(PrismTheme.textTertiary)
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PrismTheme.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(PrismTheme.textSecondary)
            }

            Spacer()
        }
    }
}

// MARK: - Package Card

private struct PackageCard: View {
    let package: Package
    let isSelected: Bool
    let isEmphasized: Bool
    let badge: String?
    let onTap: () -> Void

    private var pricePerMonth: String {
        if package.packageType == .annual {
            let monthly = package.storeProduct.price / 12
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = package.storeProduct.currencyCode ?? "USD"
            return formatter.string(from: monthly as NSNumber) ?? ""
        }
        return package.storeProduct.localizedPriceString
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.purple : PrismTheme.border, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 14, height: 14)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(package.packageType == .annual ? "Yearly" : "Monthly")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(PrismTheme.textPrimary)

                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                        }
                    }

                    if package.packageType == .annual {
                        Text("\(pricePerMonth)/mo")
                            .font(.caption)
                            .foregroundStyle(PrismTheme.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(package.storeProduct.localizedPriceString)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PrismTheme.textPrimary)

                    Text(package.packageType == .annual ? "/year" : "/month")
                        .font(.caption)
                        .foregroundStyle(PrismTheme.textSecondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(PrismTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? Color.purple : (isEmphasized ? Color.purple.opacity(0.3) : PrismTheme.border),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Native Paywall") {
    PrismPaywallView(trigger: .createPrism)
        .environment(EntitlementStore())
        .preferredColorScheme(.dark)
}

#Preview("Custom Paywall") {
    CustomPaywallView(trigger: .createPrism)
        .environment(EntitlementStore())
        .preferredColorScheme(.dark)
}
