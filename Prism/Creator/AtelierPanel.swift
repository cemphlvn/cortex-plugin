import SwiftUI

// MARK: - Atelier Panel (Redesigned)

struct AtelierPanel: View {
    let draft: PrismDefinition?
    let isBuilding: Bool
    let compileStatus: CreatorViewModel.CompileStatus
    let compileError: String?
    let onPrizmate: () -> Void

    @State private var showDetail = false

    private let beamColors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple]

    var body: some View {
        VStack(spacing: 16) {
            // Top: Prism Name + Action
            HStack(alignment: .center) {
                if let name = draft?.name {
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(PrismTheme.textPrimary)
                        .lineLimit(1)
                } else {
                    Text("New Prism")
                        .font(.headline)
                        .foregroundStyle(PrismTheme.textTertiary)
                }

                Spacer()

                actionButton
            }

            // Flow: You provide → ▲ → You get
            Button(action: { if draft != nil { showDetail = true } }) {
                VStack(spacing: 8) {
                    // Labels row (separate from flow for proper alignment)
                    HStack {
                        Text("You provide")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(PrismTheme.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer()
                            .frame(width: 100) // Match center width

                        Text("You get")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(PrismTheme.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    // Flow row: Input → Prism → Outputs (beams aligned to centers)
                    HStack(alignment: .center, spacing: 0) {
                        // Input pill
                        InputPill(title: draft?.incidentBeam.title, hasContent: draft != nil)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Center: beam → prism → beam (fixed width)
                        HStack(spacing: 4) {
                            LightBeam(isActive: isBuilding)
                                .frame(width: 20, height: 2)

                            PrismTriangleSimple(isBuilding: isBuilding, hasContent: draft != nil)
                                .frame(width: 52, height: 52)

                            LightBeam(isActive: isBuilding, isRainbow: true)
                                .frame(width: 20, height: 2)
                        }
                        .frame(width: 100)

                        // Output pills (fixed width, right-aligned)
                        if let beams = draft?.refractedBeams, !beams.isEmpty {
                            OutputBeamPillsVertical(beams: beams, isBuilding: isBuilding)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } else {
                            Text("Your outputs")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(PrismTheme.textTertiary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(PrismTheme.glass)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            // Status hint
            if compileStatus != .ready || draft == nil {
                statusHint
            }
        }
        .padding(16)
        .background(PrismTheme.surface.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(PrismTheme.border, lineWidth: 0.5)
        )
        .sheet(isPresented: $showDetail) {
            if let draft = draft {
                DraftDetailSheet(draft: draft)
            }
        }
    }

    // MARK: - Status Hint

    @ViewBuilder
    private var statusHint: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 5, height: 5)

            Text(statusText)
                .font(.caption2)
                .foregroundStyle(PrismTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusColor: Color {
        switch compileStatus {
        case .idle: return PrismTheme.textTertiary
        case .compiling: return .yellow
        case .refining: return .orange
        case .ready: return .green
        }
    }

    private var statusText: String {
        switch compileStatus {
        case .idle: return "Describe your Prism"
        case .compiling: return "Shaping..."
        case .refining:
            if let error = compileError {
                return error
            }
            return "Try again"
        case .ready: return "Tap to preview"
        }
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        let hasDraft = draft != nil
        let label = hasDraft ? "SAVE" : "PRIZMATE"

        Button(action: onPrizmate) {
            HStack(spacing: 4) {
                Image(systemName: hasDraft ? "checkmark.circle.fill" : "sparkles")
                    .font(.caption)
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isBuilding ? PrismTheme.textTertiary : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isBuilding
                    ? AnyShapeStyle(PrismTheme.glass)
                    : AnyShapeStyle(
                        LinearGradient(
                            colors: hasDraft ? [.green, .cyan] : [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .clipShape(Capsule())
        }
        .disabled(isBuilding)
    }
}

// MARK: - Input Pill (White light - same width as output pills)

struct InputPill: View {
    let title: String?
    let hasContent: Bool

    var body: some View {
        Text(title ?? "Your input")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(hasContent ? .black : PrismTheme.textTertiary)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(width: 110, alignment: .center) // Same width as output pills
            .background(hasContent ? .white : PrismTheme.glass)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Output Beam Pills (Vertical - uniform size, centered stack)

struct OutputBeamPillsVertical: View {
    let beams: [BeamSpec]
    let isBuilding: Bool

    private let colors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple]

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            ForEach(Array(beams.enumerated()), id: \.element.id) { index, beam in
                BeamPillUniform(
                    title: beam.title,
                    color: colors[index % colors.count],
                    delay: Double(index) * 0.08,
                    isAnimating: isBuilding
                )
            }
        }
    }
}

struct BeamPillUniform: View {
    let title: String
    let color: Color
    let delay: Double
    let isAnimating: Bool

    @State private var pulse = false

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(PrismTheme.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(width: 110, alignment: .center) // Fixed width for uniformity
            .background(color.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(color.opacity(0.5), lineWidth: 1)
            )
            .scaleEffect(isAnimating && pulse ? 1.03 : 1.0)
            .opacity(isAnimating ? (pulse ? 1.0 : 0.8) : 1.0)
            .animation(
                isAnimating
                    ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(delay)
                    : .default,
                value: pulse
            )
            .onAppear { pulse = true }
            .onChange(of: isAnimating) { _, newValue in
                pulse = newValue
            }
    }
}

// MARK: - Simple Prism Triangle (centered, bigger)

struct PrismTriangleSimple: View {
    let isBuilding: Bool
    let hasContent: Bool

    @State private var breathe = false

    var body: some View {
        ZStack {
            // Glow behind
            TrianglePrism()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(hasContent ? 0.2 : 0.05), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .frame(width: 50, height: 50)
                .blur(radius: 8)

            // Glass triangle
            TrianglePrism()
                .fill(PrismTheme.glass)
                .frame(width: 42, height: 42)
                .overlay(
                    TrianglePrism()
                        .strokeBorder(PrismTheme.border, lineWidth: 1)
                )

            // Spectral rim
            if isBuilding || hasContent {
                TriangleSpectralRing(
                    intensity: isBuilding ? 1.0 : 0.6,
                    lineWidth: 2
                )
                .frame(width: 48, height: 48)
            }
        }
        .scaleEffect(isBuilding ? (breathe ? 1.05 : 0.95) : 1.0)
        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: breathe)
        .onAppear { breathe = true }
    }
}

// MARK: - Light Beam (Animated Ray)

struct LightBeam: View {
    let isActive: Bool
    var isRainbow: Bool = false

    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base line
                Rectangle()
                    .fill(PrismTheme.border)

                // Traveling light
                Rectangle()
                    .fill(
                        isRainbow
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [.clear, .red, .orange, .yellow, .green, .blue, .purple, .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.8), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: (phase - 0.5) * geo.size.width * 1.5)
                    .opacity(isActive ? 1 : 0.3)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 1.5))
        .onAppear {
            if isActive { startAnimation() }
        }
        .onChange(of: isActive) { _, active in
            if active { startAnimation() }
        }
    }

    private func startAnimation() {
        phase = 0
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            phase = 1
        }
    }
}

// MARK: - Draft Detail Sheet

struct DraftDetailSheet: View {
    let draft: PrismDefinition
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text(draft.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(PrismTheme.textPrimary)

                        if !draft.instructions.isEmpty {
                            Text(draft.instructions)
                                .font(.subheadline)
                                .foregroundStyle(PrismTheme.textSecondary)
                        }
                    }

                    // You provide → You get flow
                    VStack(alignment: .leading, spacing: 20) {
                        // Input
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "text.cursor")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                Text("You provide")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(PrismTheme.textPrimary)
                            }

                            Text(draft.incidentBeam.title ?? draft.incidentBeam.description)
                                .font(.body)
                                .foregroundStyle(PrismTheme.textSecondary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(PrismTheme.glass)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            if let example = draft.exampleInput, !example.isEmpty {
                                Text("e.g. \"\(example)\"")
                                    .font(.caption)
                                    .italic()
                                    .foregroundStyle(PrismTheme.textTertiary)
                                    .padding(.leading, 4)
                            }
                        }

                        // Arrow
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.down")
                                .font(.title3)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            Spacer()
                        }

                        // Outputs
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.subheadline)
                                    .foregroundStyle(.purple)
                                Text("You get")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(PrismTheme.textPrimary)
                            }

                            ForEach(draft.refractedBeams) { beam in
                                OutputBeamCard(beam: beam)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(PrismTheme.background)
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Output Beam Card

struct OutputBeamCard: View {
    let beam: BeamSpec

    /// Convert field guides to simple bullet points
    private var fieldDescriptions: [String] {
        beam.fields.map { field in
            // Clean up the guide text to be more readable
            let guide = field.guide
                .replacingOccurrences(of: "MUST ", with: "")
                .replacingOccurrences(of: "MUST NOT ", with: "Won't ")
            return guide
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section title
            Text(beam.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PrismTheme.textPrimary)

            // Simple bullet list of what's generated
            VStack(alignment: .leading, spacing: 6) {
                ForEach(fieldDescriptions, id: \.self) { description in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(beamColor)
                            .frame(width: 5, height: 5)
                            .padding(.top, 6)

                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(PrismTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PrismTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(beamColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var beamColor: Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple]
        let index = abs(beam.id.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Preview

#Preview("Atelier Panel - Empty") {
    VStack {
        AtelierPanel(
            draft: nil,
            isBuilding: false,
            compileStatus: .idle,
            compileError: nil,
            onPrizmate: {}
        )
    }
    .padding()
    .background(PrismTheme.background)
}

#Preview("Atelier Panel - With Draft") {
    let mockDraft = PrismDefinition(
        name: "Breakfast Ideas",
        instructions: "Generate breakfast ideas from fridge contents",
        incidentBeam: IncidentBeamSpec(type: "string", title: "Fridge Contents", description: "List items in your fridge"),
        refractedBeams: [
            BeamSpec(id: "contents", title: "Fridge Contents", fields: [
                BeamFieldSpec(key: "items", guide: "Parsed list of ingredients", valueType: .stringArray)
            ]),
            BeamSpec(id: "ideas", title: "Breakfast Ideas", fields: [
                BeamFieldSpec(key: "recipes", guide: "Quick breakfast recipes", valueType: .stringArray)
            ])
        ],
        exampleInput: "eggs, milk, bread, cheese"
    )

    VStack {
        AtelierPanel(
            draft: mockDraft,
            isBuilding: false,
            compileStatus: .ready,
            compileError: nil,
            onPrizmate: {}
        )
    }
    .padding()
    .background(PrismTheme.background)
}

#Preview("Draft Detail Sheet") {
    let mockDraft = PrismDefinition(
        name: "Meeting Notes",
        instructions: "Extract action items and key decisions from meeting notes",
        incidentBeam: IncidentBeamSpec(type: "string", title: "Meeting Notes", description: "Paste your meeting transcript"),
        refractedBeams: [
            BeamSpec(id: "summary", title: "Summary", fields: [
                BeamFieldSpec(key: "key_points", guide: "Main discussion points", valueType: .stringArray)
            ]),
            BeamSpec(id: "actions", title: "Action Items", fields: [
                BeamFieldSpec(key: "tasks", guide: "Tasks to be completed", valueType: .stringArray),
                BeamFieldSpec(key: "owners", guide: "Person responsible", valueType: .stringArray)
            ])
        ],
        exampleInput: "Team sync on Monday..."
    )

    DraftDetailSheet(draft: mockDraft)
}
