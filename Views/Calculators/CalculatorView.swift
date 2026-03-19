import SwiftUI

struct CalculatorView: View {
    @StateObject var viewModel: CalculatorViewModel
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var adService = AdService.shared
    let type: CalculatorType
    @State private var showingGuidance = false
    @State private var navigateToResults = false
    
    init(type: CalculatorType) {
        self.type = type
        _viewModel = StateObject(wrappedValue: CalculatorViewModel(type: type))
    }
    
    init(type: CalculatorType, restoredViewModel: CalculatorViewModel) {
        self.type = type
        _viewModel = StateObject(wrappedValue: restoredViewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 20) {
                    if type != .comparison {
                        inputCard
                    }
                    
                    if type == .auto {
                        autoSpecificInputs
                    } else if type == .home || type == .fha {
                        homeSpecificInputs
                    } else if type == .student {
                        studentSpecificInputs
                    } else if type == .personal {
                        personalSpecificInputs
                    } else if type == .eligibility {
                        eligibilitySpecificInputs
                    } else if type == .stampDuty {
                        stampDutySpecificInputs
                    } else if type == .comparison {
                        comparisonSpecificInputs
                    } else if type == .rentVsBuy {
                        rentVsBuySpecificInputs
                    }
                    
                    if type != .eligibility && type != .stampDuty && type != .comparison && type != .rentVsBuy {
                        extraPaymentCard
                    }
                }
                .padding(.horizontal)
                
                if type != .stampDuty && type != .comparison && type != .rentVsBuy {
                    calculateButton
                } else if type == .rentVsBuy {
                    calculateButton
                }
                
                if let result = viewModel.result {
                    summaryPreview(result: result)
                } else if type == .eligibility || type == .stampDuty {
                    summaryPreview(result: nil)
                }
                
                if type == .comparison, let res1 = viewModel.result, let res2 = viewModel.comparisonResult {
                    comparisonResultsView(res1: res1, res2: res2)
                }
                
                Spacer(minLength: 100)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
            HapticService.shared.impact(style: .light)
        }
        .id(settings.appLanguage)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(type.localizedName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToResults) {
            ResultsView(viewModel: viewModel)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingGuidance = true
                    HapticService.shared.impact(style: .light)
                }) {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showingGuidance) {
            GuidanceView(type: type, country: viewModel.selectedCountry)
        }
    }

    var inputCard: some View {
        VStack(spacing: 20) {
            if type == .reverse {
                InputField(title: L10n.monthlyBudget, value: $viewModel.monthlyBudget, range: 100...viewModel.selectedCountry.maxMonthlyBudget, step: 50, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
            } else if type == .eligibility {
                InputField(title: L10n.interestRate, value: $viewModel.interestRate, range: 0.1...30, step: 0.1, isPercentage: true, country: viewModel.selectedCountry)
            } else if type != .stampDuty {
                InputField(title: L10n.loanAmount, value: $viewModel.loanAmount, range: 1000...viewModel.selectedCountry.maxLoanAmount, step: viewModel.selectedCountry.loanStep, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
                InputField(title: L10n.interestRate, value: $viewModel.interestRate, range: 0.1...30, step: 0.1, isPercentage: true, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
            }
            
            if type != .stampDuty {
                VStack(alignment: .leading) {
                    Text("\(L10n.loanTerm): \(viewModel.loanTermYears) \(L10n.years)")
                        .font(.system(.headline, design: .rounded))
                    Slider(value: Binding(get: {
                        Double(viewModel.loanTermYears)
                    }, set: {
                        viewModel.loanTermYears = Int($0)
                        HapticService.shared.impact(style: .light)
                        viewModel.calculate()
                        viewModel.performImpactCalculation()
                    }), in: 1...40, step: 1)
                    .accentColor(.indigo)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    var autoSpecificInputs: some View {
        VStack(spacing: 20) {
            InputField(title: L10n.downPayment, value: $viewModel.downPayment, range: 0...viewModel.selectedCountry.maxLoanAmount, step: viewModel.selectedCountry.loanStep, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
            InputField(title: L10n.tradeInValue, value: $viewModel.tradeInValue, range: 0...viewModel.selectedCountry.maxLoanAmount / 10, step: viewModel.selectedCountry.loanStep, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
            
            InputField(title: L10n.salesTax, value: $viewModel.salesTaxRate, range: 0...20, step: 0.1, isPercentage: true, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
            InputField(title: L10n.registrationFees, value: $viewModel.registrationFees, range: 0...5000, step: 50, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    var homeSpecificInputs: some View {
        VStack(spacing: 20) {
             InputField(title: L10n.downPayment, value: $viewModel.downPayment, range: 0...viewModel.selectedCountry.maxLoanAmount, step: viewModel.selectedCountry.loanStep, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
             
            Text(L10n.monthlyEscrow)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            InputField(title: L10n.propertyTax, value: $viewModel.propertyTax, range: 0...viewModel.selectedCountry.maxMonthlyBudget / 5, step: 10, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
            InputField(title: L10n.homeInsurance, value: $viewModel.homeInsurance, range: 0...viewModel.selectedCountry.maxMonthlyBudget / 10, step: 10, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
            InputField(title: L10n.hoaFees, value: $viewModel.hoaFees, range: 0...viewModel.selectedCountry.maxMonthlyBudget / 5, step: 10, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    var studentSpecificInputs: some View {
        VStack(spacing: 20) {
             VStack(alignment: .leading) {
                Text("\(L10n.gracePeriod): \(viewModel.gracePeriodMonths) \(L10n.months)")
                    .font(.system(.headline, design: .rounded))
                Slider(value: Binding(get: {
                    Double(viewModel.gracePeriodMonths)
                }, set: {
                    viewModel.gracePeriodMonths = Int($0)
                    HapticService.shared.impact(style: .light)
                    viewModel.calculate()
                    viewModel.performImpactCalculation()
                }), in: 0...12, step: 1)
                .accentColor(.indigo)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }

    var personalSpecificInputs: some View {
        VStack(spacing: 20) {
            Text(L10n.monthly)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                
            Picker("Frequency", selection: $viewModel.frequency) {
                Text(L10n.monthly).tag(PaymentFrequency.monthly)
                Text(L10n.biWeekly).tag(PaymentFrequency.biWeekly)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    var eligibilitySpecificInputs: some View {
        VStack(spacing: 20) {
            InputField(title: L10n.annualIncome, value: $viewModel.annualIncome, range: 1000...viewModel.selectedCountry.maxAnnualIncome, step: 1000, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
            InputField(title: L10n.monthlyDebts, value: $viewModel.monthlyDebts, range: 0...viewModel.selectedCountry.maxMonthlyDebt, step: 100, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    var stampDutySpecificInputs: some View {
        VStack(spacing: 20) {
            InputField(title: L10n.propertyValue, value: $viewModel.propertyValue, range: 1000...viewModel.selectedCountry.maxLoanAmount, step: 5000, country: viewModel.selectedCountry)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $viewModel.useManualTaxRate.animation()) {
                    Label(L10n.string("custom_tax_rate"), systemImage: "percent")
                        .font(.headline)
                }
                .tint(.indigo)
                
                if viewModel.useManualTaxRate {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.string("calculation_rule"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Menu {
                                Picker("Tax Rule", selection: $viewModel.customTaxType) {
                                    ForEach(TaxCalculationType.allCases) { type in
                                        Text(type.localizedName).tag(type)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.customTaxType.localizedName)
                                        .font(.headline)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption)
                                }
                                .foregroundColor(.indigo)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.indigo.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        Spacer()
                    }
                    .padding(.top, 4)
                    
                    let inputTitle: String = {
                        switch viewModel.customTaxType {
                        case .percentage: return L10n.string("tax_rate_percent")
                        case .amountPerUnit: return L10n.string("tax_amount")
                        case .flat: return L10n.string("flat_fee_amount")
                        }
                    }()
                    
                    InputField(title: inputTitle, value: $viewModel.manualTaxRate, 
                               range: 0...(viewModel.customTaxType == .flat ? viewModel.selectedCountry.maxLoanAmount : 1000), 
                               step: 0.1, 
                               isPercentage: viewModel.customTaxType == .percentage, 
                               country: viewModel.selectedCountry,
                               performImpact: viewModel.performImpactCalculation)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                    if viewModel.customTaxType == .amountPerUnit {
                        InputField(title: L10n.string("per_unit_value"), 
                                   value: $viewModel.taxUnitBase, 
                                   range: 1...10000, 
                                   step: 10, 
                                   country: viewModel.selectedCountry,
                                   performImpact: viewModel.performImpactCalculation)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        
                        Text(L10n.string("example_florida_tax", viewModel.selectedCountry.currencySymbol + "0.70", viewModel.selectedCountry.currencySymbol + "100"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    Text("\(L10n.string("calculating_as_prefix")): \(viewModel.customTaxType == .amountPerUnit ? "\(viewModel.selectedCountry.currencySymbol)\(String(format: "%.2f", viewModel.manualTaxRate)) \(L10n.string("for_every")) \(viewModel.selectedCountry.currencySymbol)\(Int(viewModel.taxUnitBase)) \(L10n.string("property_value"))" : viewModel.customTaxType.localizedName)")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .italic()
                }
            }
            .padding()
            .background(Color.indigo.opacity(0.05))
            .cornerRadius(16)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    var comparisonSpecificInputs: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.string("loan_option_1"))
                    .font(.headline)
                InputField(title: L10n.string("amount"), value: $viewModel.loanAmount, range: 1000...viewModel.selectedCountry.maxLoanAmount, step: viewModel.selectedCountry.loanStep, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
                InputField(title: L10n.string("rate_percent"), value: $viewModel.interestRate, range: 0.1...30, step: 0.1, isPercentage: true, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.string("loan_option_2"))
                    .font(.headline)
                InputField(title: L10n.string("amount"), value: $viewModel.comparisonLoanAmount, range: 1000...viewModel.selectedCountry.maxLoanAmount, step: viewModel.selectedCountry.loanStep, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
                InputField(title: L10n.string("rate_percent"), value: $viewModel.comparisonInterestRate, range: 0.1...30, step: 0.1, isPercentage: true, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    var rentVsBuySpecificInputs: some View {
        VStack(spacing: 20) {
            // Renting side
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "building.2")
                        .foregroundColor(.orange)
                    Text(L10n.string("renting"))
                        .font(.headline)
                }
                InputField(title: L10n.string("monthly_rent"), value: $viewModel.monthlyRent, range: 100...viewModel.selectedCountry.maxMonthlyBudget, step: 50, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
                InputField(title: L10n.string("annual_rent_increase"), value: $viewModel.annualRentIncrease, range: 0...15, step: 0.5, isPercentage: true, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
            }
            
            Divider()
            
            // Buying side
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundColor(.indigo)
                    Text(L10n.string("buying"))
                        .font(.headline)
                }
                InputField(title: L10n.loanAmount, value: $viewModel.loanAmount, range: 1000...viewModel.selectedCountry.maxLoanAmount, step: viewModel.selectedCountry.loanStep, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
                InputField(title: L10n.downPayment, value: $viewModel.downPayment, range: 0...viewModel.selectedCountry.maxLoanAmount, step: viewModel.selectedCountry.loanStep, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
                InputField(title: L10n.interestRate, value: $viewModel.interestRate, range: 0.1...30, step: 0.1, isPercentage: true, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
                
                VStack(alignment: .leading) {
                    Text("\(L10n.loanTerm): \(viewModel.loanTermYears) \(L10n.years)")
                        .font(.system(.headline, design: .rounded))
                    Slider(value: Binding(get: {
                        Double(viewModel.loanTermYears)
                    }, set: {
                        viewModel.loanTermYears = Int($0)
                        HapticService.shared.impact(style: .light)
                        viewModel.calculate()
                    }), in: 1...40, step: 1)
                    .accentColor(.indigo)
                }
                
                InputField(title: L10n.string("home_appreciation"), value: $viewModel.homeAppreciation, range: 0...15, step: 0.5, isPercentage: true, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
                InputField(title: L10n.string("closing_costs"), value: $viewModel.closingCostsPercent, range: 0...10, step: 0.5, isPercentage: true, country: viewModel.selectedCountry, performImpact: viewModel.performImpactCalculation)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    var extraPaymentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.extraPayment)
                .font(.system(.headline, design: .rounded))
            
            HStack {
                Text(viewModel.selectedCountry.currencySymbol)
                    .font(.system(.title3, design: .rounded))
                    .foregroundColor(.secondary)
                TextField("0", value: $viewModel.extraMonthlyPayment, format: .number)
                    .keyboardType(.decimalPad)
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .textFieldStyle(.plain)
                    .onChange(of: viewModel.extraMonthlyPayment) { _, _ in
                        viewModel.calculate()
                    }
                Spacer()
            }
            .padding(10)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(12)
            
            Slider(value: $viewModel.extraMonthlyPayment, in: 0...viewModel.selectedCountry.maxMonthlyBudget, step: viewModel.selectedCountry.extraPaymentStep)
                .accentColor(.green)
                .onChange(of: viewModel.extraMonthlyPayment) { _, _ in
                    HapticService.shared.impact(style: .light)
                    viewModel.calculate()
                    viewModel.performImpactCalculation()
                }
            
            Text(L10n.string("see_interest_save"))
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    var calculateButton: some View {
        Button(action: {
            viewModel.calculate()
            viewModel.performImpactCalculation()
            if adService.canShowInterstitial() {
                adService.showInterstitial {
                    navigateToResults = true
                }
            } else {
                navigateToResults = true
            }
        }) {
            HStack {
                Text(L10n.viewDetailedReport)
                Image(systemName: "chevron.right")
            }
            .font(.system(.headline, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(Color.indigo)
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
    
    func summaryPreview(result: LoanCalculation?) -> some View {
        VStack(spacing: 12) {
            if type == .reverse || type == .eligibility {
                Text(L10n.borrowingPower)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(CurrencyFormatter.format(amount: viewModel.affordableLoanAmount, country: viewModel.selectedCountry))
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.indigo)
            } else if type == .stampDuty {
                Text(L10n.stampDuty)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(CurrencyFormatter.format(amount: viewModel.stampDutyAmount, country: viewModel.selectedCountry))
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.green)
                
                VStack(spacing: 8) {
                    Text(viewModel.selectedCountry.stampDutyBasis)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .padding(.top, 12)
                .padding(.horizontal)
            } else if let res = result {
                Text(L10n.monthlyPayment)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(CurrencyFormatter.format(amount: res.monthlyPayment, country: viewModel.selectedCountry))
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.indigo)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    func comparisonResultsView(res1: LoanCalculation, res2: LoanCalculation) -> some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                comparisonColumn(title: L10n.string("option_1"), payment: res1.monthlyPayment, total: res1.totalPayment)
                comparisonColumn(title: L10n.string("option_2"), payment: res2.monthlyPayment, total: res2.totalPayment)
            }
            
            let diff = abs(res1.totalPayment - res2.totalPayment)
            Text("\(L10n.string("difference_in_total")): \(CurrencyFormatter.format(amount: diff, country: viewModel.selectedCountry))")
                .font(.headline)
                .foregroundColor(.indigo)
        }
        .padding()
    }
    
    func comparisonColumn(title: String, payment: Double, total: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            Text("\(L10n.monthly): \(CurrencyFormatter.format(amount: payment, country: viewModel.selectedCountry))")
                .font(.subheadline)
            Text("\(L10n.string("total")): \(CurrencyFormatter.format(amount: total, country: viewModel.selectedCountry))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.5))
        .cornerRadius(12)
    }
}

struct InputField: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    var isPercentage: Bool = false
    let country: Country

    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    var performImpact: (() -> Void)?

    init(title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, isPercentage: Bool = false, country: Country, performImpact: (() -> Void)? = nil) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.isPercentage = isPercentage
        self.country = country
        self.performImpact = performImpact
        // Initialize textValue with a raw numeric string (no symbols) for easy editing
        if isPercentage {
            self._textValue = State(initialValue: Self.numericString(from: value.wrappedValue))
        } else {
            self._textValue = State(initialValue: Self.numericString(from: value.wrappedValue))
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                Spacer()
                HStack(spacing: 6) {
                    if !isPercentage {
                        Text(currencySymbol(for: country))
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    TextField(isPercentage ? "0.0" : "0", text: $textValue)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($isFocused)
                        .onChange(of: textValue) { _, new in
                            // Immediate update of the value without snapping/clamping while typing
                            // This allows calculations to update in real-time without moving the cursor or changing digits
                            let parsed = Self.parseNumeric(from: new)
                            if let raw = Double(parsed) {
                                value = raw
                            }
                        }
                        .onChange(of: isFocused) { _, focused in
                            if !focused {
                                // Final validation when focus is lost
                                finalizeInput()
                                performImpact?()
                            }
                        }
                        .onSubmit {
                            finalizeInput()
                        }
                        .submitLabel(.done)
                        .frame(minWidth: 80)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }

            Slider(value: Binding(get: {
                value
            }, set: { newVal in
                // Sliders still use snapping and clamping for better UX
                let snapped = snap(newVal, to: step)
                let clamped = clamp(snapped, in: range)
                if clamped != value {
                    value = clamped
                    textValue = Self.numericString(from: clamped)
                    HapticService.shared.impact(style: .light)
                }
            }), in: range, step: step)
            .accentColor(.indigo)
        }
        .onChange(of: value) { _, newVal in
            // ONLY update text if NOT focused to prevent jumping while typing
            if !isFocused {
                let numeric = Self.numericString(from: newVal)
                if numeric != textValue {
                    textValue = numeric
                }
            }
        }
    }

    private func finalizeInput() {
        let parsed = Self.parseNumeric(from: textValue)
        guard let raw = Double(parsed) else {
            // Reset to current valid value if input is invalid
            textValue = Self.numericString(from: value)
            return
        }
        
        let clamped = clamp(raw, in: range)
        
        value = clamped
        textValue = Self.numericString(from: clamped)
    }

    private func clamp(_ v: Double, in range: ClosedRange<Double>) -> Double {
        return min(max(v, range.lowerBound), range.upperBound)
    }

    private func snap(_ v: Double, to step: Double) -> Double {
        guard step > 0 else { return v }
        let steps = (v / step).rounded()
        return steps * step
    }

    private static func numericString(from value: Double) -> String {
        // Avoid scientific notation and trailing zeros issues
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    private static func parseNumeric(from input: String) -> String {
        // Keep digits and at most one decimal separator
        var result = ""
        var hasDecimal = false
        for ch in input { 
            if ch.isNumber { result.append(ch) }
            else if (ch == "." || ch == ",") && !hasDecimal { result.append("."); hasDecimal = true }
        }
        return result
    }
    
    private func currencySymbol(for country: Country) -> String {
        return country.currencySymbol
    }
}

// Global helper to dismiss keyboard instantly
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
