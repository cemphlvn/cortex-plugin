import SwiftUI

/// Full-screen edit view for modifying a PrismDefinition
struct PrismEditView: View {
    let prism: PrismDefinition
    let onSave: (PrismDefinition) -> Void

    @Environment(\.dismiss) private var dismiss

    // Editable state
    @State private var name: String
    @State private var instructions: String
    @State private var inputTitle: String
    @State private var inputDescription: String
    @State private var exampleInput: String
    @State private var beams: [EditableBeam]

    // Help sheet states
    @State private var showingHelp: HelpTopic?

    private let beamColors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple]

    init(prism: PrismDefinition, onSave: @escaping (PrismDefinition) -> Void) {
        self.prism = prism
        self.onSave = onSave
        _name = State(initialValue: prism.name)
        _instructions = State(initialValue: prism.instructions)
        _inputTitle = State(initialValue: prism.incidentBeam.title ?? "")
        _inputDescription = State(initialValue: prism.incidentBeam.description)
        _exampleInput = State(initialValue: prism.exampleInput ?? "")
        _beams = State(initialValue: prism.refractedBeams.map { EditableBeam(from: $0) })
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !inputDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !beams.isEmpty &&
        beams.allSatisfy { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Outputs (Most Important - First)
                outputsSection

                // MARK: - Behavior
                behaviorSection

                // MARK: - Input
                inputSection

                // MARK: - Identity
                identitySection
            }
            .padding()
        }
        .background(PrismTheme.background)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(PrismTheme.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(PrismTheme.textSecondary)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .fontWeight(.semibold)
                .foregroundStyle(isValid ? .white : PrismTheme.textTertiary)
                .disabled(!isValid)
            }
        }
        .sheet(item: $showingHelp) { topic in
            HelpSheet(topic: topic)
        }
    }

    // MARK: - Outputs Section

    private var outputsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                icon: "sparkles",
                title: "Outputs",
                subtitle: "What the Prism generates",
                onHelp: { showingHelp = .outputs }
            )

            VStack(spacing: 12) {
                ForEach(Array(beams.enumerated()), id: \.element.id) { index, _ in
                    BeamEditCard(
                        beam: $beams[index],
                        color: beamColors[index % beamColors.count]
                    )
                }
            }
        }
    }

    // MARK: - Behavior Section

    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                icon: "brain.head.profile",
                title: "Behavior",
                subtitle: "How AI processes your input",
                onHelp: { showingHelp = .behavior }
            )

            TextEditor(text: $instructions)
                .font(.body)
                .foregroundStyle(PrismTheme.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120)
                .padding(12)
                .background(PrismTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(PrismTheme.border, lineWidth: 0.5)
                )
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                icon: "arrow.right.circle",
                title: "Input",
                subtitle: "What user provides",
                onHelp: { showingHelp = .input }
            )

            VStack(spacing: 0) {
                // Label
                EditField(
                    label: "Label",
                    placeholder: "e.g. Meeting Notes",
                    text: $inputTitle
                )

                Divider()
                    .background(PrismTheme.border)

                // Description
                EditField(
                    label: "Description",
                    placeholder: "What to enter...",
                    text: $inputDescription,
                    isMultiline: true
                )

                Divider()
                    .background(PrismTheme.border)

                // Example
                EditField(
                    label: "Example",
                    placeholder: "e.g. Team sync on Monday...",
                    text: $exampleInput,
                    isSecondary: true
                )
            }
            .background(PrismTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(PrismTheme.border, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Identity Section

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                icon: "tag",
                title: "Identity",
                subtitle: "Name shown in collection",
                onHelp: nil
            )

            TextField("Name", text: $name)
                .font(.body)
                .foregroundStyle(PrismTheme.textPrimary)
                .padding(12)
                .background(PrismTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(PrismTheme.border, lineWidth: 0.5)
                )
        }
    }

    // MARK: - Save

    private func save() {
        let updated = PrismDefinition(
            id: prism.id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            instructions: instructions.trimmingCharacters(in: .whitespacesAndNewlines),
            incidentBeam: IncidentBeamSpec(
                type: prism.incidentBeam.type,
                title: inputTitle.isEmpty ? nil : inputTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                description: inputDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            ),
            refractedBeams: beams.map { $0.toBeamSpec() },
            version: prism.version + 1,
            exampleInput: exampleInput.isEmpty ? nil : exampleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        onSave(updated)
        dismiss()
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    let onHelp: (() -> Void)?

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(PrismTheme.textTertiary)
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(PrismTheme.textPrimary)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(PrismTheme.textTertiary)
            }

            Spacer()

            if let onHelp {
                Button(action: onHelp) {
                    Image(systemName: "questionmark.circle")
                        .font(.body)
                        .foregroundStyle(PrismTheme.textTertiary)
                }
            }
        }
    }
}

// MARK: - Edit Field

