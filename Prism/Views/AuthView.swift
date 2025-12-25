import SwiftUI
import AuthenticationServices

/// Authentication view with Apple, Google, and Email sign in
struct AuthView: View {
    @Environment(SupabaseAuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss

    var onAuthenticated: (() -> Void)?
    var onSkip: (() -> Void)?
    var showSkipOption: Bool = true

    @State private var showEmailForm = false
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        ZStack {
            PrismTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 40)

                    // MARK: - Header
                    headerSection

                    Spacer().frame(height: 20)

                    // MARK: - Auth Buttons
                    VStack(spacing: 16) {
                        signInWithAppleButton
                        signInWithGoogleButton
                        emailOptionButton
                    }
                    .padding(.horizontal, 24)

                    // MARK: - Email Form (expandable)
                    if showEmailForm {
                        emailFormSection
                            .padding(.horizontal, 24)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Spacer()

                    // MARK: - Footer
                    footerSection
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Something went wrong")
        }
        .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                onAuthenticated?()
                dismiss()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Prism icon
            ZStack {
                TrianglePrism()
                    .fill(PrismTheme.glass)
                    .frame(width: 80, height: 80)

                TriangleSpectralRing(intensity: 0.5, lineWidth: 2)
                    .frame(width: 80, height: 80)
            }

            VStack(spacing: 8) {
                Text("Welcome to Prism")
                    .font(.title.bold())
                    .foregroundStyle(PrismTheme.textPrimary)

                Text("Sign in to sync your Prisms across devices and share with others")
                    .font(.subheadline)
                    .foregroundStyle(PrismTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Sign in with Apple

    private var signInWithAppleButton: some View {
        SignInWithAppleButtonInternal { request in
            request.requestedScopes = [.email, .fullName]
            // Set hashed nonce for Apple to verify
            let hashedNonce = auth.prepareAppleSignIn()
            request.nonce = hashedNonce
        } onCompletion: { result in
            Task {
                do {
                    let authorization = try result.get()
                    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                        throw AuthError.invalidCredentials
                    }
                    try await auth.signInWithApple(credential: credential)
                } catch {
                    handleError(error)
                }
            }
        }
        .frame(height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Sign in with Google

    private var signInWithGoogleButton: some View {
        Button {
            // TODO: Integrate GoogleSignIn SDK
            // For now, show placeholder
            errorMessage = "Google Sign In coming soon"
            showError = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "g.circle.fill")
                    .font(.title2)
                Text("Continue with Google")
                    .font(.body.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(PrismTheme.textPrimary)
            .background(PrismTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(PrismTheme.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Email Option

    private var emailOptionButton: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                showEmailForm.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .font(.title3)
                Text("Continue with Email")
                    .font(.body.weight(.medium))
                Spacer()
                Image(systemName: showEmailForm ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(PrismTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .padding(.horizontal, 20)
            .foregroundStyle(PrismTheme.textSecondary)
            .background(PrismTheme.glass)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Email Form

    private var emailFormSection: some View {
        VStack(spacing: 16) {
            // Email field
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(PrismTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(PrismTheme.textPrimary)

            // Password field
            SecureField("Password", text: $password)
                .textContentType(isSignUp ? .newPassword : .password)
                .padding()
                .background(PrismTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(PrismTheme.textPrimary)

            // Sign in / Sign up button
            Button {
                Task {
                    await handleEmailAuth()
                }
            } label: {
                HStack {
                    if auth.isLoading {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.body.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundStyle(.black)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(email.isEmpty || password.isEmpty || auth.isLoading)

            // Toggle sign in / sign up
            Button {
                withAnimation {
                    isSignUp.toggle()
                }
            } label: {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.footnote)
                    .foregroundStyle(PrismTheme.textSecondary)
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 20) {
            // Skip option
            if showSkipOption {
                Button {
                    onSkip?()
                    dismiss()
                } label: {
                    Text("Continue without account")
                        .font(.subheadline)
                        .foregroundStyle(PrismTheme.textTertiary)
                }
            }

            // Terms and Privacy
            VStack(spacing: 4) {
                Text("By continuing, you agree to our")
                    .font(.caption)
                    .foregroundStyle(PrismTheme.textTertiary)

                HStack(spacing: 4) {
                    Link("Terms of Service", destination: URL(string: "https://prism.app/terms")!)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(PrismTheme.textSecondary)

                    Text("and")
                        .font(.caption)
                        .foregroundStyle(PrismTheme.textTertiary)

                    Link("Privacy Policy", destination: URL(string: "https://prism.app/privacy")!)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(PrismTheme.textSecondary)
                }
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Actions

    private func handleEmailAuth() async {
        do {
            if isSignUp {
                try await auth.signUp(email: email, password: password)
            } else {
                try await auth.signIn(email: email, password: password)
            }
        } catch {
            handleError(error)
        }
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}

// MARK: - Sign in with Apple Button (Internal)

private struct SignInWithAppleButtonInternal: UIViewRepresentable {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
        button.cornerRadius = 12
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handlePress),
            for: .touchUpInside
        )
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onRequest: onRequest, onCompletion: onCompletion)
    }

    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let onRequest: (ASAuthorizationAppleIDRequest) -> Void
        let onCompletion: (Result<ASAuthorization, Error>) -> Void

        init(onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
             onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
            self.onRequest = onRequest
            self.onCompletion = onCompletion
        }

        @objc func handlePress() {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            onRequest(request)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else {
                fatalError("No window")
            }
            return window
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            onCompletion(.success(authorization))
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            // Don't report cancellation as error
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            onCompletion(.failure(error))
        }
    }
}

// MARK: - Preview

#Preview {
    AuthView()
        .environment(SupabaseAuthService())
}
