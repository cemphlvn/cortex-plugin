import Foundation

/// Loads bundled Prism definitions from Resources/Prisms/
enum PrismLoader {

    /// Load all bundled Prisms from the app bundle
    static func loadBundledPrisms() -> [PrismDefinition] {
        guard let resourceURL = Bundle.main.resourceURL?
            .appendingPathComponent("Prisms") else {
            return []
        }

        return loadPrisms(from: resourceURL)
    }

    /// Load Prisms from a directory URL
    static func loadPrisms(from directory: URL) -> [PrismDefinition] {
        let fileManager = FileManager.default

        guard let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        let decoder = JSONDecoder()

        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> PrismDefinition? in
                guard let data = try? Data(contentsOf: url),
                      let prism = try? decoder.decode(PrismDefinition.self, from: data) else {
                    return nil
                }
                return prism
            }
            .sorted { $0.name < $1.name }
    }

    /// Load a single Prism from JSON data
    static func load(from data: Data) throws -> PrismDefinition {
        let decoder = JSONDecoder()
        return try decoder.decode(PrismDefinition.self, from: data)
    }

    /// Load a single Prism from a JSON string
    static func load(from jsonString: String) throws -> PrismDefinition {
        guard let data = jsonString.data(using: .utf8) else {
            throw LoadError.invalidJSON
        }
        return try load(from: data)
    }

    enum LoadError: Error, LocalizedError {
        case invalidJSON
        case fileNotFound

        var errorDescription: String? {
            switch self {
            case .invalidJSON: return "Invalid JSON format"
            case .fileNotFound: return "Prism file not found"
            }
        }
    }
}
