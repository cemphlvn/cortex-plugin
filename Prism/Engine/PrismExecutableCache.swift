import Foundation

/// Caches compiled PrismExecutables by ID and version
/// Ensures "compile once per version" behavior
@available(iOS 26.0, *)
actor PrismExecutableCache {
    private var cache: [String: PrismExecutable] = [:]

    /// Get cached executable or compile and cache
    func getOrCompile(_ prism: PrismDefinition) throws -> PrismExecutable {
        let key = cacheKey(prism)

        if let cached = cache[key] {
            return cached
        }

        let executable = try PrismSchemaCompiler.compile(prism)
        cache[key] = executable
        return executable
    }

    /// Clear cache for a specific Prism (all versions)
    func invalidate(_ prismId: UUID) {
        cache = cache.filter { !$0.key.hasPrefix(prismId.uuidString) }
    }

    /// Clear cache for a specific Prism version
    func invalidate(_ prismId: UUID, version: Int) {
        let key = "\(prismId.uuidString):\(version)"
        cache.removeValue(forKey: key)
    }

    /// Clear entire cache
    func clearAll() {
        cache.removeAll()
    }

    /// Check if a Prism is cached
    func isCached(_ prism: PrismDefinition) -> Bool {
        cache[cacheKey(prism)] != nil
    }

    private func cacheKey(_ prism: PrismDefinition) -> String {
        "\(prism.id.uuidString):\(prism.version)"
    }
}
