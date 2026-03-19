import Foundation
import StoreKit
import Combine
import Supabase

/// Manages StoreKit 2 subscriptions for LoanPro+ Pro tier.
@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    // MARK: - Product Identifiers
    static let monthlyProductID = "loanpro_monthly"
    static let yearlyProductID = "loanpro_yearly"
    
    // MARK: - Published State
    @Published var isPro: Bool = false
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var productsLoading: Bool = false
    @Published var errorMessage: String?
    
    // Internal trackers for multi-source Pro status
    private var localIsPro: Bool = false
    private var remoteIsPro: Bool = false
    
    private var transactionListener: Task<Void, Error>?
    private let client = SupabaseManager.client
    
    private init() {
        // Start listening for transactions
        transactionListener = listenForTransactions()
        
        // Check existing entitlements
        Task {
            await checkExistingEntitlements()
            await loadProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        productsLoading = true
        errorMessage = nil
        
        do {
            let productIDs: Set<String> = [
                StoreKitManager.monthlyProductID,
                StoreKitManager.yearlyProductID
            ]
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
                
            if products.isEmpty {
                print("StoreKit: No products found. Check configuration.")
                errorMessage = "No products found. Please ensure StoreKit is configured."
            }
            
            print("StoreKit: Loaded \(products.count) products")
        } catch {
            print("StoreKit: Failed to load products: \(error)")
            errorMessage = "Failed to load subscription options."
        }
        productsLoading = false
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateProStatus(transaction: transaction)
                await transaction.finish()
                return true
                
            case .userCancelled:
                print("StoreKit: User cancelled purchase")
                return false
                
            case .pending:
                print("StoreKit: Purchase pending")
                errorMessage = "Purchase is pending approval."
                return false
                
            @unknown default:
                return false
            }
        } catch {
            print("StoreKit: Purchase error: \(error)")
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        // AppStore.sync() forces a refresh of the entitlements
        do {
            try await AppStore.sync()
            await checkExistingEntitlements()
            
            if isPro {
                HapticService.shared.notification(type: .success)
            } else {
                errorMessage = "No active subscription found."
            }
        } catch {
            errorMessage = "Failed to restore: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateProStatus(transaction: transaction)
                    await transaction.finish()
                } catch {
                    print("StoreKit: Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Check Existing Entitlements
    
    private func checkExistingEntitlements() async {
        var activeSubs = Set<String>()
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    activeSubs.insert(transaction.productID)
                }
            } catch {
                print("StoreKit: Entitlement check failed: \(error)")
            }
        }
        
        purchasedProductIDs = activeSubs
        localIsPro = activeSubs.contains(StoreKitManager.monthlyProductID) ||
                     activeSubs.contains(StoreKitManager.yearlyProductID)
        
        refreshIsPro()
        print("StoreKit: Local Pro status = \(localIsPro), Total = \(isPro)")
    }
    
    // MARK: - Verification
    
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.unknown
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Update Pro Status
    
    private func updateProStatus(transaction: Transaction) async {
        let isActive = transaction.revocationDate == nil
        
        if isActive {
            purchasedProductIDs.insert(transaction.productID)
        } else {
            purchasedProductIDs.remove(transaction.productID)
        }
        
        localIsPro = purchasedProductIDs.contains(StoreKitManager.monthlyProductID) ||
                     purchasedProductIDs.contains(StoreKitManager.yearlyProductID)
        
        refreshIsPro()
        
        // Sync pro status to Supabase if we are authenticated
        await syncProStatusToCloud()
    }
    
    private func refreshIsPro() {
        isPro = localIsPro || remoteIsPro
    }
    
    /// Syncs the current pro status to the Supabase profiles table.
    func syncProStatusToCloud() async {
        guard let userId = await getCurrentUserId() else { return }
        
        // We sync if either local or remote is true, but primarily we push local status to ensure account is updated.
        let statusToSync = isPro
        
        do {
            let dataToSync: [String: AnyJSON] = [
                "id": AnyJSON.string(userId.uuidString),
                "is_pro": AnyJSON.bool(statusToSync),
                "updated_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
            ]
            try await client.from("profiles")
                .upsert(dataToSync)
                .execute()
            print("StoreKit: Synced pro status (\(statusToSync)) to cloud")
        } catch {
            print("StoreKit: Failed to sync pro status: \(error)")
        }
    }
    
    /// Fetches the pro status from the cloud and updates the local state.
    func fetchProStatusFromCloud() async {
        guard let userId = await getCurrentUserId() else { return }
        
        do {
            let response: [UserProfile] = try await client.from("profiles")
                .select("is_pro")
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            
            if let profile = response.first {
                self.remoteIsPro = profile.isPro
                refreshIsPro()
                print("StoreKit: Fetched remote Pro status: \(profile.isPro)")
            }
        } catch {
            print("StoreKit: Failed to fetch pro status: \(error)")
        }
    }
    
    /// Called when the user logs out to clear account-linked Pro status.
    func resetRemoteProStatus() {
        remoteIsPro = false
        refreshIsPro()
        print("StoreKit: Reset remote Pro status")
    }
    
    /// Directly sets the remote pro status (e.g. from CoinManager profile fetch)
    func setRemoteProStatus(_ value: Bool) {
        remoteIsPro = value
        refreshIsPro()
        print("StoreKit: setRemoteProStatus = \(value)")
    }
    
    private func getCurrentUserId() async -> UUID? {
        do {
            let session = try await client.auth.session
            return session.user.id
        } catch {
            return nil
        }
    }
    
    // MARK: - Helpers
    
    var monthlyProduct: Product? {
        products.first { $0.id == StoreKitManager.monthlyProductID }
    }
    
    var yearlyProduct: Product? {
        products.first { $0.id == StoreKitManager.yearlyProductID }
    }
    
    var yearlySavingsPercentage: Int {
        guard let monthly = monthlyProduct, let yearly = yearlyProduct else { return 0 }
        let monthlyAnnual = monthly.price * 12
        let savings = ((monthlyAnnual - yearly.price) / monthlyAnnual) * 100
        return NSDecimalNumber(decimal: savings).intValue
    }
}
