import SwiftUI

/// Skeleton card for a beam before output arrives
/// Dark glass style with subtle placeholders
struct BeamSlotView: View {
    let spec: BeamSpec

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Beam title
            Text(spec.title)
                .font(.headline)
                .foregroundStyle(PrismTheme.textSecondary)

            // Placeholder fields
            ForEach(spec.fields, id: \.key) { field in
                VStack(alignment: .leading, spacing: 6) {
                    Text(fieldLabel(for: field))
                        .font(.caption)
                        .foregroundStyle(PrismTheme.textTertiary)
                        .textCase(.uppercase)

                    // Skeleton content based on type
                    skeletonContent(for: field)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .darkGlassCard()
    }

    // MARK: - Helpers

    private func fieldLabel(for field: BeamFieldSpec) -> String {
        // Extract first sentence from guide, max 40 chars
        let guide = field.guide
        if let dotIndex = guide.firstIndex(of: ".") {
            let sentence = String(guide[..<dotIndex])
            return sentence.count <= 40 ? sentence : String(sentence.prefix(37)) + "..."
        }
        return guide.count <= 40 ? guide : String(guide.prefix(37)) + "..."
    }

    @ViewBuilder
    private func skeletonContent(for field: BeamFieldSpec) -> some View {
        switch field.valueType {
        case .string:
            // Single line placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(PrismTheme.border)
                .frame(height: 18)
                .frame(maxWidth: 200)

        case .stringArray:
            // Multiple tag placeholders
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(PrismTheme.border)
                        .frame(width: 56, height: 24)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        BeamSlotView(spec: BeamSpec(
            id: "caption",
            title: "Caption",
            description: "Main output",
            fields: [
                BeamFieldSpec(key: "text", guide: "The caption text.", valueType: .string)
            ]
        ))

        BeamSlotView(spec: BeamSpec(
            id: "tags",
            title: "Hashtags",
            description: "Related tags",
            fields: [
                BeamFieldSpec(key: "tags", guide: "Relevant hashtags.", valueType: .stringArray)
            ]
        ))
    }
    .padding()
    .background(PrismTheme.background)
}
