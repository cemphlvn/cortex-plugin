import SwiftUI

/// Step 1: The Awakening
/// Pure theater - from void to light to prism
struct OnboardingVoidView: View {
    var onComplete: () -> Void

    // Animation phases
    @State private var phase: AwakeningPhase = .void
    @State private var textPhases: [CinematicText.TextPhase] = Array(repeating: .hidden, count: 5)
    @State private var burstPhase: SpectrumBurst.BurstPhase = .waiting
    @State private var showContinue = false
    @State private var showSkip = false

    private enum AwakeningPhase {
        case void
        case spark
        case breathing
        case tension
        case question
        case burst
        case complete
    }

    var body: some View {
        ZStack {
            // Pure black void
            Color.black.ignoresSafeArea()

            // Central content
            VStack(spacing: 40) {
                Spacer()

                // Light & burst area
                ZStack {
                    // The spark (phases: spark, breathing, tension)
                    if phase == .spark || phase == .breathing || phase == .tension || phase == .question {
                        LightSpark(
                            size: phase == .question ? 6 : 4,
                            glowRadius: phase == .question ? 40 : 20,
                            isBreathing: phase == .breathing,
                            isFlickering: phase == .tension
                        )
                        .scaleEffect(phase == .question ? 1.5 : 1)
                        .animation(.easeInOut(duration: 0.5), value: phase)
                    }

                    // Spectrum burst (phase: burst, complete)
                    if phase == .burst || phase == .complete {
                        SpectrumBurst(phase: $burstPhase) {
                            phase = .complete
                        }
                    }
                }
                .frame(height: 200)

                // Text area
                VStack(spacing: 16) {
                    // Text 0: "Chaos."
                    CinematicText(
                        text: "Chaos.",
                        font: .system(size: 32, weight: .ultraLight),
                        tracking: 6,
                        phase: $textPhases[0]
                    )

                    // Text 1-3: cycling descriptions
                    ZStack {
                        CinematicText(
                            text: "Scattered thoughts.",
                            font: .system(size: 20, weight: .light),
                            tracking: 2,
                            phase: $textPhases[1]
                        )
                        CinematicText(
                            text: "Raw questions.",
                            font: .system(size: 20, weight: .light),
                            tracking: 2,
                            phase: $textPhases[2]
                        )
                        CinematicText(
                            text: "Unstructured data.",
                            font: .system(size: 20, weight: .light),
                            tracking: 2,
                            phase: $textPhases[3]
                        )
                    }

                    // Text 4: "What if you could focus it?"
                    CinematicText(
                        text: "What if you could focus it?",
                        font: .system(size: 22, weight: .regular),
                        tracking: 1,
                        phase: $textPhases[4]
                    )
                    .padding(.top, 20)
                }
                .frame(height: 120)

                Spacer()

                // Continue button
                if showContinue {
                    Button(action: onComplete) {
                        Text("Continue")
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

                Spacer().frame(height: 60)
            }
            .padding(.horizontal, 40)

            // Skip button (top right)
            if showSkip {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onComplete) {
                            Text("Skip")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(PrismTheme.textTertiary)
                        }
                        .padding(.trailing, 24)
                        .padding(.top, 16)
                    }
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            startSequence()
        }
    }

    private func startSequence() {
        Task {
            // Show skip after brief delay
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.3)) {
                    showSkip = true
                }
            }
        }

        Task {
            // Phase 1: Void → Spark (0.5s)
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    phase = .spark
                }
                PrismHaptics.tick()
            }

            // Phase 2: Spark → Breathing (0.5s)
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run {
                phase = .breathing
            }

            // Text 0: "Chaos." enters
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run { textPhases[0] = .entering }

            // Hold, then exit
            try? await Task.sleep(for: .seconds(1.2))
            await MainActor.run { textPhases[0] = .exiting }

            // Phase 3: Tension + cycling text
            try? await Task.sleep(for: .seconds(0.4))
            await MainActor.run { phase = .tension }

            // Text 1: "Scattered thoughts."
            await MainActor.run { textPhases[1] = .entering }
            try? await Task.sleep(for: .seconds(1.0))
            await MainActor.run { textPhases[1] = .exiting }

            // Text 2: "Raw questions."
            try? await Task.sleep(for: .seconds(0.3))
            await MainActor.run { textPhases[2] = .entering }
            try? await Task.sleep(for: .seconds(1.0))
            await MainActor.run { textPhases[2] = .exiting }

            // Text 3: "Unstructured data."
            try? await Task.sleep(for: .seconds(0.3))
            await MainActor.run { textPhases[3] = .entering }
            try? await Task.sleep(for: .seconds(1.0))
            await MainActor.run { textPhases[3] = .exiting }

            // Phase 4: The question
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run {
                phase = .question
                PrismHaptics.buttonPress()
            }

            try? await Task.sleep(for: .seconds(0.3))
            await MainActor.run { textPhases[4] = .entering }

            // Hold on the question
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run { textPhases[4] = .exiting }

            // Phase 5: The burst
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run {
                phase = .burst
                burstPhase = .exploding
            }

            // Wait for burst to complete, then show continue
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.4)) {
                    showContinue = true
                }
            }
        }
    }
}

#Preview {
    OnboardingVoidView {
        print("Complete!")
    }
}
