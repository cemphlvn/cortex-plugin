import SwiftUI

/// Step 5: The Library
/// Shows bundled prisms and invites user to explore or create
struct OnboardingLibraryView: View {
    var onComplete: (OnboardingDestination) -> Void

    enum OnboardingDestination {
        case library
        case creator
    }

    // Bundled prism info (matches actual bundled JSONs)
    private let bundledPrisms: [BundledPrismInfo] = [
        BundledPrismInfo(
            name: "Product Review",
            icon: "eye.circle",
            color: .cyan,
            tagline: "Analyze any review into pros, cons, and verdict",
            archetype: "Judge It"
        ),
        BundledPrismInfo(
            name: "Caption Creator",
            icon: "sparkles",
            color: .purple,
            tagline: "Generate engaging captions from any context",
            archetype: "Make It"
        ),
        BundledPrismInfo(
            name: "Meeting Notes",
            icon: "arrow.triangle.swap",
            color: .orange,
            tagline: "Transform messy notes into structured action items",
            archetype: "Sort It"
        )
    ]

    @State private var showHeader = false
    @State private var cardVisibility: [Bool] = [false, false, false]
    @State private var showButtons = false
    @State private var showFooter = false

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 60)

                    // Header
                    if showHeader {
                        VStack(spacing: 8) {
                            Text("Your Toolkit")
                                .font(.system(size: 32, weight: .light))
                                .foregroundStyle(.white)

                            Text("Ready to use. On-device AI.")
                                .font(.system(size: 15))
                                .foregroundStyle(PrismTheme.textSecondary)
                        }
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Prism cards
                    VStack(spacing: 16) {
                        ForEach(Array(bundledPrisms.enumerated()), id: \.offset) { index, prism in
                            bundledPrismCard(prism, index: index)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Action buttons
                    if showButtons {
                        VStack(spacing: 12) {
                            // Primary: Start Exploring
                            Button {
                                PrismHaptics.buttonPress()
                                onComplete(.library)
                            } label: {
                                HStack(spacing: 8) {
                                    Text("Start Exploring")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    Capsule()
                                        .fill(.white)
                                )
                            }

                            // Secondary: Create My Own
                            Button {
                                PrismHaptics.tick()
                                onComplete(.creator)
                            } label: {
                                Text("Create My Own")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(PrismTheme.textSecondary)
                                    .padding(.vertical, 12)
                            }
                        }
                        .padding(.horizontal, 40)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // Footer
                    if showFooter {
                        Text("You can always create more in the Creator tab")
                            .font(.caption)
                            .foregroundStyle(PrismTheme.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .transition(.opacity)
                    }

                    Spacer().frame(height: 40)
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            animateSequence()
        }
    }

    // MARK: - Prism Card

    private func bundledPrismCard(_ prism: BundledPrismInfo, index: Int) -> some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(prism.color.opacity(0.15))
                    .frame(width: 52, height: 52)

                Image(systemName: prism.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(prism.color)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(prism.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(prism.archetype)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(prism.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(prism.color.opacity(0.15))
                        )
                }

                Text(prism.tagline)
                    .font(.system(size: 13))
                    .foregroundStyle(PrismTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .background(PrismTheme.glass)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(PrismTheme.border, lineWidth: 0.5)
        )
        .opacity(cardVisibility[index] ? 1 : 0)
        .offset(y: cardVisibility[index] ? 0 : 20)
        .scaleEffect(cardVisibility[index] ? 1 : 0.95)
    }

    // MARK: - Animation

    private func animateSequence() {
        Task {
            // Header
            try? await Task.sleep(for: .seconds(0.3))
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showHeader = true
                }
            }

            // Cards with stagger
            for i in 0..<bundledPrisms.count {
                try? await Task.sleep(for: .seconds(0.15))
                await MainActor.run {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                        cardVisibility[i] = true
                    }
                }
            }

            // Buttons
            try? await Task.sleep(for: .seconds(0.4))
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showButtons = true
                }
            }

            // Footer
            try? await Task.sleep(for: .seconds(0.3))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    showFooter = true
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct BundledPrismInfo {
    let name: String
    let icon: String
    let color: Color
    let tagline: String
    let archetype: String
}

#Preview {
    OnboardingLibraryView { destination in
        print("Selected: \(destination)")
    }
}
