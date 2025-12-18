import SwiftUI

@main
struct LoanPro2025App: App {
    @ObservedObject var settings = SettingsManager.shared
    
    var body: some Scene {
        WindowGroup {
            if !settings.hasCompletedOnboarding {
                CountrySelectionView(isInitialSetup: true)
                    .preferredColorScheme(.light)
            } else {
                HomeView()
                    .preferredColorScheme(.light)
            }
        }
    }
}
