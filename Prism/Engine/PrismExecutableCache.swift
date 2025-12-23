import Foundation

/// Caches compiled PrismExecutables by ID and version
actor PrismExecutableCache {
    private var cache: [String: PrismExecutable] = [:]

    /// Get cached executable or compile and cache
    func getOrCompile(_ prism: PrismDefinition) throws -> PrismExecutable {
        let key = "\(prism.id.uuidString):\(prism.version)"

        if let cached = cache[key] {
            return cached
        }

        let executable = try PrismSchemaCompiler.compile(prism)
        cache[key] = executable
        return executable
    }

    /// Clear cache for a specific Prism
    func invalidate(_ prismId: UUID) {
        cache = cache.filter { !$0.key.hasPrefix(prismId.uuidString) }
    }

    /// Clear entire cache
    func clearAll() {
        cache.removeAll()
    }
}
