import Foundation

/// Specification for a single beam in a Prism
struct BeamSpec: Codable, Identifiable, Sendable, Equatable {
    /// Schema-safe identifier (snake_case)
    let id: String
    /// Human-readable title for UI
    var title: String
    /// Optional description for the beam
    var description: String?
    /// Fields within this beam
    var fields: [BeamFieldSpec]
}

/// Specification for a field within a beam
struct BeamFieldSpec: Codable, Sendable, Equatable {
    /// Schema-safe key (snake_case)
    let key: String
    /// Guide text - becomes schema property description
    var guide: String
    /// Type of value this field holds
    var valueType: BeamValueType
}

/// Specification for the incident (input) beam
struct IncidentBeamSpec: Codable, Sendable, Equatable {
    /// Type of input (MVP: "string")
    let type: String
    /// Description of what input is expected
    var description: String
}
