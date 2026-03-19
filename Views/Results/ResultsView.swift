import SwiftUI
import Charts

// Chart helper structs — must be outside ViewBuilder closures
private struct ChartSlice: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let percentage: Double
    let color: Color
}

private struct SeriesPoint: Identifiable {
    let id = UUID()
    let year: Int
    let value: Double
    let series: String
}

private struct BalancePoint: Identifiable {
    let id = UUID()
    let year: Int
    let balance: Double
}

private struct RentBuyChartPoint: Identifiable {
    let id = UUID()
    let year: Int
    let value: Double
    let series: String
}

struct ResultsView: View {
    @ObservedObject var viewModel: CalculatorViewModel
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var coinManager = CoinManager.shared
    @ObservedObject var adService = AdService.shared
    @ObservedObject var authService = AuthService.shared
    @State private var showFullSchedule = false
    @State private var viewMode: AmortizationViewMode = .monthly
    @State private var hasUnlockedFullSchedule = false
    @State private var showCoinAlert = false
    @State private var pendingExportType: ExportType?
    @State private var showSaveSheet = false
    @State private var chartMode: ChartViewMode = .breakdown
    
    enum ChartViewMode: String, CaseIterable {
        case breakdown = "Breakdown"
        case trend = "Trend"
        case balance = "Balance"
    }
    
    @State private var shareItem: ShareItem?
    
    struct ShareItem: Identifiable {
        let id = UUID()
        let items: [Any]
    }
    
    enum AmortizationViewMode {
        case monthly, yearly
    }
    
    enum ExportType {
        case pdf, csv
        var cost: Int {
            switch self {
            case .pdf: return CoinManager.pdfCost
            case .csv: return CoinManager.csvCost
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.calculatorType == .eligibility {
                    eligibilityBreakdown
                }
                
                if let result = viewModel.result {
                    // Rent vs Buy specific results
                    if viewModel.calculatorType == .rentVsBuy, let rvb = viewModel.rentVsBuyResult {
                        rentVsBuyResultsSection(rvb: rvb)
                    }
                    
                    if viewModel.extraMonthlyPayment > 0 && viewModel.interestSaved > 0 {
                        savingsCard
                    }
                    
                    // Extra Payment Simulator
                    if supportsExtraPayment {
                        extraPaymentSimulator
                    }
                    
                    summaryCards(result: result)
                    
                    if hasAdditionalDetails {
                        calculatorSpecificDetails
                    }
                    
                    chartSection(result: result)
                    
                    // Smart Tips
                    smartTipsSection
                    
                    amortizationSection(result: result)
                } else if viewModel.calculatorType == .stampDuty {
                    stampDutyAnalysis
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .id(settings.appLanguage) // Force refresh on language change
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(L10n.analysis)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Save calculation button (authenticated users only)
                    if authService.isAuthenticated {
                        Button(action: { showSaveSheet = true }) {
                            Image(systemName: "bookmark")
                        }
                    }
                    
                    if let res = viewModel.result {
                    Menu {
                        // 1. Snapshot as Text (FREE — core functionality)
                        Button {
                            let text = ExportService.shared.generateTextSummary(viewModel: viewModel)
                            let source = ShareActivityItemSource(item: text, title: "Loan Summary")
                            shareItem = ShareItem(items: [source])
                        } label: {
                            Label(L10n.share, systemImage: "doc.text")
                        }
                        
                        Divider()
                        
                        // 2. Amortization Details (COIN-GATED)
                        Menu {
                            Button {
                                attemptExport(.pdf) {
                                    if let url = ExportService.shared.generatePDF(for: viewModel, includeSchedule: true) {
                                        let source = ShareActivityItemSource(item: url, title: "Amortization Schedule (PDF)")
                                        shareItem = ShareItem(items: [source])
                                    }
                                }
                            } label: {
                                let label = StoreKitManager.shared.isPro ? L10n.shareAsPDF : "\(L10n.shareAsPDF) (\(CoinManager.pdfCost) 🪙)"
                                Label(label, systemImage: "doc.richtext")
                            }
                            
                            Button {
                                attemptExport(.csv) {
                                    if let url = ExportService.shared.generateCSV(for: viewModel, includeSummary: false) {
                                        let source = ShareActivityItemSource(item: url, title: "Amortization Schedule (CSV)")
                                        shareItem = ShareItem(items: [source])
                                    }
                                }
                            } label: {
                                let label = StoreKitManager.shared.isPro ? L10n.shareAsExcel : "\(L10n.shareAsExcel) (\(CoinManager.csvCost) 🪙)"
                                Label(label, systemImage: "tablecells")
                            }
                        } label: {
                            Label(L10n.shareAmortization, systemImage: "list.bullet.rectangle")
                        }
                        
                        // 3. All Details (COIN-GATED)
                        Menu {
                            Button {
                                attemptExport(.pdf) {
                                    if let url = ExportService.shared.generatePDF(for: viewModel, includeSchedule: true) {
                                        let source = ShareActivityItemSource(item: url, title: "Loan Analysis Report (PDF)")
                                        shareItem = ShareItem(items: [source])
                                    }
                                }
                            } label: {
                                let label = StoreKitManager.shared.isPro ? L10n.shareAsPDF : "\(L10n.shareAsPDF) (\(CoinManager.pdfCost) 🪙)"
                                Label(label, systemImage: "doc.richtext")
                            }
                            
                            Button {
                                attemptExport(.csv) {
                                    if let url = ExportService.shared.generateCSV(for: viewModel, includeSummary: true) {
                                        let source = ShareActivityItemSource(item: url, title: "Loan Analysis Report (CSV)")
                                        shareItem = ShareItem(items: [source])
                                    }
                                }
                            } label: {
                                let label = StoreKitManager.shared.isPro ? L10n.shareAsExcel : "\(L10n.shareAsExcel) (\(CoinManager.csvCost) 🪙)"
                                Label(label, systemImage: "tablecells")
                            }
                        } label: {
                            Label(L10n.shareFullReport, systemImage: "doc.zipper")
                        }
                        
                        Divider()
                        
                        // Original Image Export
                        let shareView = ExportSummaryView(viewModel: viewModel, result: res)
                        let renderer = ImageRenderer(content: shareView)
                        let _ = { renderer.scale = 3.0 }()
                        if let image = renderer.uiImage {
                            ShareLink(item: Image(uiImage: image), preview: SharePreview(L10n.analysis, image: Image(uiImage: image))) {
                                Label(L10n.shareAsImage, systemImage: "photo")
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    }
                }
            }
        }
        .sheet(isPresented: $showSaveSheet) {
            SaveCalculationSheet(viewModel: viewModel)
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: item.items)
        }
        .alert(L10n.string("not_enough_coins"), isPresented: $showCoinAlert) {
            Button(L10n.string("earn_coins_button"), role: .none) {
                adService.showRewarded { success in
                    if success {
                        coinManager.earnCoins()
                        HapticService.shared.impact(style: .heavy)
                        // Retry the pending export after earning coins
                        if let exportType = pendingExportType {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                retryPendingExport(exportType)
                            }
                        }
                    }
                }
            }
            Button(L10n.string("cancel"), role: .cancel) {
                pendingExportType = nil
            }
        } message: {
            Text(L10n.string("watch_ad_for_coins"))
        }
    }
    
