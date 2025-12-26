import SwiftUI
import RevenueCat

/// Soft paywall shown during onboarding - skippable but highlights Pro value
struct OnboardingPromoView: View {
    @Environment(EntitlementStore.self) private var store
    var onContinue: () -> Void

    @State private var appeared = false
    @State private var featuresAppeared = false
    @State private var ctaAppeared = false
    @State private var isPurchasing = false

    private var monthlyPriceString: String {
        guard let annual = store.annualPackage else { return "$2.50" }
        let monthlyPrice = Double(truncating: annual.storeProduct.price as NSNumber) / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = annual.storeProduct.currencyCode ?? "USD"
        return formatter.string(from: NSNumber(value: monthlyPrice)) ?? "$2.50"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Hero
                VStack(spacing: 16) {
                    // Animated prism
                    PromoPrismIcon()
                        .frame(height: 100)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.7)

                    Text("Go Unlimited")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                        .opacity(appeared ? 1 : 0)

                    Text("Create without limits")
                        .font(.title3)
                        .foregroundStyle(PrismTheme.textSecondary)
                        .opacity(appeared ? 1 : 0)
                }

                Spacer()

                // Features
                VStack(spacing: 16) {
                    PromoFeature(icon: "infinity", text: "Unlimited Prisms", delay: 0)
                    PromoFeature(icon: "icloud", text: "Sync across devices", delay: 0.1)
                    PromoFeature(icon: "square.and.arrow.up", text: "Share & export", delay: 0.2)
                }
                .padding(.horizontal, 40)
                .opacity(featuresAppeared ? 1 : 0)

                Spacer()

                // CTA section
                VStack(spacing: 12) {
                    // Price highlight
                    Text("Just \(monthlyPriceString)/month")
                        .font(.headline)
                        .foregroundStyle(.white)

                    // Primary CTA
                    Button {
                        Task { await startTrial() }
                    } label: {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "sparkles")
                                Text("Start Free Trial")
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isPurchasing)

                    // Skip button
                    Button {
                        onContinue()
                    } label: {
                        Text("Maybe later")
                            .font(.subheadline)
                            .foregroundStyle(PrismTheme.textTertiary)
                    }
                    .padding(.top, 4)

                    // Fine print
                    Text("7-day free trial · Cancel anytime")
                        .font(.caption2)
                        .foregroundStyle(PrismTheme.textTertiary)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(ctaAppeared ? 1 : 0)
                .offset(y: ctaAppeared ? 0 : 20)
            }
        }
        .task {
            await store.fetchOfferings()
            await animateEntrance()
        }
    }

    private func animateEntrance() async {
        try? await Task.sleep(for: .seconds(0.1))
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            appeared = true
        }

        try? await Task.sleep(for: .seconds(0.2))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            featuresAppeared = true
        }

        try? await Task.sleep(for: .seconds(0.2))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            ctaAppeared = true
        }
    }

    private func startTrial() async {
        guard let package = store.annualPackage else { return }
        isPurchasing = true

        do {
            try await store.purchase(package)
            PrismHaptics.success()
            onContinue()
        } catch {
            // User cancelled or error - just continue
        }
        isPurchasing = false
    }
}

// MARK: - Promo Prism Icon

private struct PromoPrismIcon: View {
    @State private var rotation: Double = 0
    @State private var glow: CGFloat = 0

    var body: some View {
        ZStack {
            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.purple.opacity(0.4), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 60 + glow * 10
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(1 + glow * 0.1)

            // Triangle
            TrianglePrism()
                .fill(PrismTheme.glass)
                .frame(width: 50, height: 50)
                .overlay(
                    TrianglePrism()
                        .strokeBorder(
                            AngularGradient(
                                colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red],
                                center: .center,
                                angle: .degrees(rotation)
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .purple.opacity(0.4), radius: 15)
        }
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glow = 1
            }
        }
    }
}

// MARK: - Promo Feature

private struct PromoFeature: View {
    let icon: String
    let text: String
    let delay: Double

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 32)

            Text(text)
                .font(.body)
                .foregroundStyle(.white)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green.opacity(0.8))
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.5)
        }
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(0.5 + delay))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    appeared = true
                }
            }
        }
    }
}

#Preview {
    OnboardingPromoView {
        print("Continue")
    }
    .environment(EntitlementStore())
}
