import SwiftUI

/// Step 4: The Reveal - Archetype showcase with tap-based transformations
/// Shows each archetype with an input→output transformation animation
struct OnboardingRevealView: View {
    var onComplete: () -> Void

    @State private var currentArchetypeIndex = 0
    @State private var phase: TransformPhase = .idle
    @State private var showHeader = false
    @State private var showArchetype = false
    @State private var showInput = false
    @State private var showPrism = false
    @State private var showBeams = false
    @State private var showNav = false
    @State private var showContinue = false

    private let archetypes = PrismArchetype.allCases

    private enum TransformPhase {
        case idle
        case inputEntering
        case transforming
        case outputRevealing
        case complete
    }

    // Example transformations for each archetype
    private let examples: [PrismArchetype: (input: String, outputs: [(String, String)])] = [
        .analyzer: (
            input: "Should I take the job?",
            outputs: [("Verdict", "Consider it"), ("Pros", "Better pay, growth"), ("Cons", "Long commute")]
        ),
        .generator: (
            input: "sunset with friends",
            outputs: [("Caption", "Golden hour, golden memories"), ("Tags", "#sunset #friends")]
        ),
        .transformer: (
            input: "we discussed Q3 launch...",
            outputs: [("Summary", "Q3 launch planning"), ("Action Items", "Review timeline"), ("Owners", "Sarah, John")]
        ),
        .extractor: (
            input: "Meet Tuesday, deadline March 15",
            outputs: [("Dates", "Tuesday, March 15"), ("Events", "Meeting, Deadline")]
        )
    ]

    private var currentArchetype: PrismArchetype {
        archetypes[currentArchetypeIndex]
    }

    private var currentExample: (input: String, outputs: [(String, String)]) {
        examples[currentArchetype] ?? (input: "Input", outputs: [("Output", "Result")])
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer().frame(height: 60)

                // Header
                VStack(spacing: 8) {
                    Text("FOUR ARCHETYPES")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrismTheme.textTertiary)
                        .tracking(3)

                    Text("Tap to see each transformation")
                        .font(.system(size: 14))
                        .foregroundStyle(PrismTheme.textTertiary)
                }
                .opacity(showHeader ? 1 : 0)

                // Archetype selector (dots/icons)
                archetypeSelector
                    .opacity(showNav ? 1 : 0)

                Spacer()

