import SwiftUI

/// Orchestrates the full onboarding experience
/// Manages step transitions with beautiful animations
struct OnboardingContainerView: View {
    var onComplete: (OnboardingLibraryView.OnboardingDestination) -> Void

    @State private var currentStep: OnboardingStep = .void
    @State private var isTransitioning = false

    enum OnboardingStep: Int, CaseIterable {
        case void = 0      // The Awakening
        case demo = 1      // The Demonstration
        case showcase = 2  // The Showcase (diverse examples)
        case reveal = 3    // The Reveal (archetypes)
        case library = 4   // The Library
    }

    var body: some View {
        ZStack {
            // Background (ensures no flash during transitions)
            Color.black.ignoresSafeArea()

            // Current step view
            Group {
                switch currentStep {
                case .void:
                    OnboardingVoidView {
                        transitionTo(.demo)
                    }

                case .demo:
                    OnboardingDemoView {
                        transitionTo(.showcase)
                    }

                case .showcase:
                    OnboardingShowcaseView {
                        transitionTo(.reveal)
                    }

                case .reveal:
                    OnboardingRevealView {
                        transitionTo(.library)
                    }

                case .library:
                    OnboardingLibraryView { destination in
                        onComplete(destination)
                    }
                }
            }
            .transition(stepTransition)
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(currentStep == .void)
    }

    // MARK: - Transitions

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 1.02)).animation(.easeOut(duration: 0.4)),
            removal: .opacity.combined(with: .scale(scale: 0.98)).animation(.easeIn(duration: 0.3))
        )
    }

    private func transitionTo(_ step: OnboardingStep) {
        guard !isTransitioning else { return }
        isTransitioning = true

        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep = step
        }

        Task {
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run {
                isTransitioning = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingContainerView { destination in
        print("Onboarding complete, going to: \(destination)")
    }
}
