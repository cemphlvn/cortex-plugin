import SwiftUI

/// Step between Void and Demo: Explain I → PRISM → O
/// Visual metaphor: light entering prism, refracting into colored beams
struct OnboardingConceptView: View {
    var onComplete: () -> Void

    // Animation state
    @State private var phase: ConceptPhase = .idle
    @State private var showText1 = false
    @State private var showInput = false
    @State private var showPrism = false
    @State private var showBeams = false
    @State private var showText2 = false
    @State private var showContinue = false

    private enum ConceptPhase {
        case idle
        case inputEntering
        case prismGlowing
        case beamsRefracting
        case complete
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Intro text
                VStack(spacing: 8) {
                    Text("HOW IT WORKS")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrismTheme.textTertiary)
                        .tracking(3)
                        .opacity(showText1 ? 1 : 0)

                    Text("Light enters. Color emerges.")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(.white)
                        .opacity(showText1 ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: showText1)
                }

                // The I → PRISM → O visualization
                conceptDiagram
                    .padding(.vertical, 40)

                // Explanation text
                VStack(spacing: 16) {
                    Text("Your input is the light.")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(PrismTheme.textSecondary)
                        .opacity(showText2 ? 1 : 0)

                    Text("A Prism transforms it into structured insight.")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .opacity(showText2 ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.15), value: showText2)

                    Text("Prisms can be anything—\neven a poem generator.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(PrismTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .opacity(showText2 ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.3), value: showText2)
                }
                .padding(.horizontal, 32)

                Spacer()

                // Continue button
                if showContinue {
                    Button(action: onComplete) {
                        Text("Try it")
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
        }
        .onAppear {
            startSequence()
        }
    }

    // MARK: - Concept Diagram

    private var conceptDiagram: some View {
        HStack(spacing: 0) {
            // INPUT side - the "I"
            inputElement
                .frame(width: 80)
                .opacity(showInput ? 1 : 0)
                .offset(x: showInput ? 0 : -20)

            // Light beam traveling to prism
            lightBeamIn
                .frame(width: 40)
                .opacity(phase == .inputEntering || phase == .prismGlowing || phase == .beamsRefracting || phase == .complete ? 1 : 0)

            // PRISM in center
            prismElement
                .frame(width: 100)
                .opacity(showPrism ? 1 : 0)
                .scaleEffect(showPrism ? 1 : 0.8)

            // Refracted beams traveling out
            lightBeamsOut
                .frame(width: 60)
                .opacity(showBeams ? 1 : 0)

            // OUTPUT side - the "O" (beams)
            outputElement
                .frame(width: 80)
                .opacity(showBeams ? 1 : 0)
                .offset(x: showBeams ? 0 : 20)
        }
    }

    // MARK: - Input Element (I)

    private var inputElement: some View {
        VStack(spacing: 8) {
            // Glowing white orb representing input
            ZStack {
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .blur(radius: 10)

                Circle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
                    .shadow(color: .white.opacity(0.8), radius: 8)
            }

            Text("INPUT")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundStyle(PrismTheme.textTertiary)
        }
    }

    // MARK: - Light Beam In

    private var lightBeamIn: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
            }
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(0.8), .white.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .blur(radius: 1)
        }
        .frame(height: 80)
    }

    // MARK: - Prism Element

    private var prismElement: some View {
        ZStack {
            // Spectral glow when active
            if phase == .prismGlowing || phase == .beamsRefracting || phase == .complete {
                TriangleSpectralRing(
                    intensity: phase == .complete ? 0.9 : 0.6,
                    lineWidth: 2
                )
                .frame(width: 90, height: 90)
            }

            // The prism triangle
            TrianglePrism()
                .fill(PrismTheme.glass)
                .frame(width: 70, height: 70)
                .overlay(
                    TrianglePrism()
                        .strokeBorder(
                            phase == .prismGlowing || phase == .beamsRefracting || phase == .complete
                                ? Color.clear
                                : PrismTheme.border,
                            lineWidth: 1
                        )
                )

            // Label
            VStack {
                Spacer().frame(height: 85)
                Text("PRISM")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(PrismTheme.textTertiary)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: phase)
    }

    // MARK: - Light Beams Out (refracted)

    private var lightBeamsOut: some View {
        GeometryReader { geo in
            let centerY = geo.size.height / 2
            let colors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple]
            let spread: CGFloat = 4

            ForEach(0..<colors.count, id: \.self) { i in
                let offset = CGFloat(i - 3) * spread
                Path { path in
                    path.move(to: CGPoint(x: 0, y: centerY))
                    path.addLine(to: CGPoint(x: geo.size.width, y: centerY + offset))
                }
                .stroke(
                    colors[i],
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .blur(radius: 0.5)
                .opacity(showBeams ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(Double(i) * 0.05), value: showBeams)
            }
        }
        .frame(height: 80)
    }

    // MARK: - Output Element (O / Beams)

    private var outputElement: some View {
        VStack(spacing: 8) {
            // Rainbow beam dots
            VStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    HStack(spacing: 3) {
                        let colors: [[Color]] = [
                            [.red, .orange],
                            [.yellow, .green, .cyan],
                            [.blue, .purple]
                        ]
                        ForEach(colors[i], id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .opacity(showBeams ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(Double(i) * 0.1), value: showBeams)
                }
            }

            Text("OUTPUT")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundStyle(PrismTheme.textTertiary)
        }
    }

    // MARK: - Animation Sequence

    private func startSequence() {
        Task {
            // Show header text
            try? await Task.sleep(for: .seconds(0.3))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.5)) {
                    showText1 = true
                }
            }

            // Show input element
            try? await Task.sleep(for: .seconds(0.6))
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showInput = true
                    phase = .inputEntering
                }
                PrismHaptics.tick()
            }

            // Show prism
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showPrism = true
                    phase = .prismGlowing
                }
                PrismHaptics.buttonPress()
            }

            // Show refracted beams
            try? await Task.sleep(for: .seconds(0.6))
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showBeams = true
                    phase = .beamsRefracting
                }
                PrismHaptics.success()
            }

            // Show explanation text
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run {
                phase = .complete
                withAnimation(.easeOut(duration: 0.5)) {
                    showText2 = true
                }
            }

            // Show continue button
            try? await Task.sleep(for: .seconds(0.8))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.4)) {
                    showContinue = true
                }
            }
        }
    }
}

#Preview {
    OnboardingConceptView {
        print("Complete!")
    }
}
