import SwiftUI
import GoogleSignIn

@main
struct LoanPro2025App: App {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var authService = AuthService.shared
    
    init() {
        AdService.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !settings.hasCompletedOnboarding {
                    CountrySelectionView(isInitialSetup: true)
                } else if !settings.hasSeenFeatureTour {
                    FeatureTourView()
                } else {
                    HomeView()
                }
            }
            .preferredColorScheme(settings.appearance.colorScheme)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
