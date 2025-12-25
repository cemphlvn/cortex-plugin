import SwiftUI
import AuthenticationServices

/// Step 5: Sign In (Optional)
/// Offers cloud sync without blocking progress
struct OnboardingAuthView: View {
    @Environment(SupabaseAuthService.self) private var auth

    var onComplete: () -> Void

    @State private var showHeader = false
    @State private var showButtons = false
    @State private var showSkip = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Header
                if showHeader {
                    VStack(spacing: 20) {
                        // Cloud icon with prism
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.cyan.opacity(0.15), .clear],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 140, height: 140)

                            Image(systemName: "icloud")
                                .font(.system(size: 56, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.6)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            // Small prism inside cloud
                            TrianglePrism()
                                .fill(PrismTheme.glass)
                                .frame(width: 20, height: 20)
                                .offset(y: 6)
                        }

                        VStack(spacing: 12) {
                            Text("Sync Your Prisms")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.white)

                            Text("Sign in to back up your creations\nand access them on all your devices")
                                .font(.system(size: 15))
                                .foregroundStyle(PrismTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()

                // Auth buttons
                if showButtons {
                    VStack(spacing: 12) {
                        // Sign in with Apple
                        SignInWithAppleButton { request in
                            request.requestedScopes = [.email, .fullName]
                            let hashedNonce = auth.prepareAppleSignIn()
                            request.nonce = hashedNonce
                        } onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Email option
                        Button {
                            // For now, just skip - email can be done in settings
                            onComplete()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 18))
                                Text("Continue with Email")
                                    .font(.system(size: 17, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .foregroundStyle(.white)
                            .background(PrismTheme.glass)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(PrismTheme.border, lineWidth: 0.5)
                            )
                        }
                    }
                    .padding(.horizontal, 32)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Skip option
                if showSkip {
                    Button {
                        PrismHaptics.tick()
                        onComplete()
                    } label: {
                        Text("Maybe Later")
                            .font(.system(size: 15))
                            .foregroundStyle(PrismTheme.textTertiary)
                    }
                    .padding(.top, 8)
                    .transition(.opacity)
                }

                Spacer().frame(height: 50)
            }
        }
        .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                PrismHaptics.success()
                onComplete()
            }
        }
        .onAppear {
            animateSequence()
        }
    }

    // MARK: - Apple Sign In

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        Task {
            do {
                let authorization = try result.get()
                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                    return
                }
                try await auth.signInWithApple(credential: credential)
            } catch {
                // Silently handle - user can retry or skip
                print("Apple sign in failed: \(error)")
            }
        }
    }

    // MARK: - Animation

    private func animateSequence() {
        Task {
            // Header
            try? await Task.sleep(for: .seconds(0.3))
            await MainActor.run {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showHeader = true
                }
            }

            // Buttons
            try? await Task.sleep(for: .seconds(0.4))
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showButtons = true
                }
            }

            // Skip
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    showSkip = true
                }
            }
        }
    }
}

#Preview {
    OnboardingAuthView {
        print("Complete")
    }
    .environment(SupabaseAuthService())
}
