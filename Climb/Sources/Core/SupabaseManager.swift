import Foundation
import Supabase

/// Singleton managing the Supabase client connection.
/// Uses the same backend as the web app.
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private static let supabaseURL = URL(string: "https://kyeclvdgzigiwqimqdvg.supabase.co")!
    private static let supabaseKey = "sb_publishable_ZN4NvIXuymJ2QvbdQ5qDkg_BVf4q7Wz"

    private init() {
        client = SupabaseClient(
            supabaseURL: Self.supabaseURL,
            supabaseKey: Self.supabaseKey
        )
    }
}
