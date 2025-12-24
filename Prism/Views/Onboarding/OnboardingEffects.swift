import SwiftUI

// MARK: - Light Spark

/// A breathing point of light - the primordial element
struct LightSpark: View {
    var size: CGFloat = 4
    var glowRadius: CGFloat = 20
    var isBreathing: Bool = true
    var isFlickering: Bool = false

    @State private var breathePhase: CGFloat = 0
    @State private var flickerOpacity: CGFloat = 1
    @State private var jitter: CGSize = .zero

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.4), .white.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: glowRadius
                    )
                )
                .frame(width: glowRadius * 2, height: glowRadius * 2)
                .scaleEffect(1 + breathePhase * 0.3)

            // Core
            Circle()
                .fill(.white)
                .frame(width: size, height: size)
                .shadow(color: .white, radius: 4)
        }
        .opacity(flickerOpacity)
        .offset(jitter)
        .onAppear {
            if isBreathing {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    breathePhase = 1
                }
            }
        }
        .onChange(of: isFlickering) { _, flickering in
            if flickering {
                startFlickering()
            }
        }
    }

    private func startFlickering() {
        Task {
            while isFlickering {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.05)) {
                        flickerOpacity = Double.random(in: 0.4...1.0)
                        jitter = CGSize(
                            width: CGFloat.random(in: -3...3),
                            height: CGFloat.random(in: -3...3)
                        )
                    }
                }
                try? await Task.sleep(for: .milliseconds(50))
            }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    flickerOpacity = 1
                    jitter = .zero
                }
            }
        }
    }
}

// MARK: - Spectrum Burst

/// The big bang - light explodes into rainbow rays, then converges to triangle
struct SpectrumBurst: View {
    @Binding var phase: BurstPhase
    var onComplete: (() -> Void)?

    enum BurstPhase {
        case waiting
        case exploding
        case converging
        case complete
    }

    private let rayCount = 12
    private let spectrumColors: [Color] = [
        .red, .orange, .yellow, .green, .cyan, .blue, .purple,
        .red, .orange, .yellow, .green, .cyan
    ]

    @State private var rayScales: [CGFloat] = Array(repeating: 0, count: 12)
    @State private var rayOpacities: [Double] = Array(repeating: 0, count: 12)
    @State private var showTriangle = false
    @State private var triangleScale: CGFloat = 0.3
    @State private var triangleOpacity: Double = 0

    var body: some View {
        ZStack {
            // Rays
            ForEach(0..<rayCount, id: \.self) { index in
                SpectrumRay(
                    color: spectrumColors[index],
                    angle: Double(index) * (360.0 / Double(rayCount))
                )
                .scaleEffect(rayScales[index])
                .opacity(rayOpacities[index])
            }

            // Central triangle emerges
            if showTriangle {
                ZStack {
                    // Glow behind
                    TrianglePrism()
                        .fill(.white.opacity(0.3))
                        .blur(radius: 20)
                        .frame(width: 100, height: 100)

                    // Glass triangle
                    TrianglePrism()
                        .fill(PrismTheme.glass)
                        .frame(width: 88, height: 88)
                        .overlay(
                            TrianglePrism()
                                .strokeBorder(PrismTheme.border, lineWidth: 1)
                        )

                    // Spectral rim
                    TriangleSpectralRing(intensity: 0.9, lineWidth: 3)
                        .frame(width: 96, height: 96)
                }
                .scaleEffect(triangleScale)
                .opacity(triangleOpacity)
            }
        }
        .onChange(of: phase) { _, newPhase in
            switch newPhase {
            case .waiting:
                break
            case .exploding:
                explode()
            case .converging:
                converge()
            case .complete:
                break
            }
        }
    }

    private func explode() {
        // Staggered ray explosion
        for i in 0..<rayCount {
            let delay = Double(i) * 0.02
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(delay)) {
                rayScales[i] = 1.5
                rayOpacities[i] = 1
            }
        }