                // Main transformation area
                transformationView
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)

                Spacer()

                // Navigation hint
                if showNav && !showContinue {
                    Text("Tap anywhere to continue")
                        .font(.system(size: 13))
                        .foregroundStyle(PrismTheme.textTertiary)
                        .opacity(phase == .complete ? 1 : 0.5)
                }

                // Continue button (after seeing all)
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
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }

                Spacer().frame(height: 50)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap()
        }
        .onAppear {
            startSequence()
        }
    }

    // MARK: - Archetype Selector

    private var archetypeSelector: some View {
        HStack(spacing: 16) {
            ForEach(Array(archetypes.enumerated()), id: \.element.id) { index, archetype in
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(index == currentArchetypeIndex ? archetype.accentColor.opacity(0.2) : PrismTheme.surface)
                            .frame(width: 44, height: 44)

                        Image(systemName: archetype.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(index == currentArchetypeIndex ? archetype.accentColor : PrismTheme.textTertiary)
                    }

                    Text(archetype.actionVerb)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(index == currentArchetypeIndex ? archetype.accentColor : PrismTheme.textTertiary)
                }
                .opacity(index <= currentArchetypeIndex ? 1 : 0.4)
                .animation(.easeOut(duration: 0.3), value: currentArchetypeIndex)
            }
        }
    }

    // MARK: - Transformation View

    private var transformationView: some View {
        VStack(spacing: 32) {
            // Archetype title
            VStack(spacing: 8) {
                Text(currentArchetype.displayName)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white)

                Text(currentArchetype.transformationHint)
                    .font(.system(size: 14))
                    .foregroundStyle(currentArchetype.accentColor)
            }
            .opacity(showArchetype ? 1 : 0)
            .offset(y: showArchetype ? 0 : 10)

            // Transformation diagram
            VStack(spacing: 20) {
                // Input card
                inputCard
                    .opacity(showInput ? 1 : 0)
                    .offset(y: showInput ? 0 : 15)
                    .scaleEffect(phase == .transforming ? 0.95 : 1)

                // Prism indicator
                prismIndicator
                    .opacity(showPrism ? 1 : 0)
                    .scaleEffect(showPrism ? 1 : 0.8)

                // Output beams
                outputBeams
                    .opacity(showBeams ? 1 : 0)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: phase)
        }
    }

    private var inputCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 14))
                .foregroundStyle(PrismTheme.textTertiary)

            Text(currentExample.input)
                .font(.system(size: 14))
                .foregroundStyle(PrismTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PrismTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(PrismTheme.border, lineWidth: 0.5)
        )
    }

    private var prismIndicator: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(phase == .transforming || phase == .outputRevealing || phase == .complete
                      ? currentArchetype.accentColor.opacity(0.5)
                      : PrismTheme.border)
                .frame(width: 30, height: 1)
                .animation(.easeOut(duration: 0.3), value: phase)

            ZStack {
                if phase == .transforming || phase == .outputRevealing || phase == .complete {
                    TriangleSpectralRing(intensity: phase == .complete ? 0.9 : 0.6, lineWidth: 2)
                        .frame(width: 48, height: 48)
                }

                TrianglePrism()
                    .fill(PrismTheme.glass)
                    .frame(width: 36, height: 36)
                    .overlay(
                        TrianglePrism()
                            .strokeBorder(currentArchetype.accentColor.opacity(0.5), lineWidth: 1)
                    )
            }

            Rectangle()
                .fill(phase == .outputRevealing || phase == .complete
                      ? currentArchetype.accentColor.opacity(0.5)
                      : PrismTheme.border)
                .frame(width: 30, height: 1)
                .animation(.easeOut(duration: 0.3).delay(0.1), value: phase)
        }
    }

    private var outputBeams: some View {
        VStack(spacing: 8) {
            ForEach(Array(currentExample.outputs.enumerated()), id: \.offset) { index, output in
                HStack(spacing: 10) {
                    Circle()
                        .fill(currentArchetype.accentColor)
                        .frame(width: 6, height: 6)

                    Text(output.0)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(currentArchetype.accentColor)
                        .frame(width: 80, alignment: .leading)

                    Text(output.1)
                        .font(.system(size: 13))
                        .foregroundStyle(PrismTheme.textPrimary)
                        .lineLimit(1)

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(PrismTheme.glass)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(currentArchetype.accentColor.opacity(0.3), lineWidth: 0.5)
                )
                .opacity(showBeams ? 1 : 0)
                .offset(y: showBeams ? 0 : 10)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.8)
                        .delay(Double(index) * 0.1),
                    value: showBeams
                )
            }
        }
    }

    // MARK: - Actions

    private func handleTap() {
        guard showNav else { return }

        if phase != .complete {
            // Speed up current animation
            return
        }

        // Move to next archetype or show continue
        if currentArchetypeIndex < archetypes.count - 1 {
            moveToNextArchetype()
        } else if !showContinue {
            withAnimation(.easeOut(duration: 0.4)) {
                showContinue = true
            }
        }
    }

    private func moveToNextArchetype() {
        // Reset state
        withAnimation(.easeOut(duration: 0.2)) {
            showInput = false
            showPrism = false
            showBeams = false
            showArchetype = false
            phase = .idle
        }

        // Change archetype
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            await MainActor.run {
                currentArchetypeIndex += 1
                runTransformation()
            }
        }
    }

    private func startSequence() {
        Task {
            // Show header
            try? await Task.sleep(for: .seconds(0.3))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.4)) {
                    showHeader = true
                }
            }

            // Show nav
            try? await Task.sleep(for: .seconds(0.4))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.4)) {
                    showNav = true
                }
            }

            // Run first transformation
            try? await Task.sleep(for: .seconds(0.3))
            await MainActor.run {
                runTransformation()
            }
        }
    }

    private func runTransformation() {
        Task {
            // Show archetype name
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showArchetype = true
                    phase = .idle
                }
            }

            // Show input
            try? await Task.sleep(for: .seconds(0.4))
            await MainActor.run {
                phase = .inputEntering
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showInput = true
                }
                PrismHaptics.tick()
            }

            // Show prism (transforming)
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run {
                phase = .transforming
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showPrism = true
                }
                PrismHaptics.buttonPress()
            }

            // Show outputs
            try? await Task.sleep(for: .seconds(0.6))
            await MainActor.run {
                phase = .outputRevealing
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showBeams = true
                }
                PrismHaptics.success()
            }

            // Mark complete
            try? await Task.sleep(for: .seconds(0.4))
            await MainActor.run {
                phase = .complete
            }
        }
    }
}

#Preview {
    OnboardingRevealView {
        print("Complete!")
    }
}
