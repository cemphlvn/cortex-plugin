import Foundation
import Supabase

/// Supabase configuration from Info.plist (set via xcconfig)
@MainActor
enum SupabaseConfig {
    static var url: URL {
        guard let info = Bundle.main.infoDictionary,
              let urlString = info["SupabaseURL"] as? String,
              let url = URL(string: urlString) else {
            fatalError("SupabaseURL not configured in Info.plist")
        }
        return url
    }

    static var anonKey: String {
        guard let info = Bundle.main.infoDictionary,
              let key = info["SupabaseAnonKey"] as? String, !key.isEmpty else {
            fatalError("SupabaseAnonKey not configured in Info.plist")
        }
        return key
    }
}

/// Shared Supabase client instance (initialized on main actor)
@MainActor
let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.anonKey
)
