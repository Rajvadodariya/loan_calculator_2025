import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var storeKit = StoreKitManager.shared
    @State private var showSignIn = false
    
    var body: some View {
        List {
            // Account section
            Section(header: Text(L10n.string("account"))) {
                if authService.isAuthenticated {
                    NavigationLink(destination: ProfileView()) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.indigo, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 40, height: 40)
                                
                                Text(authService.userInitial)
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(authService.userDisplayName)
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.semibold)
                                Text(authService.userEmail)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    Button(action: { showSignIn = true }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.indigo.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "person.fill")
                                    .foregroundColor(.indigo)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.string("sign_in"))
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text(L10n.string("sign_in_benefits"))
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // LoanPro+ section
            Section {
                if storeKit.isPro {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LoanPro+")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                            Text("Active subscription")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        Text("PRO")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(6)
                    }
                    .padding(.vertical, 4)
                } else {
                    NavigationLink(destination: ProUpgradeView()) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Upgrade to LoanPro+")
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Text("No ads, unlimited saves, free exports")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
Section(header: Text(L10n.preferences)) {
                 NavigationLink(destination: CountrySelectionView(isInitialSetup: false)) {
                     HStack {
                         Label(L10n.country, systemImage: "globe")
                         Spacer()
                         Text(settings.selectedCountry.rawValue)
                             .foregroundColor(.secondary)
                     }
                 }
                 
                 NavigationLink(destination: LanguageSelectionView()) {
                     HStack {
                         Label(L10n.language, systemImage: "character.bubble.fill")
                         Spacer()
                         Text("\(settings.appLanguage.flag) \(settings.appLanguage.displayName)")
                             .foregroundColor(.secondary)
                     }
                 }
                 
                 // Appearance picker
                 HStack {
                     Label(L10n.string("appearance"), systemImage: settings.appearance.icon)
                     Spacer()
                     Picker("", selection: Binding(
                         get: { settings.appearance },
                         set: { settings.appearance = $0 }
                     )) {
                         ForEach(AppAppearance.allCases, id: \.self) { mode in
                             Text(mode.localizedName).tag(mode)
                         }
                     }
                     .pickerStyle(.menu)
                     .tint(.indigo)
                 }
             }
             
             // PDF Customization Section (Pro only)
             if storeKit.isPro {
                 Section(header: Text("PDF Customization")) {
                     Toggle(isOn: $settings.removePDFWatermark) {
                         HStack {
                             Label("Remove Watermark", systemImage: "nosign")
                         }
                     }
                     
                     Toggle(isOn: $settings.addCustomNameToPDF) {
                         HStack {
                             Label("Add Name/Logo", systemImage: "text.badge.plus")
                         }
                     }
                     
                     if settings.addCustomNameToPDF {
                         TextField("Your Name or Business", text: $settings.customPDFName)
                             .textFieldStyle(.roundedBorder)
                             .padding(.vertical, 4)
                     }
                 }
             }
             
             Section(header: Text(L10n.howToUse)) {
                NavigationLink(destination: HowToUseView()) {
                    Label(L10n.howToUse, systemImage: "book.fill")
                }
            }
            
            Section(header: Text(L10n.supportFeedback)) {
                NavigationLink(destination: SupportView()) {
                    Label(L10n.getSupport, systemImage: "questionmark.circle.fill")
                }
                
                Button(action: shareApp) {
                    Label(L10n.shareApp, systemImage: "square.and.arrow.up")
                }
                
                Button(action: rateApp) {
                    Label(L10n.rateApp, systemImage: "star.fill")
                }
            }
            
            Section(header: Text(L10n.legal)) {
                NavigationLink(destination: PrivacyPolicyView()) {
                    Label(L10n.privacyPolicy, systemImage: "lock.shield.fill")
                }
                
                Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                    Label(L10n.termsOfService, systemImage: "doc.text.fill")
                }
            }
            
            Section(header: Text(L10n.appInfo), footer: Text("© 2025 LoanPro Team. All rights reserved.")) {
                HStack {
                    Text(L10n.version)
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(L10n.settings)
        .sheet(isPresented: $showSignIn) {
            SignInView()
        }
    }
    
    private func shareApp() {
        let text = "Check out LoanPro 2025 - The smartest way to calculate your loans!"
        let url = URL(string: "https://apps.apple.com/app/idYOUR_ID")!
        let activityVC = UIActivityViewController(activityItems: [text, url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func rateApp() {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/idYOUR_ID?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
}
