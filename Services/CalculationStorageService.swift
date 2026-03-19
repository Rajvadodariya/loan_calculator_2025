import Foundation
import Combine
import UIKit
import Supabase

/// Service for saving, loading, and managing loan calculations in Supabase + local cache.
@MainActor
class CalculationStorageService: ObservableObject {
    static let shared = CalculationStorageService()
    
    @Published var savedCalculations: [SavedCalculation] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let client = SupabaseManager.client
    private let cacheKey = "cached_saved_calculations"
    
    // MARK: - Free tier limits
    static let freeMaxSaved = 5
    static let freeMaxHistory = 10
    
    private init() {
        loadFromCache()
    }
    
    // MARK: - CRUD Operations
    
    /// Saves a calculation to Supabase and local cache.
    func saveCalculation(name: String, viewModel: CalculatorViewModel) async -> Bool {
        guard let userId = await getCurrentUserId() else {
            errorMessage = "Please sign in to save calculations."
            return false
        }
        
        // Check free tier limit
        if !StoreKitManager.shared.isPro && savedCalculations.count >= CalculationStorageService.freeMaxSaved {
            errorMessage = "Free users can save up to \(CalculationStorageService.freeMaxSaved) calculations. Upgrade to Pro for unlimited saves."
            return false
        }
        
        let calculation = SavedCalculation.from(name: name, viewModel: viewModel, userId: userId)
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await client.from("saved_calculations")
                .insert(calculation)
                .execute()
            
            savedCalculations.insert(calculation, at: 0)
            saveToCache()
            HapticService.shared.notification(type: .success)
            print("CalculationStorage: Saved '\(name)'")
            return true
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            print("CalculationStorage: Save failed: \(error)")
            return false
        }
    }
    
    /// Fetches all saved calculations for the current user from Supabase.
    func loadCalculations() async {
        guard let userId = await getCurrentUserId() else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: [SavedCalculation] = try await client.from("saved_calculations")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            let limit = StoreKitManager.shared.isPro ? response.count : min(response.count, CalculationStorageService.freeMaxHistory)
            savedCalculations = Array(response.prefix(limit))
            saveToCache()
            print("CalculationStorage: Loaded \(savedCalculations.count) calculations")
        } catch {
            print("CalculationStorage: Load failed: \(error.localizedDescription)")
            // Fall back to cache
            loadFromCache()
        }
    }
    
    /// Deletes a calculation from Supabase and local cache.
    func deleteCalculation(id: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await client.from("saved_calculations")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
            
            savedCalculations.removeAll { $0.id == id }
            saveToCache()
            HapticService.shared.impact(style: .medium)
            print("CalculationStorage: Deleted calculation \(id)")
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
            print("CalculationStorage: Delete failed: \(error)")
        }
    }
    
    /// Toggles the favorite status of a calculation.
    func toggleFavorite(id: UUID) async {
        guard let index = savedCalculations.firstIndex(where: { $0.id == id }) else { return }
        let newValue = !savedCalculations[index].isFavorite
        
        do {
            try await client.from("saved_calculations")
                .update(["is_favorite": AnyJSON.bool(newValue)])
                .eq("id", value: id.uuidString)
                .execute()
            
            savedCalculations[index].isFavorite = newValue
            saveToCache()
            HapticService.shared.impact(style: .light)
        } catch {
            print("CalculationStorage: Toggle favorite failed: \(error)")
        }
    }
    
    // MARK: - Local Cache (offline fallback)
    
    private func saveToCache() {
        if let data = try? JSONEncoder().encode(savedCalculations) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
    
    private func loadFromCache() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode([SavedCalculation].self, from: data) {
            savedCalculations = cached
        }
    }
    
    // MARK: - Helpers
    
    private func getCurrentUserId() async -> UUID? {
        do {
            let session = try await client.auth.session
            return session.user.id
        } catch {
            return nil
        }
    }
    
    /// Returns the 3 most recent saved calculations for the Home quick-access section.
    var recentCalculations: [SavedCalculation] {
        Array(savedCalculations.prefix(3))
    }
    
    /// Filtered calculations by search query.
    func filtered(by query: String) -> [SavedCalculation] {
        guard !query.isEmpty else { return savedCalculations }
        let lowered = query.lowercased()
        return savedCalculations.filter {
            $0.name.lowercased().contains(lowered) ||
            $0.calculatorType.lowercased().contains(lowered)
        }
    }
    
    /// Groups calculations by date category.
    func grouped() -> [(key: String, calculations: [SavedCalculation])] {
        let calendar = Calendar.current
        var groups: [String: [SavedCalculation]] = [:]
        
        for calc in savedCalculations {
            let key: String
            if calendar.isDateInToday(calc.createdAt) {
                key = "Today"
            } else if calendar.isDateInYesterday(calc.createdAt) {
                key = "Yesterday"
            } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()),
                      calc.createdAt > weekAgo {
                key = "This Week"
            } else {
                key = "Earlier"
            }
            groups[key, default: []].append(calc)
        }
        
        let order = ["Today", "Yesterday", "This Week", "Earlier"]
        return order.compactMap { key in
            guard let calcs = groups[key] else { return nil }
            return (key: key, calculations: calcs)
        }
    }
}
