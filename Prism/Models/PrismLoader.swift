import Foundation

/// Loads bundled Prism definitions from Resources/Prisms/
enum PrismLoader {

    /// Load all bundled Prisms from the app bundle
    static func loadBundledPrisms() -> [PrismDefinition] {
        // Use urls(forResourcesWithExtension:subdirectory:) for reliable bundle access
        if let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "Prisms"),
           !urls.isEmpty {
            print("[PrismLoader] Found \(urls.count) files in Prisms subdirectory")
            let decoder = JSONDecoder()
            return urls
                .compactMap { url -> PrismDefinition? in
                    guard let data = try? Data(contentsOf: url),
                          let prism = try? decoder.decode(PrismDefinition.self, from: data) else {
                        print("[PrismLoader] Failed to decode: \(url.lastPathComponent)")
                        return nil
                    }
                    return prism
                }
                .sorted { $0.name < $1.name }
        }

        // Fallback: try loading from bundle root (flat structure)
        print("[PrismLoader] No Prisms subdirectory, trying bundle root")
        let result = loadPrismsFromBundleRoot()
        print("[PrismLoader] Loaded \(result.count) prisms from bundle root")
        return result
    }

    /// Fallback: load JSON files directly from bundle root
    private static func loadPrismsFromBundleRoot() -> [PrismDefinition] {
        let decoder = JSONDecoder()
        let knownFiles = ["caption_creator", "meeting_notes", "product_review"]

        return knownFiles.compactMap { name -> PrismDefinition? in
            guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
                print("[PrismLoader] File not found in bundle: \(name).json")
                return nil
            }
            do {
                let data = try Data(contentsOf: url)
                let prism = try decoder.decode(PrismDefinition.self, from: data)
                print("[PrismLoader] Successfully loaded: \(name).json")
                return prism
            } catch {
                print("[PrismLoader] Decode error for \(name).json: \(error)")
                return nil
            }
        }
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
