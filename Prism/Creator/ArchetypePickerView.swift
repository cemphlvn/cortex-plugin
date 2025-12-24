import SwiftUI

// MARK: - Archetype Picker View (Redesigned)

struct ArchetypePickerView: View {
    let onSelect: (PrismArchetype) -> Void
    let onHelp: () -> Void
    let onNotSure: () -> Void

    @State private var selectedArchetype: PrismArchetype?
    @State private var cardOffsets: [PrismArchetype: CGFloat] = [:]
    @State private var cardOpacities: [PrismArchetype: Double] = [:]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 20)

            // Header - centered
            VStack(spacing: 8) {
                Text("What should it do?")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(PrismTheme.textPrimary)

                Text("Pick a starting point")
                    .font(.subheadline)
                    .foregroundStyle(PrismTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 32)

            // Cards - centered with consistent spacing
            VStack(spacing: 14) {
                ForEach(Array(PrismArchetype.allCases.enumerated()), id: \.element.id) { index, archetype in
                    ArchetypeCard(
                        archetype: archetype,
                        isSelected: selectedArchetype == archetype
                    ) {
                        selectArchetype(archetype, at: index)
                    }
                    .offset(x: cardOffsets[archetype] ?? 0)
                    .opacity(cardOpacities[archetype] ?? 1)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
                .frame(minHeight: 24)

            // Escape hatch - centered
            Button(action: onNotSure) {
                HStack(spacing: 8) {
                    Image(systemName: "text.bubble")
                        .font(.subheadline)
                    Text("Not sure? Describe what you need")
                        .font(.subheadline)
                }
                .foregroundStyle(PrismTheme.textSecondary)
            }
            .padding(.bottom, 32)

            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onHelp) {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(PrismTheme.textSecondary)
                }
            }
        }
    }

    private func selectArchetype(_ archetype: PrismArchetype, at selectedIndex: Int) {
        selectedArchetype = archetype
        PrismHaptics.tick()

        // Staggered exit animation - selected card goes last and differently
        for (index, arch) in PrismArchetype.allCases.enumerated() {
            let delay = Double(index) * 0.04

            if arch == archetype {
                // Selected card: brief pulse then exit
                withAnimation(.easeOut(duration: 0.15).delay(0.12)) {
                    cardOpacities[arch] = 0
                }
            } else {
                // Other cards: staggered slide out
                withAnimation(.easeIn(duration: 0.25).delay(delay)) {
                    cardOffsets[arch] = 300
                    cardOpacities[arch] = 0
                }
            }
        }

        // Trigger navigation after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSelect(archetype)
        }
    }
}

// MARK: - Archetype Card (Refined)

private struct ArchetypeCard: View {
    let archetype: PrismArchetype
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 18) {
                // Icon with glow - centered in fixed width
                ZStack {
                    // Glow
                    Circle()
                        .fill(archetype.accentColor.opacity(0.25))
                        .frame(width: 64, height: 64)
                        .blur(radius: 12)

                    // Icon circle
                    Circle()
                        .fill(PrismTheme.glass)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: archetype.icon)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(archetype.accentColor)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(archetype.accentColor.opacity(0.3), lineWidth: 1)
                        )
                }
                .frame(width: 64)

                // Text content - left aligned
                VStack(alignment: .leading, spacing: 5) {
                    Text(archetype.actionVerb)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(PrismTheme.textPrimary)

                    Text(archetype.transformationHint)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(PrismTheme.textTertiary)
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(PrismTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                archetype.accentColor.opacity(isPressed || isSelected ? 0.5 : 0.15),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: archetype.accentColor.opacity(isPressed ? 0.2 : 0),
                        radius: 20,
                        y: 4
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
            .animation(.easeOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Help Sheet

struct ArchetypeHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("A Prism transforms your input into structured output. Choose based on what you want to get out:")
                        .font(.body)
                        .foregroundStyle(PrismTheme.textSecondary)
                        .padding(.bottom, 8)

                    ForEach(PrismArchetype.allCases) { archetype in
                        HelpRow(archetype: archetype)
                    }
                }
                .padding(20)
            }
            .background(PrismTheme.background)
            .navigationTitle("Understanding Prisms")
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

private struct HelpRow: View {
    let archetype: PrismArchetype

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: archetype.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(archetype.accentColor)

                Text(archetype.actionVerb)
                    .font(.headline)
                    .foregroundStyle(PrismTheme.textPrimary)
            }

            Text(archetype.tagline)
                .font(.subheadline)
                .foregroundStyle(PrismTheme.textSecondary)

            Text(archetype.concreteExample)
                .font(.caption)
                .foregroundStyle(PrismTheme.textTertiary)
                .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(PrismTheme.surface)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ZStack {
            PrismTheme.background.ignoresSafeArea()
            ArchetypePickerView(
                onSelect: { print("Selected: \($0)") },
                onHelp: { print("Help") },
                onNotSure: { print("Not sure") }
            )
        }
        .navigationTitle("Creator")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Help Sheet") {
    ArchetypeHelpSheet()
}
