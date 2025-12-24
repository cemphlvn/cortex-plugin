import Foundation
import FoundationModels

/// Checks and monitors Foundation Models availability
@available(iOS 26.0, *)
@MainActor
@Observable
final class ModelAvailability {

    /// Shared instance
    static let shared = ModelAvailability()

    /// Current availability status
    private(set) var status: Status = .checking

    /// Reference to system language model
    private let model = SystemLanguageModel.default

    private init() {
        updateStatus()
    }

    /// Refresh availability status
    func refresh() {
        updateStatus()
    }

    private func updateStatus() {
        switch model.availability {
        case .available:
            status = .available

        case .unavailable(.deviceNotEligible):
            status = .unavailable(.deviceNotEligible)

        case .unavailable(.appleIntelligenceNotEnabled):
            status = .unavailable(.appleIntelligenceNotEnabled)

        case .unavailable(.modelNotReady):
            status = .unavailable(.modelNotReady)

        case .unavailable(let reason):
            status = .unavailable(.other(String(describing: reason)))
        }
    }

    // MARK: - Types

    enum Status: Equatable {
        case checking
        case available
        case unavailable(UnavailableReason)

        var isAvailable: Bool {
            if case .available = self { return true }
            return false
        }
    }

    enum UnavailableReason: Equatable {
        case deviceNotEligible
        case appleIntelligenceNotEnabled
        case modelNotReady
        case other(String)

        var message: String {
            switch self {
            case .deviceNotEligible:
                return "This device doesn't support Apple Intelligence."
            case .appleIntelligenceNotEnabled:
                return "Please enable Apple Intelligence in Settings."
            case .modelNotReady:
                return "The model is downloading. Please try again later."
            case .other(let description):
                return description
            }
        }
    }
}

// MARK: - Fallback for older iOS

enum ModelAvailabilityFallback {
    static var isSupported: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }
}
