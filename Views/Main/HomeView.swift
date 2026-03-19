import SwiftUI

struct HomeView: View {
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var adService = AdService.shared
    @ObservedObject var authService = AuthService.shared
    @ObservedObject var storageService = CalculationStorageService.shared
    @State private var showingCountryPicker = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var filteredCalculators: [CalculatorType] {
        CalculatorType.allCases.filter { $0.supportedCountries.contains(settings.selectedCountry) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            headerSection
                            
                            // Recent saved calculations
                            if authService.isAuthenticated && !storageService.recentCalculations.isEmpty {
                                recentCalculationsSection
                            }
                            
                            LazyVGrid(columns: columns, spacing: 16) {
                                let calculators = filteredCalculators
                                ForEach(Array(calculators.enumerated()), id: \.element.id) { index, type in
                                    NavigationLink(destination: destinationView(for: type)) {
                                        CalculatorCard(type: type)
                                    }
                                    
                                    // Insert native ad after every 4 calculator cards (if not pro)
                                    if (index + 1) % 4 == 0 && adService.isNativeAdReady && !StoreKitManager.shared.isPro {
                                        NativeAdCardView()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Sticky banner ad at bottom
                                    if !StoreKitManager.shared.isPro {
                                        BannerAdView()
                                            .frame(height: 50)
                                            .background(Color(uiColor: .systemGroupedBackground))
                                    }
                }
            }
            .id(settings.appLanguage)
            .navigationTitle("LoanPro 2025")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 12) {
                        if !StoreKitManager.shared.isPro {
                            CoinWalletView()
                        }
                        
                        if authService.isAuthenticated {
                            NavigationLink(destination: HistoryView()) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.title3)
                                    .foregroundColor(.indigo)
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundColor(.indigo)
                        }
                        
                        Button(action: {
                            showingCountryPicker = true
                        }) {
                            Text(settings.selectedCountry.flag)
                                .font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCountryPicker) {
                NavigationStack {
                    CountrySelectionView(isInitialSetup: false)
                        .navigationTitle(L10n.selectCountry)
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
            .task {
                if authService.isAuthenticated {
                    await storageService.loadCalculations()
                }
            }
        }
    }
    
    @ViewBuilder
    func destinationView(for type: CalculatorType) -> some View {
        if type == .debtPayoff {
            DebtPayoffView()
        } else {
            CalculatorView(type: type)
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
    
    // MARK: - Recent Calculations
    var recentCalculationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink(destination: HistoryView()) {
                    Text("See All")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.indigo)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(storageService.recentCalculations) { calc in
                        NavigationLink {
                            restoredView(for: calc)
                        } label: {
                            RecentCalcCard(calculation: calc)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func restoredView(for calc: SavedCalculation) -> some View {
        let type = CalculatorType(rawValue: calc.calculatorType) ?? .simple
        let vm = CalculatorViewModel(type: type)
        calc.restore(to: vm)
        return CalculatorView(type: type, restoredViewModel: vm)
    }
}

// MARK: - Recent Calculation Card
struct RecentCalcCard: View {
    let calculation: SavedCalculation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: calculation.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.indigo)
                
                if calculation.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }
            }
            
            Text(calculation.name)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text(calculation.summaryValue)
                .font(.system(.caption2, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.indigo)
        }
        .frame(width: 130, alignment: .leading)
        .padding(12)
        .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterial))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.indigo.opacity(0.1), lineWidth: 1)
        )
    }
}

struct CalculatorCard: View {
    let type: CalculatorType
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(.indigo)
            
            Text(type.localizedName)
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
