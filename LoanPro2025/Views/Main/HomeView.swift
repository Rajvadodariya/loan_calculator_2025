import SwiftUI

struct HomeView: View {
    @ObservedObject var settings = SettingsManager.shared
    @State private var showingCountryPicker = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(CalculatorType.allCases) { type in
                                NavigationLink(destination: CalculatorView(type: type)) {
                                    CalculatorCard(type: type)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("LoanPro 2025")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCountryPicker = true
                    }) {
                        Text(settings.selectedCountry.flag)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingCountryPicker) {
                NavigationView {
                    CountrySelectionView(isInitialSetup: false)
                        .navigationTitle("Select Country")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingCountryPicker = false
                                }
                            }
                        }
                }
            }
        }
    }
    
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(settings.selectedCountry.rawValue) Edition")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.indigo)
            
            Text("Smart Loan Intelligence")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.black)
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

struct CalculatorCard: View {
    let type: CalculatorType
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(.indigo)
            
            Text(type.rawValue)
                .font(.system(.body, design: .rounded))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterial))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.indigo.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}
