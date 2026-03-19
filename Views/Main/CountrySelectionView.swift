import SwiftUI

struct CountrySelectionView: View {
    @ObservedObject var settings = SettingsManager.shared
    @Environment(\.dismiss) var dismiss
    var isInitialSetup: Bool = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    if isInitialSetup {
                        VStack(spacing: 8) {
                            Text(L10n.welcome)
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .multilineTextAlignment(.center)
                            
                            Text(L10n.selectCountrySubtitle)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .padding(.top, 24)
                    }
                    
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Country.allCases) { country in
                            Button(action: {
                                settings.selectedCountry = country
                                settings.appLanguage = country.defaultLanguage
                                HapticService.shared.notification(type: .success)
                            }) {
                                VStack(spacing: 8) {
                                    Text(country.flag)
                                        .font(.system(size: 32))
                                    
                                    Text(country.rawValue)
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(settings.selectedCountry == country ? .white : .primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(settings.selectedCountry == country ? Color.indigo : Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(settings.selectedCountry == country ? Color.indigo : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.appLanguage)
                            .font(.system(.headline, design: .rounded))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(AppLanguage.allCases) { language in
                                    Button(action: {
                                        settings.appLanguage = language
                                        HapticService.shared.impact(style: .light)
                                    }) {
                                        HStack(spacing: 8) {
                                            Text(language.flag)
                                            Text(language.displayName)
                                                .font(.system(.subheadline, design: .rounded))
                                                .fontWeight(.semibold)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(settings.appLanguage == language ? Color.indigo : Color(uiColor: .secondarySystemGroupedBackground))
                                        .foregroundColor(settings.appLanguage == language ? .white : .primary)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            
            if isInitialSetup {
                Button(action: {
                    settings.hasCompletedOnboarding = true
                }) {
                    Text(L10n.continueButton)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(Color.indigo)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(uiColor: .systemGroupedBackground))
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(isInitialSetup ? "" : "Select Country")
        .navigationBarTitleDisplayMode(.inline)
    }
}
