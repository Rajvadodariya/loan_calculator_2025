import Foundation
import Supabase

/// Central Supabase client manager
/// Replace the placeholder URL and key with your actual Supabase project credentials before release.
enum SupabaseManager {
    
    // MARK: - ⚠️ REPLACE THESE BEFORE PRODUCTION ⚠️
    private static let projectURL = "https://fuqdnclxmdsjnrxzllvr.supabase.co"
    private static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ1cWRuY2x4bWRzam5yeHpsbHZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIyNzkzNDUsImV4cCI6MjA4Nzg1NTM0NX0.jpeMfudl8GBEqRULV1-8_PE1lO5xcQjgSzKiiVlN2VY"
    
    /// Shared Supabase client
    static let client = SupabaseClient(
        supabaseURL: URL(string: projectURL)!,
        supabaseKey: anonKey,
        options: SupabaseClientOptions(
            auth: SupabaseClientOptions.AuthOptions(
                emitLocalSessionAsInitialSession: true
            )
        )
    )
}
