import SwiftUI

/// Step 3: The Reveal
/// Quick visual breakdown of concepts + archetype gallery
struct OnboardingRevealView: View {
    var onComplete: () -> Void

    @State private var showDiagram = false
    @State private var showInput = false
    @State private var showPrism = false
    @State private var showBeams = false
    @State private var showLabels = false
    @State private var showArchetypes = false
    @State private var archetypeVisibility: [Bool] = [false, false, false, false]
    @State private var showTagline = false
    @State private var showContinue = false

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 40) {
                    Spacer().frame(height: 60)

                    // Concept diagram
                    conceptDiagram
                        .padding(.horizontal, 20)

                    // Archetype gallery
                    if showArchetypes {
                        archetypeGallery
                            .padding(.horizontal, 20)
                    }

                    // Tagline
                    if showTagline {
                        VStack(spacing: 8) {
                            Text("Different Prisms.")
                                .font(.system(size: 20, weight: .light))
                                .foregroundStyle(PrismTheme.textSecondary)

                            Text("Different transformations.")
                                .font(.system(size: 20, weight: .light))
                                .foregroundStyle(PrismTheme.textSecondary)
                        }
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    // Continue button
                    if showContinue {
                        Button(action: onComplete) {
                            HStack(spacing: 8) {
                                Text("See Your Toolkit")
                                Image(systemName: "arrow.right")
                            }
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(PrismTheme.glass)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                AngularGradient(
                                                    gradient: Gradient(colors: [
                                                        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .red
                                                    ]),
                                                    center: .center
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                            )
                        }
                        .padding(.top, 20)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }

                    Spacer().frame(height: 60)
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            animateSequence()
        }
    }

    // MARK: - Concept Diagram

    private var conceptDiagram: some View {
        VStack(spacing: 24) {
            // Title
            if showDiagram {
                Text("THE TRANSFORMATION")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PrismTheme.textTertiary)
                    .tracking(3)
                    .transition(.opacity)
            }

            // Diagram
            HStack(spacing: 16) {
                // Input
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(PrismTheme.surface)
                            .frame(width: 60, height: 44)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(PrismTheme.border, lineWidth: 0.5)
                            )

                        Image(systemName: "text.alignleft")
                            .font(.system(size: 18))
                            .foregroundStyle(PrismTheme.textSecondary)
                    }
                    .opacity(showInput ? 1 : 0)
                    .scaleEffect(showInput ? 1 : 0.5)

                    if showLabels {
                        Text("Your input")
                            .font(.caption)
                            .foregroundStyle(PrismTheme.textTertiary)
                            .transition(.opacity)
                    }
                }

                // Arrow 1
                if showPrism {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(PrismTheme.textTertiary)
                        .transition(.opacity.combined(with: .scale))
                }

                // Prism
                VStack(spacing: 8) {
                    ZStack {
                        TrianglePrism()
                            .fill(PrismTheme.glass)
                            .frame(width: 56, height: 56)
                            .overlay(
                                TrianglePrism()
                                    .strokeBorder(PrismTheme.border, lineWidth: 1)
                            )

                        if showPrism {
                            TriangleSpectralRing(intensity: 0.6, lineWidth: 2)
                                .frame(width: 62, height: 62)
                        }
                    }
                    .opacity(showPrism ? 1 : 0)
                    .scaleEffect(showPrism ? 1 : 0.5)

                    if showLabels {
                        Text("Prism")
                            .font(.caption)
                            .foregroundStyle(PrismTheme.textTertiary)
                            .transition(.opacity)
                    }
                }

                // Arrow 2
                if showBeams {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(PrismTheme.textTertiary)
                        .transition(.opacity.combined(with: .scale))
                }

                // Beams
                VStack(spacing: 8) {
                    VStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(beamColor(for: index))
                                .frame(width: 50, height: 12)
                                .opacity(showBeams ? 1 : 0)
                                .scaleEffect(x: showBeams ? 1 : 0.3, y: 1, anchor: .leading)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.7)
                                        .delay(Double(index) * 0.1),
                                    value: showBeams
                                )
                        }
                    }

                    if showLabels {
                        Text("Beams")
                            .font(.caption)
                            .foregroundStyle(PrismTheme.textTertiary)
                            .transition(.opacity)
                    }
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showInput)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showPrism)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(PrismTheme.glass.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(PrismTheme.border, lineWidth: 0.5)
                )
        )
    }

    private func beamColor(for index: Int) -> Color {
        switch index {
        case 0: return .cyan.opacity(0.6)
        case 1: return .purple.opacity(0.6)
        default: return .orange.opacity(0.6)
        }
    }

    // MARK: - Archetype Gallery

    private var archetypeGallery: some View {
        VStack(spacing: 20) {
            Text("FOUR ARCHETYPES")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(PrismTheme.textTertiary)
                .tracking(3)

            HStack(spacing: 20) {
                ForEach(Array(PrismArchetype.allCases.enumerated()), id: \.element.id) { index, archetype in
                    archetypeCard(archetype, index: index)
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func archetypeCard(_ archetype: PrismArchetype, index: Int) -> some View {
        VStack(spacing: 10) {
            ArchetypeIconView(
                archetype: archetype,
                size: 52,
                showGlow: archetypeVisibility[index]
            )

            VStack(spacing: 4) {
                Text(archetype.actionVerb)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(archetype.accentColor)

                Text(archetype.transformationHint)
                    .font(.system(size: 10))
                    .foregroundStyle(PrismTheme.textTertiary)
            }
        }
        .opacity(archetypeVisibility[index] ? 1 : 0)
        .scaleEffect(archetypeVisibility[index] ? 1 : 0.7)
    }

    // MARK: - Animation Sequence

    private func animateSequence() {
        Task {
            // Show diagram title
            try? await Task.sleep(for: .seconds(0.3))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.4)) {
                    showDiagram = true
                }
            }

            // Input element
            try? await Task.sleep(for: .seconds(0.3))
            await MainActor.run {
                showInput = true
            }

            // Prism element
            try? await Task.sleep(for: .seconds(0.4))
            await MainActor.run {
                showPrism = true
            }

            // Beams
            try? await Task.sleep(for: .seconds(0.4))
            await MainActor.run {
                showBeams = true
            }

            // Labels
            try? await Task.sleep(for: .seconds(0.4))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    showLabels = true
                }
            }

            // Archetype gallery
            try? await Task.sleep(for: .seconds(0.6))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.4)) {
                    showArchetypes = true
                }
            }

            // Individual archetypes with stagger
            for i in 0..<4 {
                try? await Task.sleep(for: .seconds(0.15))
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        archetypeVisibility[i] = true
                    }
                }
            }

            // Tagline
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.4)) {
                    showTagline = true
                }
            }

            // Continue button
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.4)) {
                    showContinue = true
                }
            }
        }
    }
}

#Preview {
    OnboardingRevealView {
        print("Complete!")
    }
}