        // Transition to converging
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            await MainActor.run {
                phase = .converging
            }
        }
    }

    private func converge() {
        // Rays fade and shrink
        withAnimation(.easeIn(duration: 0.3)) {
            for i in 0..<rayCount {
                rayScales[i] = 0.2
                rayOpacities[i] = 0
            }
        }

        // Triangle emerges
        showTriangle = true
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
            triangleScale = 1
            triangleOpacity = 1
        }

        // Complete
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            await MainActor.run {
                phase = .complete
                PrismHaptics.success()
                onComplete?()
            }
        }
    }
}

/// A single ray of the spectrum
struct SpectrumRay: View {
    let color: Color
    let angle: Double

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 4, height: 120)
            .blur(radius: 2)
            .rotationEffect(.degrees(angle))
            .offset(y: -60) // Ray points outward from center
    }
}

// MARK: - Text Dissolve Effect

/// Text that dissolves into light particles streaming upward
struct TextDissolve: View {
    let text: String
    @Binding var isDissolving: Bool
    var targetPoint: CGPoint = CGPoint(x: 0.5, y: 0) // Relative to view
    var onComplete: (() -> Void)?

    @State private var textOpacity: Double = 1
    @State private var particles: [DissolveParticle] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Original text (fades out)
                Text(text)
                    .font(.body)
                    .foregroundStyle(PrismTheme.textPrimary)
                    .opacity(textOpacity)

                // Particles
                ForEach(particles) { particle in
                    Circle()
                        .fill(.white)
                        .frame(width: particle.size, height: particle.size)
                        .shadow(color: .white.opacity(0.5), radius: 2)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onChange(of: isDissolving) { _, dissolving in
                if dissolving {
                    startDissolve(in: geo.size)
                }
            }
        }
    }

    private func startDissolve(in size: CGSize) {
        let target = CGPoint(x: size.width * targetPoint.x, y: size.height * targetPoint.y)

        // Create particles across the text area
        let particleCount = min(text.count * 2, 30)
        var newParticles: [DissolveParticle] = []

        for i in 0..<particleCount {
            let startX = CGFloat.random(in: size.width * 0.2...size.width * 0.8)
            let startY = CGFloat.random(in: size.height * 0.3...size.height * 0.7)

            newParticles.append(DissolveParticle(
                id: i,
                position: CGPoint(x: startX, y: startY),
                targetPosition: target,
                size: CGFloat.random(in: 2...4),
                delay: Double(i) * 0.03,
                opacity: 1
            ))
        }

        particles = newParticles

        // Fade text
        withAnimation(.easeIn(duration: 0.3)) {
            textOpacity = 0
        }

        // Animate particles
        for i in 0..<particles.count {
            let delay = particles[i].delay

            Task {
                try? await Task.sleep(for: .seconds(delay))
                await MainActor.run {
                    withAnimation(.easeIn(duration: 0.5)) {
                        particles[i].position = particles[i].targetPosition
                        particles[i].opacity = 0
                        particles[i].size = 1
                    }
                }
            }
        }

        // Complete callback
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            await MainActor.run {
                onComplete?()
            }
        }
    }
}

struct DissolveParticle: Identifiable {
    let id: Int
    var position: CGPoint
    var targetPosition: CGPoint
    var size: CGFloat
    var delay: Double
    var opacity: Double
}

// MARK: - Light Ray (for beam reveal)

/// A ray of light shooting from source to target
struct LightRay: View {
    var color: Color = .white
    var startPoint: CGPoint
    var endPoint: CGPoint
    @Binding var isVisible: Bool
    var onLand: (() -> Void)?

    @State private var progress: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: startPoint)
                let currentEnd = CGPoint(
                    x: startPoint.x + (endPoint.x - startPoint.x) * progress,
                    y: startPoint.y + (endPoint.y - startPoint.y) * progress
                )
                path.addLine(to: currentEnd)
            }
            .stroke(
                LinearGradient(
                    colors: [color.opacity(0.8), color.opacity(0.3)],
                    startPoint: .init(x: startPoint.x / geo.size.width, y: startPoint.y / geo.size.height),
                    endPoint: .init(x: endPoint.x / geo.size.width, y: endPoint.y / geo.size.height)
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .blur(radius: 2)
            .opacity(opacity)
        }
        .onChange(of: isVisible) { _, visible in
            if visible {
                animate()
            }
        }
    }

    private func animate() {
        withAnimation(.easeOut(duration: 0.15)) {
            opacity = 1
        }
        withAnimation(.easeOut(duration: 0.25)) {
            progress = 1
        }

        Task {
            try? await Task.sleep(for: .milliseconds(250))
            await MainActor.run {
                PrismHaptics.tick()
                onLand?()
            }
            try? await Task.sleep(for: .milliseconds(100))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    opacity = 0
                }
            }
        }
    }
}

