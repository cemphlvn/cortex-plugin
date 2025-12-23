import Foundation

/// Pure data representation of a Prism
/// This is what gets stored and can be created by users
struct PrismDefinition: Codable, Identifiable, Sendable, Equatable, Hashable {
    /// Unique identifier
    let id: UUID
    /// Human-readable name
    var name: String
    /// Instructions for the model (behavior + constraints)
    var instructions: String
    /// Specification for the incident (input)
    var incidentBeam: IncidentBeamSpec
    /// Specifications for output beams
    var refractedBeams: [BeamSpec]
    /// Version number (for cache invalidation)
    var version: Int

    init(
        id: UUID = UUID(),
        name: String,
        instructions: String,
        incidentBeam: IncidentBeamSpec,
        refractedBeams: [BeamSpec],
        version: Int = 1
    ) {
        self.id = id
        self.name = name
        self.instructions = instructions
        self.incidentBeam = incidentBeam
        self.refractedBeams = refractedBeams
        self.version = version
    }
}

// MARK: - Hashable (for NavigationDestination)

extension PrismDefinition {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(version)
    }
}
