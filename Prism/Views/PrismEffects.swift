import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Spectral Ring

/// Rotating rainbow ring for Prism button
/// Subtle during running, bright on success
struct SpectralRing: View {
    var intensity: Double = 0.65
    var lineWidth: CGFloat = 2.5

    @State private var spin = false

    var body: some View {
        Circle()
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
            .rotationEffect(.degrees(spin ? 360 : 0))
            .animation(
                .linear(duration: PrismAnimation.runningPulseDuration)
                .repeatForever(autoreverses: false),
                value: spin
            )
            .onAppear { spin = true }
    }
}

// MARK: - Light Sweep

/// Diagonal light sweep that plays once on beam reveal
struct LightSweep: View {
    var delay: Double = 0

    @State private var x: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.18), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: geo.size.width * 0.4)
                .rotationEffect(.degrees(-20))
                .offset(x: x * geo.size.width * 1.5)
                .blur(radius: 6)
        }
        .clipped()
        .allowsHitTesting(false)
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(delay))
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.5)) { x = 1 }
                }
            }
        }
    }
}

// MARK: - Refraction Burst

/// Brief chromatic split effect on success
struct RefractionBurst: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // RGB offset layers
            Circle()
                .fill(Color.red.opacity(0.15))
                .offset(x: -2, y: -1)

            Circle()
                .fill(Color.green.opacity(0.15))
                .offset(x: 1, y: -2)

            Circle()
                .fill(Color.blue.opacity(0.15))
                .offset(x: 1, y: 2)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .blur(radius: 8)
        .onAppear {
            withAnimation(.easeOut(duration: 0.15)) {
                scale = 1.3
                opacity = 1
            }
            withAnimation(.easeIn(duration: 0.15).delay(0.15)) {
                scale = 1.0
                opacity = 0
            }
        }
    }
}

// MARK: - Glass Background

/// Frosted glass effect for premium feel
struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func glassBackground(cornerRadius: CGFloat = 12) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius))
    }
}

// MARK: - Haptics

enum PrismHaptics {
    /// Soft click for button press
    static func buttonPress() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }

    /// Light tap for copy action
    static func copy() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }

    /// Success feedback for reveal
    static func success() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    /// Soft selection tick
    static func tick() {
        #if canImport(UIKit)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        #endif
    }
}

// MARK: - Previews

#Preview("Effects") {
    VStack(spacing: 40) {
        // Spectral Ring
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 80, height: 80)

            SpectralRing()
                .frame(width: 88, height: 88)
        }

        // Light Sweep
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.2))
            .frame(height: 80)
            .overlay(LightSweep())
            .padding(.horizontal)

        // Refraction Burst
        ZStack {
            Circle()
                .fill(Color.purple)
                .frame(width: 60, height: 60)

            RefractionBurst()
                .frame(width: 100, height: 100)
        }
    }
    .padding()
    .background(Color.black)
}
