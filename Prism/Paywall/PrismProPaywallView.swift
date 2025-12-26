import SwiftUI
import RevenueCat

// MARK: - Prism Pro Paywall

/// Premium "WOW" paywall with dramatic animations throughout
/// Research-backed: +20% from subtle animations, press feedback, glow effects
struct PrismProPaywallView: View {
    @Environment(EntitlementStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let trigger: PaywallTrigger

    @State private var selectedTier: PricingTier = .yearly
    @State private var isPurchasing = false
    @State private var purchaseSuccess = false
    @State private var errorMessage: String?

    // Staggered entrance animations
    @State private var heroAppeared = false
    @State private var headlineAppeared = false
    @State private var featuresAppeared = false
    @State private var pricingAppeared = false
    @State private var ctaAppeared = false

    var body: some View {
        ZStack {
            PrismTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    CloseButton { dismiss() }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer(minLength: 4)

                // Hero prism
                HeroPrismIcon()
                    .frame(height: 120)
                    .opacity(heroAppeared ? 1 : 0)
                    .scaleEffect(heroAppeared ? 1 : 0.6)

                // Headline
                headlineSection
                    .opacity(headlineAppeared ? 1 : 0)
                    .offset(y: headlineAppeared ? 0 : 20)
                    .padding(.top, 4)

                Spacer(minLength: 12)

                // Features
                featuresSection
                    .opacity(featuresAppeared ? 1 : 0)
                    .offset(y: featuresAppeared ? 0 : 30)

                Spacer(minLength: 12)

                // Pricing
                pricingSection
                    .opacity(pricingAppeared ? 1 : 0)
                    .offset(y: pricingAppeared ? 0 : 30)

                Spacer(minLength: 12)

                // CTA + Footer
                ctaSection
                    .opacity(ctaAppeared ? 1 : 0)
                    .offset(y: ctaAppeared ? 0 : 20)
            }
        }
        .task {
            await store.fetchOfferings()
            await animateEntrance()
        }
    }

    // MARK: - Entrance Animation

    private func animateEntrance() async {
        try? await Task.sleep(for: .seconds(0.05))
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
            heroAppeared = true
        }

