import SwiftUI

/// Step 3: The Showcase
/// Diverse examples + pre-answered questions = pattern recognition
struct OnboardingShowcaseView: View {
    var onComplete: () -> Void

    @State private var currentPage = 0
    @State private var showContent = false

    // Total pages: 5 examples + 3 value props
    private let totalPages = 8

    private let examples: [ShowcaseExample] = [
        ShowcaseExample(
            prismName: "Quick Decision",
            archetype: .analyzer,
            inputSnippet: "Should I take this job offer? Better pay but longer commute, less flexible hours...",
            outputBeams: [
                ("Recommendation", "Consider taking it", .string),
                ("Pros", "Higher salary, Career growth, Better benefits", .list),
                ("Cons", "Longer commute, Less flexibility", .list),
                ("Key Questions", "Remote work policy?, Growth path?", .list)
            ]
        ),
        ShowcaseExample(
            prismName: "Caption Creator",
            archetype: .generator,
            inputSnippet: "sunset at the beach with old friends, first time together in 5 years",
            outputBeams: [
                ("Caption", "Some sunsets are better measured in friendships than colors.", .string),
                ("Hashtags", "#reunion #beachvibes #friendship", .list),
                ("Alt Version", "5 years apart. One sunset to remember.", .string)
            ]
        ),
        ShowcaseExample(
            prismName: "Meeting Notes",
            archetype: .transformer,
            inputSnippet: "ok so we talked about the Q3 launch, Sarah said we need more testing, John wants to push it anyway, deadline is Sept 15...",
            outputBeams: [
                ("Summary", "Q3 launch timeline discussion with testing concerns", .string),
                ("Action Items", "Extend testing phase, Review Sept 15 deadline", .list),
                ("Decisions", "Pending: launch date approval", .string),
                ("Owners", "Sarah: testing, John: stakeholder alignment", .list)
            ]
        ),
        ShowcaseExample(
            prismName: "Email Tone Check",
            archetype: .analyzer,
            inputSnippet: "Hey, I noticed you didn't finish the report again. This is the third time. We need to talk about this ASAP.",
            outputBeams: [
                ("Tone", "Confrontational / Frustrated", .string),
                ("Issues", "Accusatory language, ALL CAPS, No solution offered", .list),
                ("Suggested Fix", "Express concern without blame, propose support", .string)
            ]
        ),
        ShowcaseExample(
            prismName: "Date Finder",
            archetype: .extractor,
            inputSnippet: "Let's meet Tuesday. The deadline is March 15th but we should finish by the 10th. Conference is April 2-4.",
            outputBeams: [
                ("Dates Found", "Tuesday, March 15th, March 10th, April 2-4", .list),
                ("Events", "Meeting: Tuesday, Deadline: Mar 15, Conference: Apr 2-4", .list),
                ("Soonest", "Tuesday (this week)", .string)
            ]
        )
    ]

    private let valueProps: [ValueProp] = [
        ValueProp(
            headline: "Any text in.",
            subheadline: "Structured insight out.",
            details: "Questions, notes, ideas, drafts, data, messages, transcripts—anything you can type."
        ),
        ValueProp(
            headline: "Create once.",
            subheadline: "Run forever.",
            details: "Unlike asking AI each time, a Prism gives consistent structure. One tap. Same output shape. Always."
        ),
        ValueProp(
            headline: "Private by design.",
            subheadline: nil,
            details: "On-device AI. Your thoughts never leave your phone."
        )
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("SEE WHAT'S POSSIBLE")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrismTheme.textTertiary)
                        .tracking(3)

                    if currentPage < examples.count {
                        Text("Swipe to explore")
                            .font(.system(size: 14))
                            .foregroundStyle(PrismTheme.textTertiary)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 24)
                .opacity(showContent ? 1 : 0)

