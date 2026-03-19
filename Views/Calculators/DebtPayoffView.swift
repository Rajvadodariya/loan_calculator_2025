import SwiftUI
import Charts

// Chart helper struct — must be outside ViewBuilder
private struct DebtChartPoint: Identifiable {
    let id = UUID()
    let month: Int
    let balance: Double
    let strategy: String
}

struct DebtPayoffView: View {
    @StateObject private var viewModel = DebtPayoffViewModel()
    @ObservedObject var settings = SettingsManager.shared
    @State private var selectedStrategy: StrategyTab = .comparison
    @State private var showGuide = true
    
    enum StrategyTab: String, CaseIterable {
        case comparison = "Compare"
        case snowball = "Snowball"
        case avalanche = "Avalanche"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // How-To Guide
                if showGuide {
                    guideSection
                }
                
                // Debt Input Section
                debtInputSection
                
                // Extra Budget
                extraBudgetSection
                
                // Results
                if viewModel.snowballResult != nil || viewModel.avalancheResult != nil {
                    strategyResultsSection
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
        .id(settings.appLanguage)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(L10n.string("debt_payoff"))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - How-To Guide
    var guideSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
                Text("How It Works")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        showGuide = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Add all your debts below, set your extra monthly budget, and this tool will show you the fastest way to become debt-free.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            // Snowball explanation
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "snowflake")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Snowball Method")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Pay off the **smallest balance first**. Once cleared, roll that payment into the next smallest. Great for motivation — you see debts disappear quickly!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Avalanche explanation
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "mountain.2.fill")
                    .font(.title3)
                    .foregroundColor(.red)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Avalanche Method")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("Pay off the **highest interest rate first**. Mathematically optimal — saves you the most money in interest over time.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // How to read results
            VStack(alignment: .leading, spacing: 6) {
                Label("Add each debt with its balance, rate, and minimum payment", systemImage: "1.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Label("Set your extra monthly budget (above minimums)", systemImage: "2.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Label("Compare: which strategy saves more money?", systemImage: "3.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.yellow.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Debt Input Section
    var debtInputSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L10n.string("debt_payoff"))
                    .font(.headline)
                Spacer()
                Button(action: {
                    withAnimation {
                        viewModel.addDebt()
                    }
                    HapticService.shared.impact(style: .medium)
                }) {
                    Label(L10n.string("add_debt"), systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.indigo)
                }
            }
            
            ForEach(Array(viewModel.debts.enumerated()), id: \.element.id) { index, debt in
                VStack(spacing: 12) {
                    HStack {
                        TextField(L10n.string("debt_name"), text: $viewModel.debts[index].name)
                            .font(.system(.headline, design: .rounded))
                            .textFieldStyle(.plain)
                        
                        if viewModel.debts.count > 1 {
                            Button(action: {
                                withAnimation {
                                    viewModel.removeDebt(at: index)
                                }
                                HapticService.shared.impact(style: .light)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red.opacity(0.7))
                            }
                        }
                    }
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.string("debt_balance"))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            TextField("0", value: $viewModel.debts[index].balance, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.subheadline, design: .rounded))
                                .onChange(of: viewModel.debts[index].balance) { _, _ in viewModel.calculate() }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.interestRate)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            TextField("0%", value: $viewModel.debts[index].interestRate, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.subheadline, design: .rounded))
                                .onChange(of: viewModel.debts[index].interestRate) { _, _ in viewModel.calculate() }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.string("minimum_payment"))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            TextField("0", value: $viewModel.debts[index].minPayment, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.subheadline, design: .rounded))
                                .onChange(of: viewModel.debts[index].minPayment) { _, _ in viewModel.calculate() }
                        }
                    }
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    // MARK: - Extra Budget
    var extraBudgetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.string("extra_budget"))
                .font(.system(.headline, design: .rounded))
            
            Text("Monthly amount above your minimum payments")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text(CurrencyFormatter.format(amount: viewModel.extraBudget, country: viewModel.selectedCountry))
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                Spacer()
            }
            
            Slider(value: $viewModel.extraBudget, in: 0...viewModel.selectedCountry.maxMonthlyBudget / 4, step: viewModel.selectedCountry.extraPaymentStep)
                .accentColor(.green)
                .onChange(of: viewModel.extraBudget) { _, _ in
                    HapticService.shared.impact(style: .light)
                    viewModel.calculate()
                }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    // MARK: - Results
    var strategyResultsSection: some View {
        VStack(spacing: 16) {
            Text(L10n.string("strategy_comparison"))
                .font(.headline)
            
            Picker("Strategy", selection: $selectedStrategy.animation()) {
                ForEach(StrategyTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            switch selectedStrategy {
            case .comparison:
                comparisonView
            case .snowball:
                if let result = viewModel.snowballResult {
                    strategyDetailView(result: result, name: L10n.string("snowball_method"), color: .blue)
                }
            case .avalanche:
                if let result = viewModel.avalancheResult {
                    strategyDetailView(result: result, name: L10n.string("avalanche_method"), color: .red)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    // MARK: - Comparison
    private func buildChartData(snow: DebtPayoffResult, aval: DebtPayoffResult) -> [DebtChartPoint] {
        let snowLabel = L10n.string("snowball_method")
        let avalLabel = L10n.string("avalanche_method")
        return snow.monthlyBreakdown.map { DebtChartPoint(month: $0.month, balance: $0.totalBalance, strategy: snowLabel) } +
               aval.monthlyBreakdown.map { DebtChartPoint(month: $0.month, balance: $0.totalBalance, strategy: avalLabel) }
    }
    
    var comparisonView: some View {
        VStack(spacing: 16) {
            if let snow = viewModel.snowballResult, let aval = viewModel.avalancheResult {
                HStack(spacing: 12) {
                    strategyCard(name: L10n.string("snowball_method"), months: snow.totalMonths, interest: snow.totalInterestPaid, color: .blue, icon: "snowflake")
                    strategyCard(name: L10n.string("avalanche_method"), months: aval.totalMonths, interest: aval.totalInterestPaid, color: .red, icon: "mountain.2")
                }
                
                // Savings difference
                let interestDiff = abs(snow.totalInterestPaid - aval.totalInterestPaid)
                let winner = aval.totalInterestPaid < snow.totalInterestPaid ? L10n.string("avalanche_method") : L10n.string("snowball_method")
                
                if interestDiff > 0 {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                        Text("\(winner) saves \(CurrencyFormatter.format(amount: interestDiff, country: viewModel.selectedCountry)) in interest")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Comparison chart — data built outside ViewBuilder
                let chartData = buildChartData(snow: snow, aval: aval)
                let snowLabel = L10n.string("snowball_method")
                let avalLabel = L10n.string("avalanche_method")
                
                Chart(chartData) { point in
                    LineMark(
                        x: .value(L10n.month, point.month),
                        y: .value(L10n.balance, point.balance)
                    )
                    .foregroundStyle(by: .value("Strategy", point.strategy))
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.monotone)
                }
                .chartForegroundStyleScale([
                    snowLabel: Color.blue,
                    avalLabel: Color.red
                ])
                .frame(height: 200)
            }
        }
    }
    
    func strategyCard(name: String, months: Int, interest: Double, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(name)
                    .font(.caption)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                let years = months / 12
                let remainingMonths = months % 12
                Text(years > 0 ? "\(years)y \(remainingMonths)m" : "\(remainingMonths)m")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(color)
                
                Text(CurrencyFormatter.format(amount: interest, country: viewModel.selectedCountry))
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Text(L10n.string("interest_saved_total"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
    
    func strategyDetailView(result: DebtPayoffResult, name: String, color: Color) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                    Text(L10n.string("debt_free_date"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(result.debtFreeDate, style: .date)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    let years = result.totalMonths / 12
                    let months = result.totalMonths % 12
                    Text(years > 0 ? "\(years)y \(months)m" : "\(months) months")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.black)
                        .foregroundColor(color)
                    Text(L10n.string("total_months_to_payoff"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            HStack {
                Text(L10n.totalInterest)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(CurrencyFormatter.format(amount: result.totalInterestPaid, country: viewModel.selectedCountry))
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            
            // Balance over time chart
            Chart(result.monthlyBreakdown) { snapshot in
                AreaMark(
                    x: .value(L10n.month, snapshot.month),
                    y: .value(L10n.balance, snapshot.totalBalance)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.monotone)
                
                LineMark(
                    x: .value(L10n.month, snapshot.month),
                    y: .value(L10n.balance, snapshot.totalBalance)
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.monotone)
            }
            .frame(height: 180)
        }
    }
}
