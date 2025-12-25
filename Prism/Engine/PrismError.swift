import Foundation
import FoundationModels

/// Comprehensive error handling for Prism operations
/// Maps Foundation Models errors to user-actionable messages
@available(iOS 26.0, *)
enum PrismError: Error, LocalizedError {

    // MARK: - Model Availability
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    case modelDownloading
    case modelNotReady(String?)

    // MARK: - Generation Errors
    case refusal(explanation: String?)
    case guardrailViolation
    case decodingFailure(String?)
    case assetsUnavailable
    case unsupportedLanguage(String?)
    case concurrentRequests
    case contextOverflow
    case rateLimited
    case unsupportedGuide(String?)
    case serviceUnavailable(code: Int?)

    // MARK: - Schema Errors
    case schemaCompilationFailed(String)
    case invalidSchema(String)

    // MARK: - Session Errors
    case sessionInvalid
    case cancelled

    // MARK: - Unknown
    case unknown(Error)

    // MARK: - User-Friendly Messages

    var errorDescription: String? {
        switch self {
        // Availability
        case .deviceNotEligible:
            return "This device doesn't support Apple Intelligence."
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence is not enabled."
        case .modelDownloading:
            return "The AI model is still downloading."
        case .modelNotReady(let detail):
            if let detail { return "Model not ready: \(detail)" }
            return "The AI model isn't ready yet."

        // Generation
        case .refusal(let explanation):
            if let explanation { return explanation }
            return "The model declined this request."
        case .guardrailViolation:
            return "This request couldn't be processed safely."
        case .decodingFailure(let detail):
            if let detail { return "Output parsing failed: \(detail)" }
            return "Failed to parse the AI response."
        case .assetsUnavailable:
            return "Required AI assets are unavailable."
        case .unsupportedLanguage(let locale):
            if let locale { return "Language not supported: \(locale)" }
            return "This language is not supported."
        case .concurrentRequests:
            return "Already processing a request. Please wait."
        case .contextOverflow:
            return "Input too long. Try a shorter prompt."
        case .rateLimited:
            return "Too many requests. Please slow down."
        case .unsupportedGuide(let detail):
            if let detail { return "Unsupported schema guide: \(detail)" }
            return "This Prism uses an unsupported schema feature."
        case .serviceUnavailable(let code):
            if let code { return "Apple Intelligence unavailable (error \(code))." }
            return "Apple Intelligence is temporarily unavailable."

        // Schema
        case .schemaCompilationFailed(let reason):
            return "Prism configuration error: \(reason)"
        case .invalidSchema(let reason):
            return "Invalid Prism schema: \(reason)"

        // Session
        case .sessionInvalid:
            return "Session expired. Please try again."
        case .cancelled:
            return "Request was cancelled."

        // Unknown
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .deviceNotEligible:
            return "Apple Intelligence requires iPhone 15 Pro or newer."
        case .appleIntelligenceNotEnabled:
            return "Go to Settings → Apple Intelligence & Siri to enable it."
        case .modelDownloading, .modelNotReady:
            return "Please wait a moment and try again."
        case .refusal, .guardrailViolation:
            return "Try rephrasing your input."
        case .decodingFailure, .invalidSchema, .schemaCompilationFailed:
            return "Try editing this Prism's configuration."
        case .assetsUnavailable, .serviceUnavailable:
            return "Please try again in a moment."
        case .unsupportedLanguage:
            return "Try using English or your device's primary language."
        case .concurrentRequests:
            return "Wait for the current request to finish."
        case .contextOverflow:
            return "Shorten your input and try again."
        case .rateLimited:
            return "Wait a moment before trying again."
        case .unsupportedGuide:
            return "Try editing this Prism's configuration."
        case .sessionInvalid, .cancelled:
            return "Please try again."
        case .unknown:
            return nil
        }
    }

    /// Whether this error is recoverable by retrying
    var isRetryable: Bool {
        switch self {
        case .modelDownloading, .modelNotReady, .assetsUnavailable,
             .serviceUnavailable, .sessionInvalid, .cancelled, .rateLimited:
            return true
        case .deviceNotEligible, .appleIntelligenceNotEnabled,
             .schemaCompilationFailed, .invalidSchema, .contextOverflow, .unsupportedGuide:
            return false
        default:
            return true
        }
    }

    /// SF Symbol for this error type
    var iconName: String {
        switch self {
        case .deviceNotEligible, .appleIntelligenceNotEnabled:
            return "cpu"
        case .modelDownloading, .modelNotReady, .assetsUnavailable:
            return "arrow.down.circle"
        case .refusal, .guardrailViolation:
            return "hand.raised"
        case .serviceUnavailable:
            return "cloud.slash"
        case .contextOverflow:
            return "text.badge.xmark"
        default:
            return "exclamationmark.triangle"
        }
    }

    // MARK: - Factory Methods

    /// Create from SystemLanguageModel availability
    static func from(availability: SystemLanguageModel.Availability) -> PrismError? {
        guard case .unavailable(let reason) = availability else { return nil }

        switch reason {
        case .deviceNotEligible:
            return .deviceNotEligible
        case .appleIntelligenceNotEnabled:
            return .appleIntelligenceNotEnabled
        case .modelNotReady:
            return .modelNotReady(nil)
        @unknown default:
            return .modelNotReady(String(describing: reason))
        }
    }

    /// Create from any caught error
    static func from(_ error: Error) -> PrismError {
        // Already a PrismError
        if let prismError = error as? PrismError {
            return prismError
        }

        // Generation errors
        if let genError = error as? LanguageModelSession.GenerationError {
            return from(generationError: genError)
        }

        // String-based fallback for runtime errors
        let desc = String(describing: error)

        // Service unavailable with error code
        if desc.contains("GenerationError") {
            if let codeRange = desc.range(of: #"-?\d+"#, options: .regularExpression) {
                let code = Int(desc[codeRange])
                return .serviceUnavailable(code: code)
            }
            return .serviceUnavailable(code: nil)
        }

        // Model availability from string
        if desc.contains("modelNotReady") {
            return .modelNotReady(nil)
        }
        if desc.contains("deviceNotEligible") {
            return .deviceNotEligible
        }
        if desc.contains("appleIntelligenceNotEnabled") {
            return .appleIntelligenceNotEnabled
        }

        // Schema errors
        if desc.contains("Schema") || desc.contains("compile") {
            return .schemaCompilationFailed(desc)
        }

        // Cancellation
        if error is CancellationError || desc.contains("cancel") {
            return .cancelled
        }

        return .unknown(error)
    }

    /// Create from LanguageModelSession.GenerationError
    private static func from(generationError: LanguageModelSession.GenerationError) -> PrismError {
        switch generationError {
        case .refusal:
            return .refusal(explanation: nil)
        case .guardrailViolation:
            return .guardrailViolation
        case .decodingFailure(let context):
            return .decodingFailure(context.debugDescription)
        case .assetsUnavailable:
            return .assetsUnavailable
        case .unsupportedLanguageOrLocale(let context):
            return .unsupportedLanguage(context.debugDescription)
        case .concurrentRequests:
            return .concurrentRequests
        case .exceededContextWindowSize:
            return .contextOverflow
        case .unsupportedGuide(let context):
            return .unsupportedGuide(context.debugDescription)
        case .rateLimited:
            return .rateLimited
        @unknown default:
            return .serviceUnavailable(code: nil)
        }
    }
}
