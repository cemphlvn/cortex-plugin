import Foundation

/// Output value types for beam fields
enum BeamValue: Sendable, Equatable {
    case string(String)
    case stringArray([String])
}

/// Specification for value types (stored in PrismDefinition)
enum BeamValueType: String, Codable, Sendable {
    case string
    case stringArray
}