private struct EditField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isMultiline: Bool = false
    var isSecondary: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(PrismTheme.textTertiary)
                .padding(.top, 12)
                .padding(.horizontal, 12)

            if isMultiline {
                TextField(placeholder, text: $text, axis: .vertical)
                    .font(.body)
                    .foregroundStyle(isSecondary ? PrismTheme.textSecondary : PrismTheme.textPrimary)
                    .lineLimit(2...4)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            } else {
                TextField(placeholder, text: $text)
                    .font(.body)
                    .foregroundStyle(isSecondary ? PrismTheme.textSecondary : PrismTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
        }
    }
}

// MARK: - Beam Edit Card

private struct BeamEditCard: View {
    @Binding var beam: EditableBeam
    let color: Color
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)

                    TextField("Output title", text: $beam.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(PrismTheme.textPrimary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(PrismTheme.textTertiary)
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .background(PrismTheme.border)

                // Fields
                VStack(spacing: 0) {
                    ForEach(Array(beam.fields.enumerated()), id: \.element.id) { index, _ in
                        if index > 0 {
                            Divider()
                                .background(PrismTheme.border)
                                .padding(.leading, 12)
                        }
                        FieldEditRow(field: $beam.fields[index])
                    }
                }
            }
        }
        .background(PrismTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Field Edit Row

private struct FieldEditRow: View {
    @Binding var field: EditableField

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Key + type
            HStack {
                Text(field.key)
                    .font(.caption.monospaced())
                    .foregroundStyle(PrismTheme.textTertiary)

                Spacer()

                Text(field.valueType == .string ? "text" : "list")
                    .font(.caption2)
                    .foregroundStyle(PrismTheme.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(PrismTheme.glass)
                    .clipShape(Capsule())
            }

            // Guide (editable)
            TextField("Field description", text: $field.guide, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(PrismTheme.textSecondary)
                .lineLimit(1...3)
        }
        .padding(12)
    }
}

// MARK: - Editable Models

private struct EditableBeam: Identifiable {
    let id: String
    var title: String
    var fields: [EditableField]

    init(from spec: BeamSpec) {
        self.id = spec.id
        self.title = spec.title
        self.fields = spec.fields.map { EditableField(from: $0) }
    }

    func toBeamSpec() -> BeamSpec {
        BeamSpec(
            id: id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: nil,
            fields: fields.map { $0.toFieldSpec() }
        )
    }
}

private struct EditableField: Identifiable {
    let id: String
    let key: String
    var guide: String
    let valueType: BeamValueType

    init(from spec: BeamFieldSpec) {
        self.id = spec.key
        self.key = spec.key
        self.guide = spec.guide
        self.valueType = spec.valueType
    }

    func toFieldSpec() -> BeamFieldSpec {
        BeamFieldSpec(
            key: key,
            guide: guide.trimmingCharacters(in: .whitespacesAndNewlines),
            valueType: valueType
        )
    }
}

// MARK: - Help Topics

private enum HelpTopic: String, Identifiable {
    case outputs
    case behavior
    case input

    var id: String { rawValue }

    var title: String {
        switch self {
        case .outputs: return "Outputs"
        case .behavior: return "Behavior"
        case .input: return "Input"
        }
    }

    var explanation: String {
        switch self {
        case .outputs:
            return """
            Outputs define what your Prism generates. Each output section (like "Summary" or "Action Items") contains fields that the AI fills in.

            You can edit:
            • Section titles - what appears as headers
            • Field descriptions - guides the AI on what to generate

            The field keys and types are fixed to maintain consistency.
            """
        case .behavior:
            return """
            Behavior is the core instruction that tells the AI how to process your input. Think of it as the "brain" of your Prism.

            Good behaviors are:
            • Specific about the task
            • Clear about the output style
            • Include any constraints or rules

            Example: "Extract action items from meeting notes. Each action should include who is responsible and the deadline if mentioned."
            """
        case .input:
            return """
            Input defines what the user provides to your Prism.

            • Label - Short name (e.g., "Meeting Notes")
            • Description - What to enter
            • Example - Placeholder showing sample input

            A good example helps users understand exactly what to type.
            """
        }
    }
}

// MARK: - Help Sheet

private struct HelpSheet: View {
    let topic: HelpTopic
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(topic.explanation)
                        .font(.body)
                        .foregroundStyle(PrismTheme.textSecondary)
                }
                .padding()
            }
            .background(PrismTheme.background)
            .navigationTitle(topic.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrismEditView(
            prism: PrismDefinition(
                name: "Meeting Notes",
                instructions: "Extract action items and key decisions from meeting transcript",
                incidentBeam: IncidentBeamSpec(
                    type: "string",
                    title: "Transcript",
                    description: "Paste your meeting notes"
                ),
                refractedBeams: [
                    BeamSpec(id: "summary", title: "Summary", fields: [
                        BeamFieldSpec(key: "key_points", guide: "Main discussion points", valueType: .stringArray)
                    ]),
                    BeamSpec(id: "actions", title: "Action Items", fields: [
                        BeamFieldSpec(key: "tasks", guide: "Tasks to complete", valueType: .stringArray),
                        BeamFieldSpec(key: "owners", guide: "Who is responsible", valueType: .stringArray)
                    ])
                ],
                exampleInput: "Team sync on Monday..."
            )
        ) { _ in }
    }
    .preferredColorScheme(.dark)
}
