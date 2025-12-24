import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BeamOutputView: View {
    let beam: BeamOutput
    let spec: BeamSpec?
    var index: Int = 0

    @State private var isVisible = false
    @State private var showSweep = false

    /// Delay for this beam's entrance
    private var entranceDelay: Double {
        Double(index) * PrismAnimation.beamStaggerDelay
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Beam header
            HStack {
                Text(spec?.title ?? beam.id)
                    .font(.headline)
                    .foregroundStyle(PrismTheme.textPrimary)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .darkGlassCard()
        .overlay {
            // Light sweep on reveal
            if showSweep {
                LightSweep(delay: 0)
                    .clipShape(RoundedRectangle(cornerRadius: PrismTheme.cardRadius))
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)
        .onAppear {
            // Staggered entrance
            withAnimation(PrismAnimation.entrance.delay(entranceDelay)) {
                isVisible = true
            }
            // Light sweep after entrance
            Task {
                try? await Task.sleep(for: .seconds(entranceDelay + 0.1))
                await MainActor.run { showSweep = true }
                try? await Task.sleep(for: .seconds(0.6))
                await MainActor.run { showSweep = false }
            }
        }
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

    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Field label with copy button
            HStack {
                Text(fieldLabel)
                    .font(.caption)
                    .foregroundStyle(PrismTheme.textTertiary)
                    .textCase(.uppercase)

                Spacer(minLength: 8)

                copyButton
            }

            // Value
            valueView
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    private var copyButton: some View {
        Button {
            copyToClipboard()
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.caption)
                .foregroundStyle(copied ? PrismTheme.success : PrismTheme.textTertiary)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: copied)
    }

    private func copyToClipboard() {
        let textToCopy: String
        switch field.value {
        case .string(let text):
            textToCopy = text
        case .stringArray(let items):
            textToCopy = items.joined(separator: ", ")
        }

        #if canImport(UIKit)
        UIPasteboard.general.string = textToCopy
        #endif

        PrismHaptics.copy()
        copied = true

        // Reset after delay
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run {
                copied = false
            }
        }
    }

    @ViewBuilder
    private var valueView: some View {
        switch field.value {
        case .string(let text):
            Text(text)
                .font(.body)
                .foregroundStyle(PrismTheme.textPrimary)
                .textSelection(.enabled)

        case .stringArray(let items):
            if items.isEmpty {
                Text("—")
                    .foregroundStyle(PrismTheme.textSecondary)
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
            .foregroundStyle(PrismTheme.textPrimary)
            .fixedSize(horizontal: false, vertical: true) // Wrap text, don't expand horizontally
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

/// Flow layout for tags (wraps to next line)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        let maxWidth = proposal.width ?? bounds.width

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(width: maxWidth, height: nil)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? 300 // Fallback to reasonable width
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            // Measure with constrained width so text wraps
            let size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))

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

        return (CGSize(width: min(maxX, maxWidth), height: currentY + lineHeight), positions)
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
    .background(PrismTheme.background)
}
