import SwiftUI
import FoundationModels

/// Step 2: The Demonstration
/// User types a name, gets a personalized acrostic poem
struct OnboardingDemoView: View {
    var onComplete: () -> Void

    // Demo state
    @State private var demoPhase: DemoPhase = .setup
    @State private var nameInput = ""
    @State private var showInput = false
    @State private var showButton = false
    @State private var runState: RunState = .idle
    @State private var showBeams = false
    @State private var showExplanation = false
    @State private var showContinue = false
    @State private var generatedPoem: [String] = []
    @State private var generatedMessage: String = ""
    @State private var errorMessage: String?

    @FocusState private var isInputFocused: Bool

    private enum DemoPhase {
        case setup
        case ready
        case processing
        case revealing
        case revealed
        case explaining
    }

    // The demo prism definition (inline for onboarding)
    private static let demoPrism = PrismDefinition(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Name Poem",
        instructions: """
        You are a poet who creates heartfelt acrostic poems. Given a person's name, create an acrostic poem where:
        - Each line starts with a letter from the name (in order)
        - Each line is a warm, positive sentiment about that person
        - Keep each line short (3-6 words)
        - The poem should feel personal and uplifting
        - Do NOT include the letter as a separate element - integrate it naturally as the first letter of the first word

        Also create a short, warm share message to accompany the poem.
        """,
        incidentBeam: IncidentBeamSpec(
            type: "string",
            title: "Name",
            description: "A person's name"
        ),
        refractedBeams: [
            BeamSpec(
                id: "poem",
                title: "Your Poem",
                description: "Acrostic poem based on the name",
                fields: [
                    BeamFieldSpec(
                        key: "lines",
                        guide: "Array of poem lines, one per letter of the name. Each line should be 3-6 words and start with the corresponding letter.",
                        valueType: .stringArray
                    )
                ]
            ),
            BeamSpec(
                id: "share",
                title: "Share Message",
                description: "A warm message to share with the poem",
                fields: [
                    BeamFieldSpec(
                        key: "message",
                        guide: "A short, warm message (1-2 sentences) to send along with this poem. Include the person's name.",
                        valueType: .string
                    )
                ]
            )
        ],
        version: 1,
        exampleInput: "Emma"
    )

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .onTapGesture {
                    isInputFocused = false
                }

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 50)

                    // Header
                    VStack(spacing: 8) {
                        Text("TRY IT")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(PrismTheme.textTertiary)
                            .tracking(3)

                        Text("Type a friend's name")
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(.white)
                    }
                    .opacity(showInput ? 1 : 0)

                    // The Prism triangle
                    demoPrismTriangle
                        .padding(.vertical, 16)

                    // Name input
                    if showInput {
                        nameInputField
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    // Run button
                    if showButton && !nameInput.isEmpty {
                        PrismButton(
                            state: runState,
                            isEnabled: nameInput.count >= 2,
                            action: runDemo
                        )
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(.red.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // Output beams
                    if showBeams {
                        VStack(spacing: 12) {
                            // Poem beam
                            poemBeamCard

                            // Share message beam
                            shareMessageBeamCard
                        }
                        .padding(.horizontal, 20)
                        .transition(.opacity)
                    }

                    // Explanation
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
            if runState == .running || runState == .revealed {
                TriangleSpectralRing(
                    intensity: runState == .running ? 0.5 : 0.85,
                    lineWidth: runState == .revealed ? 3 : 2
                )
                .frame(width: 104, height: 104)
            }

            if runState == .revealed {
                RefractionBurst()
                    .frame(width: 138, height: 138)
            }

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

    // MARK: - Name Input

    private var nameInputField: some View {
        VStack(spacing: 6) {
            TextField("", text: $nameInput, prompt: Text("Emma").foregroundStyle(PrismTheme.textTertiary))
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($isInputFocused)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(PrismTheme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    isInputFocused ? Color.white.opacity(0.3) : PrismTheme.border,
                                    lineWidth: isInputFocused ? 1.5 : 0.5
                                )
                        )
                )
                .frame(maxWidth: 200)
                .disabled(demoPhase != .ready)
                .opacity(demoPhase == .processing || demoPhase == .revealing ? 0.5 : 1)

            if nameInput.isEmpty {
                Text("or try: Max, Luna, Alex")
                    .font(.system(size: 13))
                    .foregroundStyle(PrismTheme.textTertiary)
            }
        }
    }

    // MARK: - Poem Beam Card

    private var poemBeamCard: some View {
        BeamCardWrapper(title: "Your Poem", index: 0) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(generatedPoem.enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .top, spacing: 0) {
                        // First letter highlighted
                        if let firstChar = line.first {
                            Text(String(firstChar))
                                .font(.system(size: 17, weight: .semibold, design: .serif))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        Text(String(line.dropFirst()))
                            .font(.system(size: 17, weight: .regular, design: .serif))
                            .foregroundStyle(PrismTheme.textPrimary)
                    }
                }
            }
        }
    }

    // MARK: - Share Message Beam Card

    private var shareMessageBeamCard: some View {
        BeamCardWrapper(title: "Share Message", index: 1) {
            Text(generatedMessage)
                .font(.system(size: 15))
                .foregroundStyle(PrismTheme.textPrimary)
                .italic()
        }
    }

    // MARK: - Explanation View

    private var explanationView: some View {
        VStack(spacing: 16) {
            Text("One name in. Personalized poem out.")
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(PrismTheme.textSecondary)
                .multilineTextAlignment(.center)

            Text("That's a Prism.")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)

            Text("Any input. Structured output. Every time.")
                .font(.system(size: 14))
                .foregroundStyle(PrismTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
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
        guard demoPhase == .ready, nameInput.count >= 2 else { return }

        isInputFocused = false
        demoPhase = .processing
        runState = .running
        errorMessage = nil
        PrismHaptics.buttonPress()

        let name = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            // Try to use the real AI model
            let result = await generateWithModel(name: name)

            await MainActor.run {
                switch result {
                case .success(let outputs):
                    // Parse the outputs
                    if let poemOutput = outputs.first(where: { $0.id == "poem" }),
                       let linesField = poemOutput.fields.first(where: { $0.key == "lines" }),
                       case .stringArray(let lines) = linesField.value {
                        generatedPoem = lines
                    }

                    if let shareOutput = outputs.first(where: { $0.id == "share" }),
                       let messageField = shareOutput.fields.first(where: { $0.key == "message" }),
                       case .string(let message) = messageField.value {
                        generatedMessage = message
                    }

                case .failure:
                    // Fallback to local generator
                    generatedPoem = AcrosticGenerator.generate(for: name)
                    generatedMessage = "Hey \(name.capitalized)! I made this poem just for you. Hope it makes you smile!"
                }

                demoPhase = .revealing
                runState = .revealed
                PrismHaptics.success()

                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showBeams = true
                }
            }

            try? await Task.sleep(for: .seconds(1.5))

            await MainActor.run {
                demoPhase = .revealed
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showExplanation = true
                }
            }

            try? await Task.sleep(for: .seconds(0.8))
            await MainActor.run {
                demoPhase = .explaining
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showContinue = true
                }
            }
        }
    }

    @available(iOS 26.0, *)
    private func generateWithModel(name: String) async -> Result<[BeamOutput], Error> {
        // Check model availability
        guard ModelAvailability.shared.status.isAvailable else {
            return .failure(PrismEngine.RunError.modelUnavailable("Model not ready"))
        }

        do {
            let executable = try PrismSchemaCompiler.compile(Self.demoPrism)
            let engine = PrismEngine()
            let outputs = try await engine.run(executable: executable, input: name)
            return .success(outputs)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - Beam Card Wrapper

struct BeamCardWrapper<Content: View>: View {
    let title: String
    var index: Int = 0
    @ViewBuilder var content: Content

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

            content
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
}

// MARK: - Acrostic Generator (Fallback)

enum AcrosticGenerator {
    // Positive, uplifting lines for each letter
    private static let lines: [Character: [String]] = [
        "A": ["Always bringing light to those around", "A heart so warm, a spirit unbound", "Amazing in ways both big and small"],
        "B": ["Brave and bold in all you do", "Brightening days with your point of view", "Beloved friend through and through"],
        "C": ["Caring deeply for everyone you meet", "Clever mind and heart so sweet", "Courage flows through all you do"],
        "D": ["Dreaming big and reaching far", "Dazzling bright like a guiding star", "Dependable, true, just as you are"],
        "E": ["Ever kind and ever true", "Embracing life in all you do", "Extraordinary through and through"],
        "F": ["Full of laughter, full of grace", "Friendship glows upon your face", "Fearless spirit none can replace"],
        "G": ["Generous heart that knows no end", "Genuine soul, a treasured friend", "Growing stronger round each bend"],
        "H": ["Honest heart that shines so bright", "Helping others feel alright", "Hopeful spirit, pure delight"],
        "I": ["Inspiring those you're standing near", "Incredible soul, so true and dear", "Illuminating year by year"],
        "J": ["Joyful spirit, warm and free", "Just the friend we need to see", "Journey on so brilliantly"],
        "K": ["Kind in ways that touch the heart", "Keeping loved ones never apart", "Known for playing such a part"],
        "L": ["Loving deeply, standing tall", "Lifting spirits one and all", "Loyal through both rise and fall"],
        "M": ["Making magic everywhere", "Moments treasured, memories rare", "Moving forward without a care"],
        "N": ["Never giving up the fight", "Noble spirit shining bright", "Nurturing all within your sight"],
        "O": ["Open heart that welcomes all", "Optimistic, standing tall", "Outstanding friend through every call"],
        "P": ["Passionate in all you chase", "Positive energy fills your space", "Patient soul with gentle grace"],
        "Q": ["Quick to laugh and quick to smile", "Quiet strength that goes the mile", "Quality friend of timeless style"],
        "R": ["Radiating warmth and care", "Rare and precious, truly rare", "Rising up beyond compare"],
        "S": ["Shining bright in every room", "Spreading joy and chasing gloom", "Strong and steady, watch them bloom"],
        "T": ["True and faithful to the end", "Thoughtful heart, a cherished friend", "Timeless bond that will not bend"],
        "U": ["Unstoppable in every way", "Uplifting those throughout the day", "Unique in all you do and say"],
        "V": ["Vibrant spirit, burning bright", "Victorious in every fight", "Valued friend, a pure delight"],
        "W": ["Warm and wonderful inside", "Wisdom flows with humble pride", "Wishing stars stand by your side"],
        "X": ["eXtraordinary, that's your name", "eXcelling in your noble aim", "eXceptional in every frame"],
        "Y": ["Youthful spirit, wild and free", "Yearning for what life can be", "You're the best that we can see"],
        "Z": ["Zestful energy you bring", "Zealous in everything", "Zenith of a joyful spring"]
    ]

    static func generate(for name: String) -> [String] {
        let cleanName = name.uppercased().filter { $0.isLetter }
        guard !cleanName.isEmpty else { return ["Enter a name to see the magic!"] }

        var usedIndices: [Character: Int] = [:]
        var poem: [String] = []

        for char in cleanName {
            if let options = lines[char] {
                let index = usedIndices[char] ?? 0
                let line = options[index % options.count]
                poem.append(line)
                usedIndices[char] = index + 1
            } else {
                // Fallback for any unhandled characters
                poem.append("Exceptional in every way")
            }
        }

        return poem
    }
}

#Preview {
    OnboardingDemoView {
        print("Complete!")
    }
}