// MARK: - Cinematic Text

/// Text with theatrical timing - fade in, hold, fade out
struct CinematicText: View {
    let text: String
    var font: Font = .system(size: 28, weight: .ultraLight)
    var tracking: CGFloat = 4
    @Binding var phase: TextPhase

    enum TextPhase {
        case hidden
        case entering
        case visible
        case exiting
    }

    @State private var opacity: Double = 0
    @State private var yOffset: CGFloat = 10

    var body: some View {
        Text(text)
            .font(font)
            .tracking(tracking)
            .foregroundStyle(.white)
            .opacity(opacity)
            .offset(y: yOffset)
            .onChange(of: phase) { _, newPhase in
                switch newPhase {
                case .hidden:
                    opacity = 0
                    yOffset = 10
                case .entering:
                    withAnimation(.easeOut(duration: 0.5)) {
                        opacity = 1
                        yOffset = 0
                    }
                case .visible:
                    break
                case .exiting:
                    withAnimation(.easeIn(duration: 0.3)) {
                        opacity = 0
                        yOffset = -5
                    }
                }
            }
    }
}

// MARK: - Pulsing Glow

/// A pulsing glow effect for emphasis
struct PulsingGlow: View {
    var color: Color = .white
    var minOpacity: Double = 0.3
    var maxOpacity: Double = 0.8
    var duration: Double = 1.5

    @State private var opacity: Double = 0.3

    var body: some View {
        Circle()
            .fill(color)
            .blur(radius: 30)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    opacity = maxOpacity
                }
            }
    }
}

// MARK: - Archetype Icon with Glow

struct ArchetypeIconView: View {
    let archetype: PrismArchetype
    var size: CGFloat = 48
    var showGlow: Bool = false

    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            // Glow
            if showGlow {
                Circle()
                    .fill(archetype.accentColor)
                    .frame(width: size * 1.5, height: size * 1.5)
                    .blur(radius: 15)
                    .opacity(glowOpacity)
            }

            // Icon background
            Circle()
                .fill(PrismTheme.glass)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .strokeBorder(archetype.accentColor.opacity(0.5), lineWidth: 1)
                )

            // Icon
            Image(systemName: archetype.icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(archetype.accentColor)
        }
        .onAppear {
            if showGlow {
                withAnimation(.easeInOut(duration: 0.8)) {
                    glowOpacity = 0.6
                }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(0.5)) {
                    glowOpacity = 0.3
                }
            }
        }
    }
}

// MARK: - Floating Card Effect

struct FloatingCard: ViewModifier {
    var delay: Double = 0

    @State private var isVisible = false
    @State private var floatOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.85)
            .offset(y: floatOffset)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                    isVisible = true
                }
                // Subtle floating
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(delay + 0.5)) {
                    floatOffset = -4
                }
            }
    }
}

extension View {
    func floatingCard(delay: Double = 0) -> some View {
        modifier(FloatingCard(delay: delay))
    }
}

// MARK: - Previews

#Preview("Light Spark") {
    ZStack {
        Color.black.ignoresSafeArea()
        LightSpark(isBreathing: true)
    }
}

#Preview("Spectrum Burst") {
    struct BurstPreview: View {
        @State private var phase: SpectrumBurst.BurstPhase = .waiting

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                SpectrumBurst(phase: $phase)

                VStack {
                    Spacer()
                    Button("Explode") {
                        phase = .exploding
                    }
                    .foregroundStyle(.white)
                    .padding()
                }
            }
        }
    }
    return BurstPreview()
}

#Preview("Archetype Icons") {
    ZStack {
        PrismTheme.background.ignoresSafeArea()

        HStack(spacing: 24) {
            ForEach(PrismArchetype.allCases) { archetype in
                ArchetypeIconView(archetype: archetype, showGlow: true)
            }
        }
    }
}
