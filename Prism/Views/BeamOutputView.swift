import SwiftUI

struct BeamOutputView: View {
    let beam: BeamOutput
    let spec: BeamSpec?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Beam header
            HStack {
                Text(spec?.title ?? beam.id)
                    .font(.headline)
                Spacer()
            }

            // Fields (in spec order)
            ForEach(orderedFields) { field in
                FieldOutputView(
                    field: field,
                    spec: spec?.fields.first { $0.key == field.key }
                )
            }
        }
        .padding()
        .background(.fill.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// Fields ordered by spec, falling back to beam order
    private var orderedFields: [FieldOutput] {
        guard let spec else { return beam.fields }

        // Order by spec field order
        return spec.fields.compactMap { fieldSpec in
            beam.fields.first { $0.key == fieldSpec.key }
        }
    }
}

struct FieldOutputView: View {
    let field: FieldOutput
    let spec: BeamFieldSpec?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Field label (from guide or key)
            Text(fieldLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            // Value
            valueView
        }
    }

    private var fieldLabel: String {
        // Extract short label from guide or use key
        if let guide = spec?.guide {
            // Take first sentence or up to period/comma
            let short = guide.prefix(while: { $0 != "." && $0 != "," })
            if short.count < 40 {
                return String(short)
            }
        }
        // Fall back to formatted key
        return field.key.replacingOccurrences(of: "_", with: " ").capitalized
    }

    @ViewBuilder
    private var valueView: some View {
        switch field.value {
        case .string(let text):
            Text(text)
                .font(.body)
                .textSelection(.enabled)

        case .stringArray(let items):
            if items.isEmpty {
                Text("—")
                    .foregroundStyle(.secondary)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(items, id: \.self) { item in
                        TagView(text: item)
                    }
                }
            }
        }
    }
}

struct TagView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.callout)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.fill.tertiary)
            .clipShape(Capsule())
    }
}

/// Flow layout for tags (wraps to next line)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

#Preview {
    VStack {
        BeamOutputView(
            beam: BeamOutput(id: "test", fields: [
                FieldOutput(key: "title", value: .string("A beautiful sunset")),
                FieldOutput(key: "tags", value: .stringArray(["sunset", "nature", "calm"]))
            ]),
            spec: BeamSpec(id: "test", title: "Preview", fields: [
                BeamFieldSpec(key: "title", guide: "Main title", valueType: .string),
                BeamFieldSpec(key: "tags", guide: "Related tags", valueType: .stringArray)
            ])
        )
    }
    .padding()
}
