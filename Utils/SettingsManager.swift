import Combine
import SwiftUI
import Supabase

enum AppAppearance: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var localizedName: String {
        switch self {
        case .system: return L10n.string("appearance_system")
        case .light: return L10n.string("appearance_light")
        case .dark: return L10n.string("appearance_dark")
        }
    }
}

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @AppStorage("selected_country") private var storedSelectedCountry: Country = .usa
    @AppStorage("app_language") private var storedAppLanguage: AppLanguage = .english
    @AppStorage("has_completed_onboarding") private var storedHasCompletedOnboarding: Bool = false
    @AppStorage("app_appearance") private var storedAppearance: String = AppAppearance.system.rawValue
    @AppStorage("has_seen_feature_tour") private var storedHasSeenFeatureTour: Bool = false
    @AppStorage("calculation_count") private var storedCalculationCount: Int = 0
    @AppStorage("has_requested_review") private var storedHasRequestedReview: Bool = false
    @AppStorage("remove_pdf_watermark") private var storedRemovePDFWatermark: Bool = false
    @AppStorage("add_custom_name_to_pdf") private var storedAddCustomNameToPDF: Bool = false
    @AppStorage("custom_pdf_name") private var storedCustomPDFName: String = ""

    var selectedCountry: Country {
        get { storedSelectedCountry }
        set { storedSelectedCountry = newValue }
    }

    var appLanguage: AppLanguage {
        get { storedAppLanguage }
        set { 
            storedAppLanguage = newValue
            L10n.clearCache()
        }
    }

    var hasCompletedOnboarding: Bool {
        get { storedHasCompletedOnboarding }
        set { storedHasCompletedOnboarding = newValue }
    }
    
    var appearance: AppAppearance {
        get { AppAppearance(rawValue: storedAppearance) ?? .system }
        set { storedAppearance = newValue.rawValue }
    }
    
    var hasSeenFeatureTour: Bool {
        get { storedHasSeenFeatureTour }
        set { storedHasSeenFeatureTour = newValue }
    }
    
    var calculationCount: Int {
        get { storedCalculationCount }
        set {
            let val = newValue
            DispatchQueue.main.async { self.storedCalculationCount = val }
        }
    }
    
    var removePDFWatermark: Bool {
        get { storedRemovePDFWatermark }
        set { 
            storedRemovePDFWatermark = newValue
            Task { await syncPDFSettingToSupabase(key: "remove_pdf_watermark", boolValue: newValue) }
        }
    }
    
    var addCustomNameToPDF: Bool {
        get { storedAddCustomNameToPDF }
        set { 
            storedAddCustomNameToPDF = newValue
            Task { await syncPDFSettingToSupabase(key: "add_custom_name_to_pdf", boolValue: newValue) }
        }
    }
    
    var customPDFName: String {
        get { storedCustomPDFName }
        set { 
            storedCustomPDFName = newValue
            Task { await syncPDFStringToSupabase(key: "custom_pdf_name", stringValue: newValue) }
        }
    }
    
    var hasRequestedReview: Bool {
        get { storedHasRequestedReview }
        set { storedHasRequestedReview = newValue }
    }
    
    func incrementCalculationCount() {
        DispatchQueue.main.async {
            self.calculationCount += 1
        }
    }
    
    private init() {
        Task { await fetchPDFSettingsFromSupabase() }
    }
    
    // MARK: - PDF Settings Sync with Supabase
    
    func fetchPDFSettingsFromSupabase() async {
        guard let userId = await getCurrentUserId() else { return }
        
        do {
            let response: [UserProfile] = try await SupabaseManager.client.from("profiles")
                .select("remove_pdf_watermark, add_custom_name_to_pdf, custom_pdf_name")
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            
            if let profile = response.first {
                await MainActor.run {
                    if let val = profile.removePdfWatermark, val != storedRemovePDFWatermark {
                        storedRemovePDFWatermark = val
                    }
                    if let val = profile.addCustomNameToPdf, val != storedAddCustomNameToPDF {
                        storedAddCustomNameToPDF = val
                    }
                    if let val = profile.customPdfName, val != storedCustomPDFName {
                        storedCustomPDFName = val
                    }
                }
            }
        } catch {
            print("SettingsManager: Failed to fetch PDF settings: \(error)")
        }
    }
    
    private func syncPDFSettingToSupabase(key: String, boolValue: Bool) async {
        guard let userId = await getCurrentUserId() else { return }
        
        do {
            let data: [String: AnyJSON] = [
                "id": AnyJSON.string(userId.uuidString),
                key: AnyJSON.bool(boolValue),
                "updated_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
            ]
            
            try await SupabaseManager.client.from("profiles")
                .upsert(data)
                .execute()
        } catch {
            print("SettingsManager: Failed to sync \(key): \(error)")
        }
    }
    
    private func syncPDFStringToSupabase(key: String, stringValue: String) async {
        guard let userId = await getCurrentUserId() else { return }
        
        do {
            let data: [String: AnyJSON] = [
                "id": AnyJSON.string(userId.uuidString),
                key: AnyJSON.string(stringValue),
                "updated_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
            ]
            
            try await SupabaseManager.client.from("profiles")
                .upsert(data)
                .execute()
        } catch {
            print("SettingsManager: Failed to sync \(key): \(error)")
        }
    }
    
    private func getCurrentUserId() async -> UUID? {
        do {
            let session = try await SupabaseManager.client.auth.session
            return session.user.id
        } catch {
            return nil
        }
    }
}