                // Pager
                TabView(selection: $currentPage) {
                    // Example cards
                    ForEach(Array(examples.enumerated()), id: \.offset) { index, example in
                        ExampleCard(example: example)
                            .tag(index)
                    }

                    // Value prop cards
                    ForEach(Array(valueProps.enumerated()), id: \.offset) { index, prop in
                        ValuePropCard(prop: prop)
                            .tag(examples.count + index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
                .opacity(showContent ? 1 : 0)

                // Page indicator + Continue
                VStack(spacing: 24) {
                    // Custom page dots
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.white : PrismTheme.textTertiary)
                                .frame(width: index == currentPage ? 8 : 6, height: index == currentPage ? 8 : 6)
                                .animation(.easeOut(duration: 0.2), value: currentPage)
                        }
                    }

                    // Continue button (shows on last page or after viewing a few)
                    if currentPage >= examples.count + valueProps.count - 1 || currentPage >= 3 {
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
                }
                .padding(.bottom, 50)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                showContent = true
            }
        }
    }
}

// MARK: - Example Card

struct ExampleCard: View {
    let example: ShowcaseExample

    @State private var showInput = false
    @State private var showPrism = false
    @State private var showOutput = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Input card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 12))
                        Text("INPUT")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1)
                    }
                    .foregroundStyle(PrismTheme.textTertiary)

                    Text(example.inputSnippet)
                        .font(.system(size: 15))
                        .foregroundStyle(PrismTheme.textSecondary)
                        .lineLimit(3)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PrismTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(PrismTheme.border, lineWidth: 0.5)
                )
                .opacity(showInput ? 1 : 0)
                .offset(y: showInput ? 0 : 10)

                // Prism indicator
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(PrismTheme.border)
                        .frame(width: 40, height: 1)

                    HStack(spacing: 8) {
                        Image(systemName: example.archetype.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(example.archetype.accentColor)

                        Text(example.prismName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(PrismTheme.glass)
                            .overlay(
                                Capsule()
                                    .strokeBorder(example.archetype.accentColor.opacity(0.5), lineWidth: 1)
                            )
                    )

                    Rectangle()
                        .fill(PrismTheme.border)
                        .frame(width: 40, height: 1)
                }
                .opacity(showPrism ? 1 : 0)
                .scaleEffect(showPrism ? 1 : 0.8)

                // Output beams
                VStack(spacing: 10) {
                    ForEach(Array(example.outputBeams.enumerated()), id: \.offset) { index, beam in
                        OutputBeamRow(
                            label: beam.0,
                            value: beam.1,
                            type: beam.2,
                            color: example.archetype.accentColor,
                            delay: Double(index) * 0.1
                        )
                        .opacity(showOutput ? 1 : 0)
                        .offset(y: showOutput ? 0 : 10)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1),
                            value: showOutput
                        )
                    }
                }
                .padding(16)
                .background(PrismTheme.glass)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(PrismTheme.border, lineWidth: 0.5)
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            animateIn()
        }
    }

    private func animateIn() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1)) {
            showInput = true
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3)) {
            showPrism = true
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.5)) {
            showOutput = true
        }
    }
}

// MARK: - Output Beam Row

struct OutputBeamRow: View {
    let label: String
    let value: String
    let type: BeamDisplayType
    let color: Color
    var delay: Double = 0

    enum BeamDisplayType {
        case string
        case list
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(color)
                    .textCase(.uppercase)
            }

            switch type {
            case .string:
                Text(value)
                    .font(.system(size: 14))
                    .foregroundStyle(PrismTheme.textPrimary)

            case .list:
                HStack(spacing: 6) {
                    ForEach(value.components(separatedBy: ", ").prefix(3), id: \.self) { item in
                        Text(item)
                            .font(.system(size: 12))
                            .foregroundStyle(PrismTheme.textPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(PrismTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Value Prop Card

struct ValuePropCard: View {
    let prop: ValueProp

    @State private var showContent = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text(prop.headline)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.white)

                if let sub = prop.subheadline {
                    Text(sub)
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(.white)
                }
            }
            .multilineTextAlignment(.center)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            Text(prop.details)
                .font(.system(size: 16))
                .foregroundStyle(PrismTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)

            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

// MARK: - Supporting Types

struct ShowcaseExample {
    let prismName: String
    let archetype: PrismArchetype
    let inputSnippet: String
    let outputBeams: [(String, String, OutputBeamRow.BeamDisplayType)]
}

struct ValueProp {
    let headline: String
    let subheadline: String?
    let details: String
}

// MARK: - Preview

#Preview {
    OnboardingShowcaseView {
        print("Complete!")
    }
}
