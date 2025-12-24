import SwiftUI

/// Step 2: The Demonstration
/// User experiences a real Prism transformation
struct OnboardingDemoView: View {
    var onComplete: () -> Void

    // Demo state
    @State private var demoPhase: DemoPhase = .setup
    @State private var inputText = "Great headphones, amazing sound but battery only lasts 4 hours. Not worth $300."
    @State private var showInput = false
    @State private var showButton = false
    @State private var runState: RunState = .idle
    @State private var showBeams = false
    @State private var showExplanation = false
    @State private var showContinue = false

    // Mock output data (simulates what the model would return)
    private let mockBeams: [(String, [(String, BeamValue)])] = [
        ("Sentiment", [
            ("rating", .string("Mixed")),
            ("confidence", .string("High"))
        ]),
        ("Highlights", [
            ("pros", .stringArray(["Amazing sound quality"])),
            ("cons", .stringArray(["Short battery life", "Overpriced"]))
        ]),
        ("Summary", [
            ("one_liner", .string("Great audio marred by poor battery and high price."))
        ])
    ]

    private enum DemoPhase {
        case setup
        case ready
        case processing
        case revealing
        case revealed
        case explaining
    }

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)

                    // Header text
                    Text("Feed it anything")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(PrismTheme.textSecondary)
                        .tracking(2)
                        .textCase(.uppercase)
                        .opacity(showInput ? 1 : 0)

                    // The Prism triangle (always visible after setup)
                    demoPrismTriangle
                        .padding(.vertical, 20)

                    // Input area
                    if showInput {
                        demoInputCard
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // Run button
                    if showButton {
                        PrismButton(
                            state: runState,
                            isEnabled: !inputText.isEmpty,
                            action: runDemo
                        )
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Output beams
                    if showBeams {
                        VStack(spacing: 12) {
                            ForEach(Array(mockBeams.enumerated()), id: \.offset) { index, beam in
                                MockBeamCard(
                                    title: beam.0,
                                    fields: beam.1,
                                    index: index
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .transition(.opacity)
                    }

                    // Explanation overlay
                    if showExplanation {
                        explanationView
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

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
                        .padding(.top, 20)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }

                    Spacer().frame(height: 60)
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            setupDemo()
        }
    }

    // MARK: - Prism Triangle

    private var demoPrismTriangle: some View {
        ZStack {
            // Spectral ring (only during running/revealed)
            if runState == .running || runState == .revealed {
                TriangleSpectralRing(
                    intensity: runState == .running ? 0.5 : 0.85,
                    lineWidth: runState == .revealed ? 3 : 2
                )
                .frame(width: 104, height: 104)
            }

            // Refraction burst on success
            if runState == .revealed {
                RefractionBurst()
                    .frame(width: 138, height: 138)
            }

            // Glass triangle
            TrianglePrism()
                .fill(PrismTheme.glass)
                .frame(width: 88, height: 88)
                .overlay(
                    TrianglePrism()
                        .strokeBorder(
                            runState == .idle ? PrismTheme.border : Color.clear,
                            lineWidth: 1
                        )
                )
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: runState)
    }

    // MARK: - Input Card

    private var demoInputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("REVIEW TO ANALYZE")
                .font(.caption)
                .foregroundStyle(PrismTheme.textTertiary)
                .tracking(1)

            TextEditor(text: $inputText)
                .font(.body)
                .foregroundStyle(PrismTheme.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80, maxHeight: 120)
                .disabled(demoPhase != .ready)
                .opacity(demoPhase == .processing || demoPhase == .revealing ? 0.3 : 1)
        }
        .padding()
        .background(PrismTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(PrismTheme.border, lineWidth: 0.5)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Explanation View

    private var explanationView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Raw input.")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(PrismTheme.textSecondary)

                Image(systemName: "arrow.down")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        AngularGradient(
                            gradient: Gradient(colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red]),
                            center: .center
                        )
                    )

                Text("Structured insight.")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(PrismTheme.textSecondary)
            }

            Text("That's what a Prism does.")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .padding(.top, 8)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(PrismTheme.glass.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(PrismTheme.border, lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Actions

    private func setupDemo() {
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showInput = true
                }
            }

            try? await Task.sleep(for: .seconds(0.3))
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showButton = true
                    demoPhase = .ready
                }
            }
        }
    }

    private func runDemo() {
        guard demoPhase == .ready else { return }

        demoPhase = .processing
        runState = .running
        PrismHaptics.buttonPress()

        Task {
            // Simulate processing time
            try? await Task.sleep(for: .seconds(1.5))

            await MainActor.run {
                demoPhase = .revealing
                runState = .revealed
                PrismHaptics.success()

                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showBeams = true
                }
            }

            // Wait for beams to appear
            try? await Task.sleep(for: .seconds(1.2))

            await MainActor.run {
                demoPhase = .revealed
            }

            // Show explanation
            try? await Task.sleep(for: .seconds(0.8))
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showExplanation = true
                }
            }

            // Show continue
            try? await Task.sleep(for: .seconds(1.0))
            await MainActor.run {
                demoPhase = .explaining
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showContinue = true
                }
            }
        }
    }
}

// MARK: - Mock Beam Card

/// Simplified beam card for demo (doesn't need real BeamOutput)
struct MockBeamCard: View {
    let title: String
    let fields: [(String, BeamValue)]
    var index: Int = 0

    @State private var isVisible = false
    @State private var showSweep = false

    private var entranceDelay: Double {
        Double(index) * 0.15
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(PrismTheme.textPrimary)

            ForEach(fields, id: \.0) { key, value in
                VStack(alignment: .leading, spacing: 6) {
                    Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                        .foregroundStyle(PrismTheme.textTertiary)
                        .textCase(.uppercase)

                    valueView(for: value)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PrismTheme.glass)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(PrismTheme.border, lineWidth: 0.5)
        )
        .overlay {
            if showSweep {
                LightSweep(delay: 0)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(entranceDelay)) {
                isVisible = true
            }
            Task {
                try? await Task.sleep(for: .seconds(entranceDelay + 0.1))
                await MainActor.run { showSweep = true }
                try? await Task.sleep(for: .seconds(0.6))
                await MainActor.run { showSweep = false }
            }
        }
    }

    @ViewBuilder
    private func valueView(for value: BeamValue) -> some View {
        switch value {
        case .string(let text):
            Text(text)
                .font(.body)
                .foregroundStyle(PrismTheme.textPrimary)

        case .stringArray(let items):
            HStack(spacing: 6) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.callout)
                        .foregroundStyle(PrismTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(PrismTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(PrismTheme.border, lineWidth: 0.5)
                        )
                }
            }
        }
    }
}

#Preview {
    OnboardingDemoView {
        print("Complete!")
    }
}
