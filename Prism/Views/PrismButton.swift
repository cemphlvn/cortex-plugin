import SwiftUI

/// Central action button for running a Prism
/// Glass triangle + spectral rim (rainbow = reward)
struct PrismButton: View {
    let state: RunState
    let isEnabled: Bool
    let action: () -> Void

    @State private var isPressed = false
    @State private var showBurst = false

    private let size: CGFloat = 88

    var body: some View {
        Button(action: {
            PrismHaptics.buttonPress()
            action()
        }) {
            ZStack {
                // Spectral ring (only during running/revealed)
                if state == .running || state == .revealed {
                    TriangleSpectralRing(
                        intensity: state == .running ? 0.5 : 0.85,
                        lineWidth: state == .revealed ? 3 : 2
                    )
                    .frame(width: size + 16, height: size + 16)
                }

                // Refraction burst on success
                if showBurst {
                    RefractionBurst()
                        .frame(width: size + 50, height: size + 50)
                }

                // Glass triangle core
                TrianglePrism()
                    .fill(PrismTheme.glass)
                    .frame(width: size, height: size)
                    .overlay(
                        TrianglePrism()
                            .strokeBorder(PrismTheme.border, lineWidth: 1)
                    )

                // Icon
                iconView
                    .offset(y: 6) // Center in triangle visually
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? PrismAnimation.buttonPressScale : 1.0)
        .animation(PrismAnimation.entrance, value: isPressed)
        .animation(PrismAnimation.entrance, value: state)
        .disabled(!isEnabled || state == .running)
        .opacity(isEnabled ? 1.0 : 0.4)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        PrismHaptics.tick()
                    }
                }
                .onEnded { _ in isPressed = false }
        )
        .onChange(of: state) { oldState, newState in
            if oldState == .running && newState == .revealed {
                // Success transition
                PrismHaptics.success()
                showBurst = true
                Task {
                    try? await Task.sleep(for: .seconds(0.3))
                    await MainActor.run { showBurst = false }
                }
            }
        }
    }

    // MARK: - Icon

    @ViewBuilder
    private var iconView: some View {
        Group {
            switch state {
            case .idle:
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .medium))

            case .running:
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(PrismTheme.textPrimary)

            case .revealed:
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold))
            }
        }
        .foregroundStyle(PrismTheme.textPrimary)
    }
}

#Preview {
    VStack(spacing: 40) {
        PrismButton(state: .idle, isEnabled: true) {}
        PrismButton(state: .running, isEnabled: true) {}
        PrismButton(state: .revealed, isEnabled: true) {}
        PrismButton(state: .idle, isEnabled: false) {}
    }
    .padding(40)
    .background(PrismTheme.background)
}
