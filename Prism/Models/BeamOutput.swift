import Foundation

/// Output from running a Prism - one per beam
struct BeamOutput: Identifiable, Sendable, Equatable {
    /// Beam ID (matches BeamSpec.id)
    let id: String
    /// Fields with their values
    var fields: [FieldOutput]
}

/// Single field output within a beam
struct FieldOutput: Identifiable, Sendable, Equatable {
    var id: String { key }
    /// Field key (matches BeamFieldSpec.key)
    let key: String
    /// The generated value
    let value: BeamValue
}