        try? await Task.sleep(for: .seconds(0.12))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            headlineAppeared = true
        }

        try? await Task.sleep(for: .seconds(0.1))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            featuresAppeared = true
        }

        try? await Task.sleep(for: .seconds(0.1))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            pricingAppeared = true
        }

        try? await Task.sleep(for: .seconds(0.1))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            ctaAppeared = true
        }
    }

    // MARK: - Headline Section

    private var headlineSection: some View {
        VStack(spacing: 6) {
            Text("Unlimited Intelligence, Unlocked")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(PrismTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text("Automatize any micro-task without limits")
                .font(.subheadline)
                .foregroundStyle(PrismTheme.textSecondary)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: 0) {
            PaywallFeatureRow(
                icon: "infinity",
                title: "Unlimited Prisms",
                subtitle: "Build as many workflows as you want",
                delay: 0
            )
            PaywallFeatureRow(
                icon: "icloud",
                title: "Cloud sync & backup",
                subtitle: "Never lose your creations and use across devices",
                delay: 0.08
            )
            PaywallFeatureRow(
                icon: "square.and.arrow.up",
                title: "Share & export",
                subtitle: "Reuse anywhere",
                delay: 0.16
            )
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(PrismTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: 8) {
            // Yearly - HERO with "Most Popular"
            YearlyHeroCard(
                monthlyPrice: yearlyMonthly,
                totalPrice: yearlyPrice,
                discountPercent: yearlyDiscount,
                isSelected: selectedTier == .yearly
            ) {
                selectedTier = .yearly
                PrismHaptics.tick()
            }

            HStack(spacing: 8) {
                // Monthly
                CompactPricingCard(
                    label: "Monthly",
                    price: monthlyPrice,
                    isSelected: selectedTier == .monthly
                ) {
                    selectedTier = .monthly
                    PrismHaptics.tick()
                }

                // Weekly (if available)
                if store.weeklyPackage != nil {
                    CompactPricingCard(
                        label: "Weekly",
                        price: weeklyPrice,
                        isSelected: selectedTier == .weekly
                    ) {
                        selectedTier = .weekly
                        PrismHaptics.tick()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Pricing Calculations

    private var weeklyPrice: String {
        store.weeklyPackage?.storeProduct.localizedPriceString ?? "$2.99"
    }

    private var monthlyPrice: String {
        store.monthlyPackage?.storeProduct.localizedPriceString ?? "$4.99"
    }

    private var yearlyPrice: String {
        store.annualPackage?.storeProduct.localizedPriceString ?? "$29.99"
    }

    private var yearlyMonthly: String {
        if let pkg = store.annualPackage {
            let monthly = Double(truncating: pkg.storeProduct.price as NSNumber) / 12
            return formatPrice(monthly, currencyCode: pkg.storeProduct.currencyCode)
        }
        return "$2.50"
    }

    private func formatPrice(_ value: Double, currencyCode: String?) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode ?? "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$\(String(format: "%.2f", value))"
    }

    // Discount compared to monthly
    private var yearlyDiscount: Int {
        guard let annual = store.annualPackage, let monthly = store.monthlyPackage else { return 50 }
        let yearlyMonthlyPrice = Double(truncating: annual.storeProduct.price as NSNumber) / 12
        let monthlyPriceValue = Double(truncating: monthly.storeProduct.price as NSNumber)
        guard monthlyPriceValue > 0 else { return 50 }
        return Int(((monthlyPriceValue - yearlyMonthlyPrice) / monthlyPriceValue) * 100)
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: 0) {
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(PrismTheme.error)
                    .padding(.bottom, 8)
            }

            // Animated CTA with research-backed effects
            AnimatedCTAButton(
                isLoading: isPurchasing,
                showSuccess: purchaseSuccess,
                isEnabled: !isPurchasing && packageForSelectedTier != nil
            ) {
                await purchase()
            }
            .padding(.horizontal, 20)

            // Footer
            VStack(spacing: 4) {
                Text("7-day free trial · Cancel anytime")
                    .font(.caption)
                    .foregroundStyle(PrismTheme.textTertiary)

                HStack(spacing: 16) {
                    Button("Restore Purchases") {
                        Task { await restore() }
                    }
                    Text("·")
                    Link("Terms", destination: URL(string: "https://prism.app/terms")!)
                    Text("·")
                    Link("Privacy", destination: URL(string: "https://prism.app/privacy")!)
                }
                .font(.caption2)
                .foregroundStyle(PrismTheme.textTertiary)
            }
            .padding(.top, 6)
            .padding(.bottom, 4)
        }
    }

    // MARK: - Actions

    private func purchase() async {
        guard let package = packageForSelectedTier else { return }
        isPurchasing = true
        errorMessage = nil

        do {
            try await store.purchase(package)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                purchaseSuccess = true
            }
            PrismHaptics.success()
            try? await Task.sleep(for: .seconds(0.8))
            dismiss()
        } catch {
            if (error as? RevenueCat.ErrorCode) != .purchaseCancelledError {
                errorMessage = "Purchase failed. Please try again."
            }
        }
        isPurchasing = false
    }

    private func restore() async {
        isPurchasing = true
        errorMessage = nil

        do {
            let info = try await store.restorePurchases()
            if info.entitlements[EntitlementStore.entitlementId]?.isActive == true {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    purchaseSuccess = true
                }
                PrismHaptics.success()
                try? await Task.sleep(for: .seconds(0.8))
                dismiss()
            } else {
                errorMessage = "No active subscription found."
            }
        } catch {
            errorMessage = "Restore failed. Please try again."
        }
        isPurchasing = false
    }

    private var packageForSelectedTier: Package? {
        switch selectedTier {
        case .weekly: return store.weeklyPackage
        case .monthly: return store.monthlyPackage
        case .yearly: return store.annualPackage
        }
    }
}

// MARK: - Pricing Tier

enum PricingTier {
    case weekly, monthly, yearly
}

// MARK: - Close Button (Animated)

private struct CloseButton: View {
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
            }
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(PrismTheme.textTertiary)
                .frame(width: 32, height: 32)
                .background(PrismTheme.surface)
                .clipShape(Circle())
                .scaleEffect(isPressed ? 0.9 : 1)
        }
    }
}

// MARK: - Hero Prism Icon (Large, Animated)

private struct HeroPrismIcon: View {
    @State private var rotationAngle: Double = 0
    @State private var glowPulse: CGFloat = 0
    @State private var floatOffset: CGFloat = 0
    @State private var innerGlow: CGFloat = 0

    var body: some View {
        ZStack {
            // Outer pulsing glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.purple.opacity(0.5 - glowPulse * 0.2),
                            Color.blue.opacity(0.25 - glowPulse * 0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 15,
                        endRadius: 75 + glowPulse * 20
                    )
                )
                .frame(width: 150, height: 150)
                .scaleEffect(1 + glowPulse * 0.15)

            // Inner glow ring
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [.purple.opacity(0.4), .blue.opacity(0.3), .purple.opacity(0.4)],
                        center: .center,
                        angle: .degrees(rotationAngle * 0.5)
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 95, height: 95)
                .opacity(0.6 + innerGlow * 0.4)

            // Main triangle
            TrianglePrism()
                .fill(
                    LinearGradient(
                        colors: [PrismTheme.glass.opacity(0.9), PrismTheme.surface],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 65, height: 65)
                .overlay(
                    TrianglePrism()
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    .red, .orange, .yellow, .green, .cyan, .blue, .purple, .red
                                ]),
                                center: .center,
                                angle: .degrees(rotationAngle)
                            ),
                            lineWidth: 2.5
                        )
                )
                .shadow(color: .purple.opacity(0.5), radius: 25, y: 10)
                .offset(y: floatOffset)
        }
        .onAppear {
            // Spectral rotation
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }

            // Glow pulse
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glowPulse = 1
            }

            // Floating effect
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                floatOffset = -8
            }

            // Inner glow pulse (offset timing)
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(0.5)) {
                innerGlow = 1
            }
        }
    }
}

