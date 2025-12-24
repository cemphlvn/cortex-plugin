import SwiftUI

/// Dark premium theme for Prism
/// Rule: black/white baseline, rainbow only as reward
enum PrismTheme {
    // MARK: - Backgrounds

    /// Near-black app background
    static let background = Color(white: 0.06)

    /// Slightly lighter surface for cards
    static let surface = Color(white: 0.10)

    /// Dark glass for elevated elements
    static let glass = Color(white: 0.12)

    /// Subtle border for glass elements
    static let border = Color(white: 0.20)

    // MARK: - Text

    /// Primary text (high contrast)
    static let textPrimary = Color(white: 0.95)

    /// Secondary text
    static let textSecondary = Color(white: 0.60)

    /// Tertiary/hint text
    static let textTertiary = Color(white: 0.40)

    // MARK: - Accents

    /// Error state
    static let error = Color.red.opacity(0.8)

    /// Success indicator (subtle)
    static let success = Color.green.opacity(0.8)

    // MARK: - Shapes

    /// Standard corner radius
    static let cornerRadius: CGFloat = 12

    /// Card corner radius
    static let cardRadius: CGFloat = 16
}

// MARK: - View Modifiers

extension View {
    /// Apply dark glass card style
    func darkGlassCard() -> some View {
        self
            .background(PrismTheme.glass)
            .clipShape(RoundedRectangle(cornerRadius: PrismTheme.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: PrismTheme.cardRadius)
                    .strokeBorder(PrismTheme.border, lineWidth: 0.5)
            )
    }

    /// Apply dark surface style
    func darkSurface() -> some View {
        self
            .background(PrismTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: PrismTheme.cornerRadius))
    }
}

// MARK: - Triangle Shape

/// Glass triangle shape for Prism button
struct TrianglePrism: Shape, InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let inset = insetAmount

        // Equilateral-ish triangle pointing up
        path.move(to: CGPoint(x: width / 2, y: inset))
        path.addLine(to: CGPoint(x: width - inset, y: height * 0.85 - inset))
        path.addLine(to: CGPoint(x: inset, y: height * 0.85 - inset))
        path.closeSubpath()

        return path
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}

/// Spectral ring for triangle (follows triangle shape)
struct TriangleSpectralRing: View {
    var intensity: Double = 0.65
    var lineWidth: CGFloat = 2.5

    @State private var spin = false

    var body: some View {
        TrianglePrism()
            .strokeBorder(
                AngularGradient(
                    gradient: Gradient(colors: [
                        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .red
                    ]),
                    center: .center
                ),
                lineWidth: lineWidth
            )
            .opacity(intensity)
            .rotationEffect(Angle.degrees(spin ? 3 : -3))
            .animation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                value: spin
            )
            .onAppear { spin = true }
    }
}

#Preview("Theme") {
    VStack(spacing: 20) {
        Text("Primary Text")
            .foregroundStyle(PrismTheme.textPrimary)

        Text("Secondary Text")
            .foregroundStyle(PrismTheme.textSecondary)

        RoundedRectangle(cornerRadius: 12)
            .fill(PrismTheme.glass)
            .frame(height: 80)
            .overlay(
                Text("Dark Glass Card")
                    .foregroundStyle(PrismTheme.textPrimary)
            )

        TrianglePrism()
            .fill(PrismTheme.glass)
            .frame(width: 80, height: 80)
            .overlay(
                TriangleSpectralRing()
            )
    }
    .padding()
    .background(PrismTheme.background)
}
