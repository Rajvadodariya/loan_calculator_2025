import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @AppStorage("selected_country") var selectedCountry: Country = .usa
    @AppStorage("has_completed_onboarding") var hasCompletedOnboarding: Bool = false
    
    private init() {}
}
