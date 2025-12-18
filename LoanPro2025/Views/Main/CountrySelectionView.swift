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
        VStack(spacing: 30) {
            if isInitialSetup {
                VStack(spacing: 12) {
                    Text("Welcome to LoanPro 2025")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.black)
                        .multilineTextAlignment(.center)
                    
                    Text("Select your country to apply local banking regulations and tax rules.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)
            }
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Country.allCases) { country in
                    Button(action: {
                        settings.selectedCountry = country
                        HapticService.shared.notification(type: .success)
                    }) {
                        VStack(spacing: 12) {
                            Text(country.flag)
                                .font(.system(size: 40))
                            
                            Text(country.rawValue)
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(settings.selectedCountry == country ? .white : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(settings.selectedCountry == country ? Color.indigo : Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(settings.selectedCountry == country ? Color.indigo : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            if isInitialSetup {
                Button(action: {
                    settings.hasCompletedOnboarding = true
                }) {
                    Text("Continue")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(Color.indigo)
                        .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }
}
