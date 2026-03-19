import Foundation
import SwiftUI
import Combine
import AuthenticationServices
import CryptoKit
import Supabase

/// Manages all authentication flows: Apple, Google, Email/Password
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var userProfile: UserProfile?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let client = SupabaseManager.client
    
    private init() {
        Task { await checkSession() }
    }
    
    // MARK: - Session Management
    
    func checkSession() async {
        do {
            let session = try await client.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
            
            // Fetch profile data
            await fetchUserProfile(userId: session.user.id)
        } catch {
            self.currentUser = nil
            self.userProfile = nil
            self.isAuthenticated = false
        }
    }

    func fetchUserProfile(userId: UUID) async {
        do {
            let response: [UserProfile] = try await client.from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            
            if let profile = response.first {
                self.userProfile = profile
                
                // Sync to other managers
                StoreKitManager.shared.setRemoteProStatus(profile.isPro)
                CoinManager.shared.coinBalance = profile.coinBalance
            }
        } catch {
            print("AuthService: Profile fetch failed: \(error)")
        }
    }
    
    // MARK: - Sign In with Apple
    
    func signInWithApple(idToken: String, nonce: String, fullName: String? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            self.currentUser = session.user
            if !self.isAuthenticated {
                self.isAuthenticated = true
            }
            
            // Sync profile with Apple data if available
            await syncProfile(userId: session.user.id, fullName: fullName)
            await syncDataAfterLogin()
        } catch {
            self.errorMessage = error.localizedDescription
            print("Apple Sign-In error: \(error)")
        }
    }
    
    // MARK: - Sign In with Google
    
    func signInWithGoogle(idToken: String, accessToken: String, fullName: String? = nil, nonce: String? = nil) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .google,
                    idToken: idToken,
                    accessToken: accessToken,
                    nonce: nonce
                )
            )
            self.currentUser = session.user
            if !self.isAuthenticated {
                self.isAuthenticated = true
            }
            
            // Sync profile with Google data if available
            await syncProfile(userId: session.user.id, fullName: fullName)
            await syncDataAfterLogin()
        } catch {
            self.errorMessage = error.localizedDescription
            print("Google Sign-In error: \(error)")
        }
    }
    
    // MARK: - Profile Sync Helper
    
    private func syncProfile(userId: UUID, fullName: String?) async {
        // 1. Check if profile already exists to avoid overwriting username/name
        var existingProfile: UserProfile? = nil
        do {
            let response: [UserProfile] = try await client.from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            existingProfile = response.first
        } catch {
            print("AuthService: Error fetching existing profile: \(error)")
        }

        // 2. Prepare update data
        var updateData: [String: AnyJSON] = [
            "id": AnyJSON.string(userId.uuidString),
            "updated_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        // Only set full_name if we don't have one yet and one was provided
        if let name = fullName, !name.isEmpty, existingProfile?.fullName == nil {
            updateData["full_name"] = AnyJSON.string(name)
        }
        
        // Only generate username if the user doesn't have one yet
        var finalUsername = existingProfile?.username
        if finalUsername == nil || finalUsername?.isEmpty == true {
            let base = fullName?.lowercased().replacingOccurrences(of: " ", with: "") ?? "user"
            let randomSuffix = Int.random(in: 1000...9999)
            let generated = "\(base)\(randomSuffix)"
            updateData["username"] = AnyJSON.string(generated)
            finalUsername = generated
        }
        
        // 3. Upsert to Profile table
        do {
            try await client.from("profiles")
                .upsert(updateData)
                .execute()
            print("AuthService: Synced profile for \(userId)")
            
            // 4. Also update Auth Metadata if we generated a new name/username
            // This ensures userDisplayName/username properties in AuthService are correct
            let attributes = UserAttributes(
                data: [
                    "full_name": AnyJSON.string(fullName ?? existingProfile?.fullName ?? ""),
                    "username": AnyJSON.string(finalUsername ?? "")
                ]
            )
            _ = try? await client.auth.update(user: attributes)
            
        } catch {
            print("AuthService: Failed to sync profile: \(error)")
        }
    }
    
    // MARK: - Email/Password Auth
    
    func signUp(email: String, password: String, fullName: String = "", username: String = "") async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let result = try await client.auth.signUp(
                email: email,
                password: password,
                data: [
                    "full_name": AnyJSON.string(fullName),
                    "username": AnyJSON.string(username)
                ]
            )
            self.currentUser = result.user
            if !self.isAuthenticated {
                self.isAuthenticated = true
            }
            
            // Create profile with name/username
            if let userId = result.user.id as UUID? {
                let profileData: [String: AnyJSON] = [
                    "id": AnyJSON.string(userId.uuidString),
                    "full_name": AnyJSON.string(fullName),
                    "username": AnyJSON.string(username),
                    "coin_balance": AnyJSON.integer(CoinManager.startingBonus)
                ]
                _ = try? await client.from("profiles")
                    .upsert(profileData)
                    .execute()
            }
            
            await syncDataAfterLogin()
        } catch {
            self.errorMessage = parseAuthError(error)
            print("Sign-up error: \(error)")
            HapticService.shared.notification(type: .error)
        }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            self.currentUser = session.user
            if !self.isAuthenticated {
                self.isAuthenticated = true
            }
            await syncDataAfterLogin()
        } catch {
            self.errorMessage = parseAuthError(error)
            print("Sign-in error: \(error)")
            HapticService.shared.notification(type: .error)
        }
    }
    
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await client.auth.resetPasswordForEmail(email)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        do {
            try await client.auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
            StoreKitManager.shared.resetRemoteProStatus()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Delete Account
    
    func deleteAccount() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Note: Full account deletion requires a Supabase Edge Function.
            // For now, we sign out. Implement server-side deletion before production.
            try await client.auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
            StoreKitManager.shared.resetRemoteProStatus()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - User Info Helpers
    
    var userEmail: String {
        currentUser?.email ?? ""
    }
    
    var userDisplayName: String {
        if let profileName = userProfile?.fullName, !profileName.isEmpty {
            return profileName
        }
        if let meta = currentUser?.userMetadata,
           let name = try? meta["full_name"]?.decode(as: String.self) {
            return name
        }
        return userEmail.components(separatedBy: "@").first ?? "User"
    }
    
    var username: String {
        if let profileUname = userProfile?.username, !profileUname.isEmpty {
            return profileUname
        }
        if let meta = currentUser?.userMetadata,
           let uname = try? meta["username"]?.decode(as: String.self) {
            return uname
        }
        return ""
    }
    
    var userInitial: String {
        String(userDisplayName.prefix(1)).uppercased()
    }
    
    // MARK: - Error Helper
    
    private func parseAuthError(_ error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("invalid credentials") || errorString.contains("invalid login") {
            return L10n.string("error_invalid_credentials")
        } else if errorString.contains("already registered") || errorString.contains("user already exists") {
            return L10n.string("error_email_in_use")
        } else if errorString.contains("weak password") || errorString.contains("password should be") {
            return L10n.string("error_weak_password")
        } else if errorString.contains("rate limit") {
            return L10n.string("error_rate_limit")
        } else if errorString.contains("network") || errorString.contains("internet") {
            return L10n.string("error_network")
        }
        
        // Return cleaned up Supabase message if we can't map it
        let message = error.localizedDescription
        return message.replacingOccurrences(of: "AuthError: ", with: "")
    }
    
    // MARK: - Data Sync Helper
    
    private func syncDataAfterLogin() async {
        await CoinManager.shared.migrateCoinsOnFirstSignIn()
        await CoinManager.shared.fetchFromCloud()
        
        // Push local Pro status to cloud account
        await StoreKitManager.shared.syncProStatusToCloud()
        // Pull existing Pro status from cloud account
        await StoreKitManager.shared.fetchProStatusFromCloud()
    }
}