// MARK: - Paywall Feature Row (Animated)

private struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let delay: Double

    @State private var appeared = false
    @State private var iconBounce = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.purple)
                    .scaleEffect(iconBounce ? 1.15 : 1)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(PrismTheme.textPrimary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(PrismTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // Animated checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.green.opacity(0.8))
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.3)
        }
        .padding(.vertical, 10)
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(0.5 + delay))
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                    appeared = true
                }
                // Icon bounce after checkmark
                try? await Task.sleep(for: .seconds(0.15))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    iconBounce = true
                }
                try? await Task.sleep(for: .seconds(0.15))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    iconBounce = false
                }
            }
        }
    }
}

// MARK: - Yearly Hero Card (Most Popular)

private struct YearlyHeroCard: View {
    let monthlyPrice: String
    let totalPrice: String
    let discountPercent: Int
    let isSelected: Bool
    let onTap: () -> Void

    @State private var badgeGlow: CGFloat = 0
    @State private var appeared = false
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // "Most Popular" badge
                HStack {
                    Spacer()
                    Text("MOST POPULAR")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.purple)
                                .shadow(color: .purple.opacity(0.5 + badgeGlow * 0.3), radius: 8 + badgeGlow * 4)
                        )
                        .scaleEffect(appeared ? 1 : 0.8)
                        .opacity(appeared ? 1 : 0)
                    Spacer()
                }
                .padding(.top, -12)
                .zIndex(1)

                // Card content
                HStack(spacing: 12) {
                    // Radio
                    ZStack {
                        Circle()
                            .strokeBorder(isSelected ? Color.purple : PrismTheme.border, lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Circle()
                                .fill(Color.purple)
                                .frame(width: 14, height: 14)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }

                    // Label + discount
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Yearly")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(PrismTheme.textPrimary)

                        Text("Save \(discountPercent)% vs monthly")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.green)
                    }

                    Spacer()

                    // Price
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 3) {
                            Text(monthlyPrice)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(PrismTheme.textPrimary)
                            Text("/mo")
                                .font(.system(size: 12))
                                .foregroundStyle(PrismTheme.textTertiary)
                        }
                        Text("Billed \(totalPrice)/year")
                            .font(.system(size: 11))
                            .foregroundStyle(PrismTheme.textTertiary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? PrismTheme.glass : PrismTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? Color.purple : PrismTheme.border.opacity(0.5),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(color: isSelected ? .purple.opacity(0.2) : .clear, radius: 12)
            )
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                badgeGlow = 1
            }
        }
    }
}

// MARK: - Compact Pricing Card

private struct CompactPricingCard: View {
    let label: String
    let price: String
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Radio
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.purple : PrismTheme.border, lineWidth: 2)
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 10, height: 10)
                    }
                }

                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PrismTheme.textSecondary)

                Spacer()

                Text(price)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(PrismTheme.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(PrismTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? Color.purple : Color.clear,
                                lineWidth: isSelected ? 2 : 0
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Animated CTA Button

private struct AnimatedCTAButton: View {
    let isLoading: Bool
    let showSuccess: Bool
    let isEnabled: Bool
    let action: () async -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowIntensity: CGFloat = 0
    @State private var sweepPhase: CGFloat = -0.3
    @State private var isPressed = false

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            ZStack {
                // Glow behind button (research: glow increases perceived importance)
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.15 + glowIntensity * 0.1))
                    .blur(radius: 15)
                    .scaleEffect(1.1)

                // Main button
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)

                // Light sweep effect
                GeometryReader { geo in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.8), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.4, height: geo.size.height * 1.8)
                        .rotationEffect(.degrees(-25))
                        .offset(x: sweepPhase * geo.size.width * 1.6)
                        .blur(radius: 6)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Content
                HStack(spacing: 10) {
                    if showSuccess {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .transition(.scale.combined(with: .opacity))
                    } else if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.black)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Start Free Trial")
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .foregroundStyle(.black)
            }
            .frame(height: 56)
            .scaleEffect(isPressed ? 0.96 : pulseScale)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.6)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            // Subtle pulse (research: 1.03-1.04 optimal)
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.03
            }

            // Glow pulse
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowIntensity = 1
            }

            // Light sweep (research: creates premium feel)
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: false)) {
                sweepPhase = 1.0
            }
        }
    }
}

// MARK: - Preview

#Preview("Generic") {
    PrismProPaywallView(trigger: .generic)
        .environment(EntitlementStore())
}

#Preview("Create") {
    PrismProPaywallView(trigger: .createPrism)
        .environment(EntitlementStore())
}
