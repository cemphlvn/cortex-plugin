import Foundation
import AuthenticationServices
import Supabase
import CryptoKit

/// Authentication service using Supabase + Sign in with Apple
@MainActor
@Observable
final class SupabaseAuthService {

    // MARK: - State

    private(set) var currentUser: User?
    private(set) var isLoading = false
    private(set) var error: Error?

    /// Current nonce for Apple Sign In (stored between request and callback)
    private var currentNonce: String?

    var isAuthenticated: Bool { currentUser != nil }

    /// User ID for RevenueCat linking
    var userId: String? { currentUser?.id.uuidString }

    // MARK: - Init

    init() {
        // Check for existing session
        currentUser = supabase.auth.currentUser

        // Listen for auth state changes
        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                switch event {
                case .signedIn, .tokenRefreshed, .userUpdated:
                    currentUser = session?.user
                case .signedOut:
                    currentUser = nil
                default:
                    break
                }
            }
        }
    }

    // MARK: - Sign in with Apple

    /// Generate a random nonce and return the SHA256 hash for Apple request
    /// Call this before presenting the Apple Sign In sheet
    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    /// Handle Sign in with Apple credential
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        guard let idToken = credential.identityToken,
              let idTokenString = String(data: idToken, encoding: .utf8) else {
            throw AuthError.missingIdToken
        }

        guard let nonce = currentNonce else {
            throw AuthError.missingNonce
        }

        // Sign in with Supabase using nonce for verification
        try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idTokenString,
                nonce: nonce
            )
        )

        // Clear nonce after use
        currentNonce = nil

        // Apple only provides name on first sign-in, save to metadata
        if let fullName = credential.fullName {
            try await updateUserName(fullName)
        }
    }

    // MARK: - Nonce Helpers

    /// Generate a random string for nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    /// SHA256 hash of a string
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Update user metadata with name
    private func updateUserName(_ fullName: PersonNameComponents) async throws {
        var nameParts: [String] = []
        if let given = fullName.givenName { nameParts.append(given) }
        if let family = fullName.familyName { nameParts.append(family) }

        guard !nameParts.isEmpty else { return }

        try await supabase.auth.update(
            user: UserAttributes(
                data: [
                    "full_name": .string(nameParts.joined(separator: " ")),
                    "given_name": .string(fullName.givenName ?? ""),
                    "family_name": .string(fullName.familyName ?? "")
                ]
            )
        )
    }

    // MARK: - Sign in with Google

    /// Handle Sign in with Google (requires GoogleSignIn SDK)
    /// Call this after getting idToken and accessToken from GIDSignIn
    func signInWithGoogle(idToken: String, accessToken: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )
    }

    // MARK: - Email Sign In

    /// Sign up with email and password
    func signUp(email: String, password: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        try await supabase.auth.signUp(
            email: email,
            password: password
        )
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        try await supabase.auth.signIn(
            email: email,
            password: password
        )
    }

    /// Send password reset email
    func resetPassword(email: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        try await supabase.auth.resetPasswordForEmail(email)
    }

    // MARK: - Sign Out

    func signOut() async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        try await supabase.auth.signOut()
        currentUser = nil
    }

    // MARK: - Session

    /// Refresh session if needed
    func refreshSessionIfNeeded() async {
        do {
            _ = try await supabase.auth.session
        } catch {
            // Session expired or invalid, user needs to re-auth
            currentUser = nil
        }
    }
}

// MARK: - Errors

enum AuthError: Error, LocalizedError {
    case missingIdToken
    case missingNonce
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .missingIdToken:
            return "Missing ID token"
        case .missingNonce:
            return "Missing authentication nonce"
        case .invalidCredentials:
            return "Invalid email or password"
        }
    }
}
