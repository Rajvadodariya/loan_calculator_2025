import Foundation
import Combine
import Supabase

// MARK: - Profile Model for Supabase
struct UserProfile: Codable {
    let id: UUID
    var coinBalance: Int
    var isPro: Bool
    var fullName: String?
    var username: String?
    var createdAt: Date?
    var updatedAt: Date?
    // PDF Customization Fields
    var removePdfWatermark: Bool?
    var addCustomNameToPdf: Bool?
    var customPdfName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case coinBalance = "coin_balance"
        case isPro = "is_pro"
        case fullName = "full_name"
        case username = "username"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case removePdfWatermark = "remove_pdf_watermark"
        case addCustomNameToPdf = "add_custom_name_to_pdf"
        case customPdfName = "custom_pdf_name"
    }
}
class CoinManager: ObservableObject {
    static let shared = CoinManager()
    
    // MARK: - Coin Costs & Rewards
    static let rewardAmount = 5
    static let pdfCost = 3
    static let csvCost = 2
    static let startingBonus = 3
    
    // MARK: - Published State
    @Published var coinBalance: Int {
        didSet {
            UserDefaults.standard.set(coinBalance, forKey: "coin_balance")
        }
    }
    
    @Published var showCoinAnimation: Bool = false
    
    private let client = SupabaseManager.client
    private var hasMigratedToCloud: Bool {
        get { UserDefaults.standard.bool(forKey: "has_migrated_coins_to_cloud") }
        set { UserDefaults.standard.set(newValue, forKey: "has_migrated_coins_to_cloud") }
    }
    
    private init() {
        let storedBalance = UserDefaults.standard.integer(forKey: "coin_balance")
        let hasReceivedBonus = UserDefaults.standard.bool(forKey: "has_received_starting_bonus")
        
        if !hasReceivedBonus {
            self.coinBalance = CoinManager.startingBonus
            UserDefaults.standard.set(CoinManager.startingBonus, forKey: "coin_balance")
            UserDefaults.standard.set(true, forKey: "has_received_starting_bonus")
        } else {
            self.coinBalance = storedBalance
        }
    }
    
    // MARK: - Coin Operations
    func earnCoins(_ amount: Int = CoinManager.rewardAmount) {
        coinBalance += amount
        triggerAnimation()
        syncToCloudIfNeeded()
    }
    
    func spendCoins(_ cost: Int) -> Bool {
        // Pro users bypass coin costs
        if StoreKitManager.shared.isPro {
            return true
        }
        guard canAfford(cost) else { return false }
        coinBalance -= cost
        syncToCloudIfNeeded()
        return true
    }
    
    func canAfford(_ cost: Int) -> Bool {
        // Pro users can always afford
        if StoreKitManager.shared.isPro {
            return true
        }
        return coinBalance >= cost
    }
    
    // MARK: - Cloud Sync
    
    /// Syncs the current local coin balance to the Supabase profiles table.
    func syncToCloud() async {
        guard let userId = await getCurrentUserId() else { return }
        
        do {
            let syncData: [String: AnyJSON] = [
                "id": AnyJSON.string(userId.uuidString),
                "coin_balance": AnyJSON.integer(coinBalance),
                "updated_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
            ]
            try await client.from("profiles")
                .upsert(syncData)
                .execute()
            print("CoinManager: Synced \(coinBalance) coins to cloud")
        } catch {
            print("CoinManager: Cloud sync failed: \(error.localizedDescription)")
        }
    }
    
    /// Fetches the coin balance from Supabase and updates local state.
    func fetchFromCloud() async {
        guard let userId = await getCurrentUserId() else { return }
        
        do {
            let response: [UserProfile] = try await client.from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            
            if let profile = response.first {
                await MainActor.run {
                    self.coinBalance = profile.coinBalance
                    StoreKitManager.shared.setRemoteProStatus(profile.isPro)
                    print("CoinManager: Fetched \(profile.coinBalance) coins and Pro=\(profile.isPro) from cloud")
                }
            }
        } catch {
            print("CoinManager: Cloud fetch failed: \(error.localizedDescription)")
        }
    }
    
    /// One-time migration on first sign-in: merges local + cloud coins (takes the higher value).
    func migrateCoinsOnFirstSignIn() async {
        guard !hasMigratedToCloud else { return }
        guard let userId = await getCurrentUserId() else { return }
        
        let localBalance = coinBalance
        
        do {
            // Try to fetch existing cloud profile
            let response: [UserProfile] = try await client.from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            
            let cloudBalance = response.first?.coinBalance ?? 0
            let mergedBalance = max(localBalance, cloudBalance)
            
            // Upsert with merged balance
            let mergedData: [String: AnyJSON] = [
                "id": AnyJSON.string(userId.uuidString),
                "coin_balance": AnyJSON.integer(mergedBalance),
                "updated_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
            ]
            try await client.from("profiles")
                .upsert(mergedData)
                .execute()
            
            await MainActor.run {
                self.coinBalance = mergedBalance
                self.hasMigratedToCloud = true
                StoreKitManager.shared.setRemoteProStatus(response.first?.isPro ?? false)
                print("CoinManager: Migration complete. Local=\(localBalance), Cloud=\(cloudBalance), Merged=\(mergedBalance)")
            }
        } catch {
            print("CoinManager: Migration failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helpers
    
    private func syncToCloudIfNeeded() {
        Task {
            guard await getCurrentUserId() != nil else { return }
            await syncToCloud()
        }
    }
    
    private func getCurrentUserId() async -> UUID? {
        do {
            let session = try await client.auth.session
            return session.user.id
        } catch {
            return nil
        }
    }
    
    // MARK: - Animation
    private func triggerAnimation() {
        showCoinAnimation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showCoinAnimation = false
        }
    }
}