    // MARK: - Coin Export Helpers
    private func attemptExport(_ type: ExportType, action: @escaping () -> Void) {
        if coinManager.canAfford(type.cost) {
            if coinManager.spendCoins(type.cost) {
                HapticService.shared.impact(style: .medium)
                action()
            }
        } else {
            pendingExportType = type
            showCoinAlert = true
        }
    }
    
    private func retryPendingExport(_ type: ExportType) {
        guard coinManager.canAfford(type.cost) else { return }
        if coinManager.spendCoins(type.cost) {
            HapticService.shared.impact(style: .medium)
            switch type {
            case .pdf:
                if let url = ExportService.shared.generatePDF(for: viewModel, includeSchedule: true) {
                    let source = ShareActivityItemSource(item: url, title: "Report (PDF)")
                    shareItem = ShareItem(items: [source])
                }
            case .csv:
                if let url = ExportService.shared.generateCSV(for: viewModel, includeSummary: true) {
                    let source = ShareActivityItemSource(item: url, title: "Report (CSV)")
                    shareItem = ShareItem(items: [source])
                }
            }
        }
        pendingExportType = nil
    }
    
    var savingsCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.interestSaved)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.green)
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            
            Divider()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text(L10n.interestSaved)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(CurrencyFormatter.format(amount: viewModel.interestSaved, country: viewModel.selectedCountry))
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.black)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(L10n.timeSaved)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    let years = viewModel.monthsSaved / 12
                    let months = viewModel.monthsSaved % 12
                    Text(years > 0 ? "\(years)y \(months)m" : "\(months) \(L10n.months.lowercased())")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.black)
                        .foregroundColor(.indigo)
                }
            }
        }
        .padding()
        .background(
            ZStack {
                Color.green.opacity(0.05)
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
            }
        )
        .cornerRadius(20)
    }
    
    // MARK: - Rent vs Buy Results
    func rentVsBuyResultsSection(rvb: RentVsBuyResult) -> some View {
        VStack(spacing: 16) {
            // Verdict Card
            VStack(spacing: 8) {
                Image(systemName: rvb.breakEvenYear != nil ? "house.fill" : "building.2.fill")
                    .font(.system(size: 36))
                    .foregroundColor(rvb.breakEvenYear != nil ? .green : .orange)
                
                Text(L10n.string("rent_vs_buy_verdict"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let breakEven = rvb.breakEvenYear {
                    Text(String(format: L10n.string("better_to_buy"), breakEven))
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                } else {
                    Text(L10n.string("better_to_rent"))
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill((rvb.breakEvenYear != nil ? Color.green : Color.orange).opacity(0.08))
            )
            
            // Cost Comparison Cards
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "building.2")
                            .foregroundColor(.orange)
                        Text(L10n.string("renting"))
                            .font(.caption)
                    }
                    Text(CurrencyFormatter.format(amount: rvb.totalRentCost, country: viewModel.selectedCountry))
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "house.fill")
                            .foregroundColor(.indigo)
                        Text(L10n.string("buying"))
                            .font(.caption)
                    }
                    Text(CurrencyFormatter.format(amount: rvb.totalBuyCost, country: viewModel.selectedCountry))
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.indigo)
                    Text("\(L10n.string("equity_built")): \(CurrencyFormatter.format(amount: rvb.buyEquity, country: viewModel.selectedCountry))")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
            
            // Comparison Line Chart
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.string("cumulative_cost"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                let rentLabel = L10n.string("renting")
                let buyLabel = L10n.string("buying")
                
                let chartData: [RentBuyChartPoint] = rvb.yearlyComparison.flatMap { snapshot in
                    [
                        RentBuyChartPoint(year: snapshot.year, value: snapshot.cumulativeRent, series: rentLabel),
                        RentBuyChartPoint(year: snapshot.year, value: snapshot.cumulativeBuy, series: buyLabel)
                    ]
                }
                
                Chart {
                    ForEach(chartData) { point in
                        LineMark(
                            x: .value(L10n.year, point.year),
                            y: .value("Cost", point.value)
                        )
                        .foregroundStyle(by: .value("Series", point.series))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.monotone)
                    }
                    
                    if let breakEven = rvb.breakEvenYear {
                        RuleMark(x: .value("Break-Even", breakEven))
                            .foregroundStyle(Color.green)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                            .annotation(position: .top, alignment: .center) {
                                Text("Year \(breakEven)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                    }
                }
                .chartForegroundStyleScale([
                    rentLabel: Color.orange,
                    buyLabel: Color.indigo
                ])
                .frame(height: 220)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    // MARK: - Extra Payment Simulator
    private var supportsExtraPayment: Bool {
        ![.eligibility, .stampDuty, .comparison, .reverse].contains(viewModel.calculatorType)
    }
    
    var extraPaymentSimulator: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.string("extra_payment_simulator"))
                        .font(.system(.headline, design: .rounded))
                    Text(L10n.string("simulator_hint"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "slider.horizontal.below.rectangle")
                    .font(.title2)
                    .foregroundColor(.indigo)
            }
            
            HStack {
                Text(CurrencyFormatter.format(amount: viewModel.extraMonthlyPayment, country: viewModel.selectedCountry))
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(.green)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: viewModel.extraMonthlyPayment)
                Spacer()
            }
            
            Slider(value: $viewModel.extraMonthlyPayment, in: 0...viewModel.selectedCountry.maxMonthlyBudget / 2, step: viewModel.selectedCountry.extraPaymentStep)
                .accentColor(.green)
                .onChange(of: viewModel.extraMonthlyPayment) { _, _ in
                    HapticService.shared.impact(style: .light)
                }
            
            if viewModel.extraMonthlyPayment > 0 && viewModel.interestSaved > 0 {
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Image(systemName: "indianrupeesign.circle.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                        Text(CurrencyFormatter.format(amount: viewModel.interestSaved, country: viewModel.selectedCountry))
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.green)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: viewModel.interestSaved)
                        Text(L10n.interestSaved)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.title3)
                            .foregroundColor(.indigo)
                        let years = viewModel.monthsSaved / 12
                        let months = viewModel.monthsSaved % 12
                        Text(years > 0 ? "\(years)y \(months)m" : "\(months) \(L10n.months.lowercased())")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.indigo)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: viewModel.monthsSaved)
                        Text(L10n.timeSaved)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    if let result = viewModel.result {
                        VStack(spacing: 4) {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.title3)
                                .foregroundColor(.mint)
                            Text(result.payoffDate, style: .date)
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.black)
                                .foregroundColor(.mint)
                            Text(L10n.string("new_payoff_date"))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            ZStack {
                Color.green.opacity(0.03)
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.green.opacity(0.15), lineWidth: 1)
            }
        )
        .cornerRadius(20)
    }
    
    // MARK: - Smart Tips
    var smartTipsSection: some View {
        let tips = generateSmartTips()
        return Group {
            if !tips.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text(L10n.string("smart_tips"))
                            .font(.headline)
                    }
                    
                    ForEach(tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "sparkle")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.top, 2)
                            Text(tip)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.05))
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
        }
    }
    
    private func generateSmartTips() -> [String] {
        var tips: [String] = []
        guard let result = viewModel.result else { return tips }
        
        // Tip: No extra payment
        if viewModel.extraMonthlyPayment == 0 && supportsExtraPayment {
            tips.append(L10n.string("tip_no_extra_payment"))
        }
        
        // Tip: High interest rate
        if viewModel.interestRate > 7.0 {
            tips.append(String(format: L10n.string("tip_high_interest"), viewModel.interestRate))
        }
        
        // Tip: Long loan term
        if viewModel.loanTermYears >= 25 {
            tips.append(L10n.string("tip_long_term"))
        }
        
        // Tip: Interest > Principal
        if result.totalInterest > result.principalAmount {
            let shorterYears = max(10, viewModel.loanTermYears / 2)
            let hypothetical = CalculationService.shared.calculateLoan(
                amount: result.principalAmount,
                annualRate: viewModel.interestRate,
                years: shorterYears,
                country: viewModel.selectedCountry,
                type: .simple
            )
            let savings = result.totalInterest - hypothetical.totalInterest
            if savings > 0 {
                tips.append(String(format: L10n.string("tip_shorter_term"), shorterYears, CurrencyFormatter.format(amount: savings, country: viewModel.selectedCountry)))
            }
        }
        
        return Array(tips.prefix(3)) // Max 3 tips
    }
    
    var eligibilityBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.eligibilityAnalysisTitle)
                .font(.headline)
            
            VStack(spacing: 12) {
                AnalysisRow(title: L10n.grossMonthlyIncome, value: CurrencyFormatter.format(amount: viewModel.grossMonthlyIncome, country: viewModel.selectedCountry))
                AnalysisRow(title: L10n.maxEmiAllowed, value: CurrencyFormatter.format(amount: viewModel.grossMonthlyIncome * 0.28, country: viewModel.selectedCountry))
                AnalysisRow(title: L10n.existingMonthlyDebts, value: CurrencyFormatter.format(amount: viewModel.monthlyDebts, country: viewModel.selectedCountry))
                
                Divider()
                
                AnalysisRow(title: L10n.netMonthlyForLoan, value: CurrencyFormatter.format(amount: viewModel.maxMonthlyEMI, country: viewModel.selectedCountry), isHighlighted: true)
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(12)
            
            Text(L10n.string("formula_eligibility"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    var stampDutyAnalysis: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.taxBreakdown)
                .font(.headline)
            
            ResultCard(title: L10n.estimatedStampDuty, value: CurrencyFormatter.format(amount: viewModel.stampDutyAmount, country: viewModel.selectedCountry), icon: "building.columns", color: .green)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.useManualTaxRate ? L10n.appliedCustomRate : L10n.calculationBasis)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.useManualTaxRate ? .orange : .primary)
                
                let manualDesc: String = {
                    let val = String(format: "%.2f", viewModel.manualTaxRate)
                    let base = String(format: "%.0f", viewModel.taxUnitBase)
                    switch viewModel.customTaxType {
                    case .percentage: return L10n.string("calculating_as_prefix") + " \(val)% " + L10n.string("property_value")
                    case .amountPerUnit: return L10n.string("calculating_as_prefix") + " \(val) " + L10n.string("for_every") + " \(viewModel.selectedCountry.currencySymbol)\(base) " + L10n.string("property_value")
                    case .flat: return L10n.string("flat_fee_amount") + ": " + CurrencyFormatter.format(amount: viewModel.manualTaxRate, country: viewModel.selectedCountry)
                    }
                }()
                
                Text(viewModel.useManualTaxRate ? manualDesc : viewModel.selectedCountry.stampDutyBasis)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
            .padding(.top, 4)
            
            Text(viewModel.selectedCountry.stampDutyBasis)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    
    private var hasAdditionalDetails: Bool {
        switch viewModel.calculatorType {
        case .auto, .rv:
            return viewModel.tradeInValue > 0 || viewModel.salesTaxRate > 0 || viewModel.registrationFees > 0
        case .home, .fha:
            return viewModel.propertyTax > 0 || viewModel.homeInsurance > 0 || viewModel.hoaFees > 0
        case .student:
            return viewModel.gracePeriodMonths > 0
        default:
            return false
        }
    }
    
    var calculatorSpecificDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(detailsTitle)
                .font(.headline)
            
            VStack(spacing: 12) {
                switch viewModel.calculatorType {
                case .auto, .rv:
                    if viewModel.tradeInValue > 0 {
                        AnalysisRow(title: L10n.tradeInValue, value: CurrencyFormatter.format(amount: viewModel.tradeInValue, country: viewModel.selectedCountry))
                    }
                    if viewModel.salesTaxRate > 0 {
                        AnalysisRow(title: L10n.salesTax, value: CurrencyFormatter.format(amount: viewModel.loanAmount * (viewModel.salesTaxRate / 100), country: viewModel.selectedCountry) + " (\(String(format: "%.1f", viewModel.salesTaxRate))%)")
                    }
                    if viewModel.registrationFees > 0 {
                        AnalysisRow(title: L10n.registrationFees, value: CurrencyFormatter.format(amount: viewModel.registrationFees, country: viewModel.selectedCountry))
                    }
                    
                case .home, .fha:
                    if viewModel.propertyTax > 0 {
                        AnalysisRow(title: L10n.propertyTax, value: CurrencyFormatter.format(amount: viewModel.propertyTax, country: viewModel.selectedCountry) + L10n.string("per_month"))
                    }
                    if viewModel.homeInsurance > 0 {
                        AnalysisRow(title: L10n.homeInsurance, value: CurrencyFormatter.format(amount: viewModel.homeInsurance, country: viewModel.selectedCountry) + L10n.string("per_month"))
                    }
                    if viewModel.hoaFees > 0 {
                        AnalysisRow(title: L10n.hoaFees, value: CurrencyFormatter.format(amount: viewModel.hoaFees, country: viewModel.selectedCountry) + L10n.string("per_month"))
                    }
                    
                case .student:
                    AnalysisRow(title: L10n.gracePeriod, value: "\(viewModel.gracePeriodMonths) \(L10n.string("months_short"))")
                    
                default:
                    EmptyView()
                }
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    private var detailsTitle: String {
        switch viewModel.calculatorType {
        case .auto: return L10n.vehicleDetails
        case .rv: return L10n.rvDetails
        case .home, .fha: return L10n.monthlyEscrow
        case .student: return L10n.studentLoanDetails
        default: return L10n.string("summary")
        }
    }
    
    func summaryCards(result: LoanCalculation) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ResultCard(title: L10n.principal, value: CurrencyFormatter.format(amount: result.principalAmount, country: viewModel.selectedCountry), icon: "indianrupeesign.circle", color: .indigo)
                ResultCard(title: L10n.monthlyPayment, value: CurrencyFormatter.format(amount: result.monthlyPayment, country: viewModel.selectedCountry), icon: "calendar.badge.clock", color: .indigo)
            }
            
            HStack(spacing: 16) {
                ResultCard(title: L10n.totalInterest, value: CurrencyFormatter.format(amount: result.totalInterest, country: viewModel.selectedCountry), icon: "percent", color: .orange)
                ResultCard(title: L10n.totalTaxFees, value: CurrencyFormatter.format(amount: result.totalTax, country: viewModel.selectedCountry), icon: "building.columns", color: .red)
            }
            
            ResultCard(title: L10n.totalPayment, value: CurrencyFormatter.format(amount: result.totalPayment, country: viewModel.selectedCountry), icon: "creditcard.fill", color: .indigo)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(L10n.payoffDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(result.payoffDate, style: .date)
                        .font(.headline)
                }
                Spacer()
                Image(systemName: "calendar")
                    .foregroundColor(.indigo)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
    
    func chartSection(result: LoanCalculation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L10n.paymentBreakdown)
                    .font(.headline)
                Spacer()
            }
            
            Picker("Chart View", selection: $chartMode.animation(.easeInOut)) {
                ForEach(ChartViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            switch chartMode {
            case .breakdown:
                donutChart(result: result)
            case .trend:
                trendChart(result: result)
            case .balance:
                balanceChart(result: result)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    // MARK: - Donut Chart (Payment Breakdown)
    func donutChart(result: LoanCalculation) -> some View {
        let total = result.principalAmount + result.totalInterest + result.totalTax
        let principalPct = total > 0 ? (result.principalAmount / total) * 100 : 0
        let interestPct = total > 0 ? (result.totalInterest / total) * 100 : 0
        let taxPct = total > 0 ? (result.totalTax / total) * 100 : 0
        
        var slices: [ChartSlice] = [
            ChartSlice(label: L10n.principal, value: result.principalAmount, percentage: principalPct, color: .indigo),
            ChartSlice(label: L10n.interest, value: result.totalInterest, percentage: interestPct, color: .orange)
        ]
        if result.totalTax > 0 {
            slices.append(ChartSlice(label: L10n.totalTaxFees, value: result.totalTax, percentage: taxPct, color: .red))
        }
        
        return VStack(spacing: 16) {
            Chart(slices) { slice in
                SectorMark(
                    angle: .value(slice.label, slice.value),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(slice.color.gradient)
                .cornerRadius(4)
            }
            .frame(height: 220)
            
            // Legend
            VStack(spacing: 8) {
                ForEach(slices) { slice in
                    HStack {
                        Circle()
                            .fill(slice.color.gradient)
                            .frame(width: 10, height: 10)
                        Text(slice.label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f%%", slice.percentage))
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.bold)
                        Text(CurrencyFormatter.format(amount: slice.value, country: viewModel.selectedCountry))
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Trend Chart (Principal vs Interest over Time)
    func trendChart(result: LoanCalculation) -> some View {
        let schedule = result.amortizationSchedule
        let totalMonths = schedule.count
        let totalYears = max(1, totalMonths / 12 + (totalMonths % 12 > 0 ? 1 : 0))
        
        let principalLabel = L10n.principal
        let interestLabel = L10n.interest
        
        var allPoints: [SeriesPoint] = []
        for year in 1...totalYears {
            let startIndex = (year - 1) * 12
            let endIndex = min(year * 12, totalMonths)
            guard startIndex < endIndex else { break }
            
            let yearSlice = schedule[startIndex..<endIndex]
            let yearPrincipal = yearSlice.reduce(0) { $0 + $1.principal }
            let yearInterest = yearSlice.reduce(0) { $0 + $1.interest }
            
            allPoints.append(SeriesPoint(year: year, value: yearPrincipal, series: principalLabel))
            allPoints.append(SeriesPoint(year: year, value: yearInterest, series: interestLabel))
        }
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("\(principalLabel) vs \(interestLabel) / \(L10n.year)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Chart(allPoints) { point in
                LineMark(
                    x: .value(L10n.year, point.year),
                    y: .value("Amount", point.value)
                )
                .foregroundStyle(by: .value("Series", point.series))
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.monotone)
                .symbol(by: .value("Series", point.series))
            }
            .chartForegroundStyleScale([
                principalLabel: Color.indigo,
                interestLabel: Color.orange
            ])
            .frame(height: 220)
        }
    }
    
    // MARK: - Balance Paydown Chart
    func balanceChart(result: LoanCalculation) -> some View {
        let schedule = result.amortizationSchedule
        let totalMonths = schedule.count
        let totalYears = max(1, totalMonths / 12 + (totalMonths % 12 > 0 ? 1 : 0))
        
        var points: [BalancePoint] = [BalancePoint(year: 0, balance: result.principalAmount)]
        for year in 1...totalYears {
            let endIndex = min(year * 12, totalMonths) - 1
            guard endIndex >= 0 && endIndex < schedule.count else { break }
            points.append(BalancePoint(year: year, balance: schedule[endIndex].balance))
        }
        
        return VStack(alignment: .leading, spacing: 8) {
            Text(L10n.balance)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Chart(points) { point in
                AreaMark(
                    x: .value(L10n.year, point.year),
                    y: .value(L10n.balance, point.balance)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.indigo.opacity(0.4), Color.indigo.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.monotone)
                
                LineMark(
                    x: .value(L10n.year, point.year),
                    y: .value(L10n.balance, point.balance)
                )
                .foregroundStyle(Color.indigo)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.monotone)
            }
            .frame(height: 220)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(L10n.string("starting_balance"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(CurrencyFormatter.format(amount: result.principalAmount, country: viewModel.selectedCountry))
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(L10n.payoffDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(totalYears) \(L10n.years)")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    func amortizationSection(result: LoanCalculation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L10n.amortizationSchedule)
                    .font(.headline)
                Spacer()
                Picker("View Mode", selection: $viewMode) {
                    Text(L10n.monthly).tag(AmortizationViewMode.monthly)
                    Text(L10n.yearly).tag(AmortizationViewMode.yearly)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 160)
            }
            
            VStack(spacing: 0) {
                HStack {
                    Text(viewMode == .monthly ? "Mo" : "Yr").frame(width: 30, alignment: .leading)
                    Text(L10n.principal).frame(maxWidth: .infinity, alignment: .trailing)
                    Text(L10n.interest).frame(maxWidth: .infinity, alignment: .trailing)
                    Text(L10n.string("total")).frame(maxWidth: .infinity, alignment: .trailing)
                    Text(L10n.balance).frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
                
                Divider()
                
                let scheduleToShow: [AmortizationEntry] = {
                    if viewMode == .monthly {
                        return showFullSchedule ? result.amortizationSchedule : Array(result.amortizationSchedule.prefix(60))
                    } else {
                        // Aggregate by year
                        var yearly: [AmortizationEntry] = []
                        for year in 1...(result.amortizationSchedule.count / 12 + (result.amortizationSchedule.count % 12 > 0 ? 1 : 0)) {
                            let startIndex = (year - 1) * 12
                            let endIndex = min(year * 12, result.amortizationSchedule.count)
                            guard startIndex < endIndex else { break }
                            
                            let yearSlice = result.amortizationSchedule[startIndex..<endIndex]
                            let yearPrincipal = yearSlice.reduce(0) { $0 + $1.principal }
                            let yearInterest = yearSlice.reduce(0) { $0 + $1.interest }
                            let finalBalance = yearSlice.last?.balance ?? 0
                            
                            yearly.append(AmortizationEntry(
                                month: year, // Using month field as year number
                                principal: yearPrincipal,
                                interest: yearInterest,
                                tax: 0,
                                balance: finalBalance
                            ))
                        }
                        return yearly
                    }
                }()
                
                LazyVStack(spacing: 0) {
                    ForEach(scheduleToShow) { entry in
                        VStack(spacing: 0) {
                            HStack {
                                Text("\(entry.month)").frame(width: 30, alignment: .leading)
                                Text(formatCompact(entry.principal, country: viewModel.selectedCountry)).frame(maxWidth: .infinity, alignment: .trailing)
                                Text(formatCompact(entry.interest, country: viewModel.selectedCountry)).frame(maxWidth: .infinity, alignment: .trailing)
                                Text(formatCompact(entry.principal + entry.interest, country: viewModel.selectedCountry)).frame(maxWidth: .infinity, alignment: .trailing)
                                Text(formatCompact(entry.balance, country: viewModel.selectedCountry)).frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .padding(.vertical, 8)
                            
                            if viewMode == .monthly && entry.month % 12 == 0 {
                                Divider()
                                Text("Year \(entry.month / 12)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 4)
                            }
                            Divider()
                        }
                    }
                }
                
                if viewMode == .monthly && result.amortizationSchedule.count > 60 {
                    if showFullSchedule {
                        // Already unlocked — show collapse button
                        Button(action: {
                            withAnimation {
                                showFullSchedule = false
                            }
                        }) {
                            HStack {
                                Text(L10n.showAll)
                                Image(systemName: "chevron.up")
                            }
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.indigo)
                            .padding(.top)
                        }
                    } else if hasUnlockedFullSchedule || StoreKitManager.shared.isPro {
                        // Previously unlocked via reward ad OR pro user
                        Button(action: {
                            withAnimation {
                                showFullSchedule = true
                            }
                        }) {
                            HStack {
                                Text("\(L10n.showAll) (\(result.amortizationSchedule.count))")
                                Image(systemName: "chevron.down")
                            }
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.indigo)
                            .padding(.top)
                        }
                    } else {
                        // Gate behind reward ad
                        VStack(spacing: 8) {
                            Text(L10n.string("free_preview"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            RewardAdButton(
                                title: L10n.string("watch_ad_unlock"),
                                subtitle: L10n.string("full_schedule_unlock"),
                                icon: "play.circle.fill",
                                color: .indigo
                            ) {
                                withAnimation {
                                    hasUnlockedFullSchedule = true
                                    showFullSchedule = true
                                }
                                HapticService.shared.impact(style: .heavy)
                            }
                        }
                        .padding(.top)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    func formatCompact(_ value: Double, country: Country) -> String {
        let symbol = country.currencySymbol
        switch country {
        case .india:
            if value >= 10_000_000 {
                return String(format: "\(symbol)%.2f Cr", value / 10_000_000)
            } else if value >= 100_000 {
                return String(format: "\(symbol)%.2f L", value / 100_000)
            } else if value >= 1_000 {
                return String(format: "\(symbol)%.1fK", value / 1_000)
            } else {
                return String(format: "\(symbol)%.0f", value)
            }
        case .indonesia:
            if value >= 1_000_000_000 {
                return String(format: "\(symbol)%.1fB", value / 1_000_000_000)
            } else if value >= 1_000_000 {
                return String(format: "\(symbol)%.1fJt", value / 1_000_000) // Juta = Million in Indonesian
            } else if value >= 1_000 {
                return String(format: "\(symbol)%.1fRb", value / 1_000) // Ribu = Thousand
            } else {
                return String(format: "\(symbol)%.0f", value)
            }
        default:
            if value >= 1_000_000 {
                return String(format: "\(symbol)%.1fM", value / 1_000_000)
            } else if value >= 1_000 {
                return String(format: "\(symbol)%.1fK", value / 1_000)
            } else {
                return String(format: "\(symbol)%.0f", value)
            }
        }
    }
}

struct AnalysisRow: View {
    let title: String
    let value: String
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(isHighlighted ? .bold : .medium)
                .foregroundColor(isHighlighted ? .indigo : .primary)
        }
    }
}

struct ResultCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.headline)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

import LinkPresentation

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            // Ensure dismissal happens on the main thread after activity completes
            DispatchQueue.main.async {
                dismiss()
            }
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

class ShareActivityItemSource: NSObject, UIActivityItemSource {
    let item: Any
    let title: String
    
    init(item: Any, title: String) {
        self.item = item
        self.title = title
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return item
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return item
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        if let url = item as? URL {
            metadata.originalURL = url
            metadata.url = url
        }
        return metadata
    }
}

// MARK: - Export View
struct ExportSummaryView: View {
    let viewModel: CalculatorViewModel
    let result: LoanCalculation
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 6) {
                Text("LoanPro 2025")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.indigo)
                Text(viewModel.calculatorType.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(Date().formatted(date: .long, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            // Primary Loan Details
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text(primaryAmountLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(CurrencyFormatter.format(amount: primaryAmountValue, country: viewModel.selectedCountry))
                        .fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(L10n.interestRate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f%%", viewModel.interestRate))
                        .fontWeight(.bold)
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Term & Down Payment
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text(L10n.loanTerm)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.loanTermYears) \(L10n.years)")
                        .fontWeight(.bold)
                }
                Spacer()
                if viewModel.downPayment > 0 {
                    VStack(alignment: .trailing) {
                        Text(L10n.downPayment)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(CurrencyFormatter.format(amount: viewModel.downPayment, country: viewModel.selectedCountry))
                            .fontWeight(.bold)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Calculator-Specific Details
            if hasExtraDetails {
                extraDetailsSection
            }
            
            // Results
            VStack(spacing: 12) {
                summaryRow(title: L10n.monthlyPayment, value: CurrencyFormatter.format(amount: result.monthlyPayment, country: viewModel.selectedCountry), color: .indigo)
                summaryRow(title: L10n.totalInterest, value: CurrencyFormatter.format(amount: result.totalInterest, country: viewModel.selectedCountry), color: .orange)
                summaryRow(title: L10n.totalPayment, value: CurrencyFormatter.format(amount: result.totalPayment, country: viewModel.selectedCountry), color: .primary)
            }
            
            // Savings (if applicable)
            if viewModel.extraMonthlyPayment > 0 {
                VStack(spacing: 6) {
                    Text(L10n.savingsAchievement)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    HStack {
                        Text(L10n.totalSavedLabel)
                            .font(.caption)
                        Spacer()
                        Text(CurrencyFormatter.format(amount: viewModel.interestSaved, country: viewModel.selectedCountry))
                            .fontWeight(.bold)
                            .font(.caption)
                    }
                    HStack {
                        Text(L10n.timeSavedLabel)
                            .font(.caption)
                        Spacer()
                        let years = viewModel.monthsSaved / 12
                        let months = viewModel.monthsSaved % 12
                        Text(years > 0 ? "\(years)y \(months)m" : "\(months)m")
                            .fontWeight(.bold)
                            .font(.caption)
                    }
                }
                .padding(10)
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
            }
            
            Spacer()
            
            Text(L10n.generatedByApp)
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 16)
        .frame(width: 400, height: 700)
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    var hasExtraDetails: Bool {
        switch viewModel.calculatorType {
        case .auto, .rv:
            return viewModel.tradeInValue > 0 || viewModel.salesTaxRate > 0 || viewModel.registrationFees > 0
        case .home, .fha:
            return viewModel.propertyTax > 0 || viewModel.homeInsurance > 0 || viewModel.hoaFees > 0
        case .student:
            return viewModel.gracePeriodMonths > 0
        case .eligibility:
            return true
        default:
            return false
        }
    }
    
    @ViewBuilder
    var extraDetailsSection: some View {
        VStack(spacing: 8) {
            switch viewModel.calculatorType {
            case .auto, .rv:
                Text(viewModel.calculatorType == .auto ? L10n.vehicleDetails : L10n.rvDetails)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                if viewModel.tradeInValue > 0 {
                    detailRow(label: L10n.tradeInValue, value: CurrencyFormatter.format(amount: viewModel.tradeInValue, country: viewModel.selectedCountry))
                }
                if viewModel.salesTaxRate > 0 {
                    detailRow(label: L10n.salesTax, value: String(format: "%.2f%%", viewModel.salesTaxRate))
                }
                if viewModel.registrationFees > 0 {
                    detailRow(label: L10n.registrationFees, value: CurrencyFormatter.format(amount: viewModel.registrationFees, country: viewModel.selectedCountry))
                }
                
            case .home, .fha:
                Text(L10n.monthlyEscrow)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                if viewModel.propertyTax > 0 {
                    detailRow(label: L10n.propertyTax, value: CurrencyFormatter.format(amount: viewModel.propertyTax, country: viewModel.selectedCountry) + L10n.string("per_month"))
                }
                if viewModel.homeInsurance > 0 {
                    detailRow(label: L10n.homeInsurance, value: CurrencyFormatter.format(amount: viewModel.homeInsurance, country: viewModel.selectedCountry) + L10n.string("per_month"))
                }
                if viewModel.hoaFees > 0 {
                    detailRow(label: L10n.hoaFees, value: CurrencyFormatter.format(amount: viewModel.hoaFees, country: viewModel.selectedCountry) + L10n.string("per_month"))
                }
                
            case .student:
                Text(L10n.studentLoanDetails)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                detailRow(label: L10n.gracePeriod, value: "\(viewModel.gracePeriodMonths) \(L10n.string("months_short"))")
                
            case .eligibility:
                Text(L10n.eligibilityAnalysisTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                detailRow(label: L10n.string("monthly_income"), value: CurrencyFormatter.format(amount: viewModel.grossMonthlyIncome, country: viewModel.selectedCountry))
                detailRow(label: L10n.monthlyDebts, value: CurrencyFormatter.format(amount: viewModel.monthlyDebts, country: viewModel.selectedCountry))
                detailRow(label: L10n.string("max_affordable_emi"), value: CurrencyFormatter.format(amount: viewModel.maxMonthlyEMI, country: viewModel.selectedCountry))
                detailRow(label: L10n.borrowingPower, value: CurrencyFormatter.format(amount: viewModel.affordableLoanAmount, country: viewModel.selectedCountry))
                
            default:
                EmptyView()
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
    
    // Adaptive label based on calculator type
    var primaryAmountLabel: String {
        switch viewModel.calculatorType {
        case .home, .fha, .stampDuty:
            return L10n.propertyValue
        case .auto, .rv:
            return L10n.vehiclePrice
        case .student:
            return L10n.tuitionAmount
        case .eligibility:
            return L10n.annualIncome
        case .reverse:
            return L10n.monthlyBudget
        default:
            return L10n.loanAmount
        }
    }
    
    var primaryAmountValue: Double {
        switch viewModel.calculatorType {
        case .home, .fha, .stampDuty:
            return viewModel.propertyValue
        case .eligibility:
            return viewModel.annualIncome
        case .reverse:
            return viewModel.monthlyBudget
        default:
            return viewModel.loanAmount
        }
    }
    
    func summaryRow(title: String, value: String, color: Color) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.black)
                .foregroundColor(color)
        }
    }
}
