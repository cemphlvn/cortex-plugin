import SwiftUI

/// Single animation language for Prism UI
/// Rule: one entrance curve, consistent timing
enum PrismAnimation {
    /// Standard spring for all entrances
    static let entrance = Animation.spring(response: 0.4, dampingFraction: 0.8)

    /// Delay between sequential beam reveals
    static let beamStaggerDelay: Double = 0.1

    /// Button press scale
    static let buttonPressScale: CGFloat = 0.95

    /// Running state pulse duration
    static let runningPulseDuration: Double = 1.2
}

/// Run state for PrismRunView
enum RunState: Equatable {
    case idle
    case running
    case revealed
}
