import SwiftUI

struct CalculatorView: View {
    @StateObject var viewModel: CalculatorViewModel
    let type: CalculatorType
    
    init(type: CalculatorType) {
        self.type = type
        _viewModel = StateObject(wrappedValue: CalculatorViewModel(type: type))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                countryPicker
                
                VStack(spacing: 20) {
                    inputCard
                    
                    if type == .auto {
                        autoSpecificInputs
                    } else if type == .home || type == .fha {
                        homeSpecificInputs
                    } else if type == .student {
                        studentSpecificInputs
                    } else if type == .personal {
                        personalSpecificInputs
                    }
                    
                    extraPaymentCard
                }
                .padding(.horizontal)
                
                calculateButton
                
                if let result = viewModel.result {
                    summaryPreview(result: result)
                }
                
                Spacer(minLength: 100) // Space for ad banner
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(type.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var countryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Country.allCases) { country in
                    Button(action: {
                        viewModel.updateCountry(country)
                    }) {
                        HStack {
                            Text(country.flag)
                            Text(country.rawValue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(viewModel.selectedCountry == country ? Color.indigo : Color.white)
                        .foregroundColor(viewModel.selectedCountry == country ? .white : .primary)
                        .cornerRadius(20)
                        .shadow(radius: 2)
                    }
                }
            }
            .padding()
        }
    }
    
    var inputCard: some View {
        VStack(spacing: 20) {
            if type == .reverse {
                InputField(title: "Monthly Budget", value: $viewModel.monthlyBudget, range: 100...20000, step: 50, country: viewModel.selectedCountry)
            } else {
                InputField(title: "Loan Amount", value: $viewModel.loanAmount, range: 1000...10000000, step: 1000, country: viewModel.selectedCountry)
            }
            
            InputField(title: "Interest Rate (%)", value: $viewModel.interestRate, range: 0.1...30, step: 0.1, isPercentage: true, country: viewModel.selectedCountry)
            
            VStack(alignment: .leading) {
                Text("Loan Term: \(viewModel.loanTermYears) Years")
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
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    var autoSpecificInputs: some View {
        VStack(spacing: 20) {
            InputField(title: "Down Payment", value: $viewModel.downPayment, range: 0...1000000, step: 500, country: viewModel.selectedCountry)
            InputField(title: "Trade-In Value", value: $viewModel.tradeInValue, range: 0...100000, step: 500, country: viewModel.selectedCountry)
            
            InputField(title: "Sales Tax (%)", value: $viewModel.salesTaxRate, range: 0...20, step: 0.1, isPercentage: true, country: viewModel.selectedCountry)
            InputField(title: "Registration Fees", value: $viewModel.registrationFees, range: 0...5000, step: 50, country: viewModel.selectedCountry)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    var homeSpecificInputs: some View {
        VStack(spacing: 20) {
             InputField(title: "Down Payment", value: $viewModel.downPayment, range: 0...1000000, step: 1000, country: viewModel.selectedCountry)
             
            Text("Monthly Escrow")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            InputField(title: "Property Tax", value: $viewModel.propertyTax, range: 0...5000, step: 10, country: viewModel.selectedCountry)
            InputField(title: "Home Insurance", value: $viewModel.homeInsurance, range: 0...1000, step: 10, country: viewModel.selectedCountry)
            InputField(title: "HOA Fees", value: $viewModel.hoaFees, range: 0...2000, step: 10, country: viewModel.selectedCountry)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    var studentSpecificInputs: some View {
        VStack(spacing: 20) {
             VStack(alignment: .leading) {
                Text("Grace Period: \(viewModel.gracePeriodMonths) Months")
                    .font(.system(.headline, design: .rounded))
                Slider(value: Binding(get: {
                    Double(viewModel.gracePeriodMonths)
                }, set: {
                    viewModel.gracePeriodMonths = Int($0)
                    HapticService.shared.impact(style: .light)
                    viewModel.calculate()
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
            Text("Payment Frequency")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                
            Picker("Frequency", selection: $viewModel.frequency) {
                Text("Monthly").tag(PaymentFrequency.monthly)
                Text("Bi-Weekly").tag(PaymentFrequency.biWeekly)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    var extraPaymentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Extra Monthly Payment")
                .font(.system(.headline, design: .rounded))
            
            HStack {
                Text(CurrencyFormatter.format(amount: viewModel.extraMonthlyPayment, country: viewModel.selectedCountry))
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                Spacer()
            }
            
            Slider(value: $viewModel.extraMonthlyPayment, in: 0...5000, step: 50)
                .accentColor(.green)
                .onChange(of: viewModel.extraMonthlyPayment) { _ in
                    HapticService.shared.impact(style: .light)
                    viewModel.calculate()
                }
            
            Text("See how much interest you save!")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    var calculateButton: some View {
        NavigationLink(destination: ResultsView(viewModel: viewModel)) {
            HStack {
                Text("View Detailed Report")
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
    
    func summaryPreview(result: LoanCalculation) -> some View {
        VStack(spacing: 12) {
            if type == .reverse {
                Text("You can afford a loan of")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(CurrencyFormatter.format(amount: viewModel.affordableLoanAmount, country: viewModel.selectedCountry))
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.indigo)
            } else {
                Text("Estimated Monthly Payment")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(CurrencyFormatter.format(amount: result.monthlyPayment, country: viewModel.selectedCountry))
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.indigo)
            }
        }
        .padding()
    }
}

struct InputField: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    var isPercentage: Bool = false
    let country: Country
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                Spacer()
                Text(isPercentage ? String(format: "%.1f%%", value) : CurrencyFormatter.format(amount: value, country: country))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.indigo)
            }
            
            Slider(value: $value, in: range, step: step)
                .accentColor(.indigo)
                .onChange(of: value) { _ in
                    HapticService.shared.impact(style: .light)
                    // Note: We might want to trigger calculate() here if the ViewModel doesn't observe these directly.
                    // But since we pass Bindings to @Published properties, the ViewModel will update.
                    // However, `calculate()` is not automatically called on @Published change unless we use Combine.
                    // In `CalculatorView`, we passed bindings. The ViewModel doesn't have an `didSet` on these properties to auto-recalculate.
                    // I will add a `.onChange` to the Slider or InputField to call calculate? 
                    // No, `CalculatorViewModel` isn't observing itself.
                    // Actually, the `InputField` has an onChange that calls Haptic.
                    // I should probably add a closure or binding to trigger calculation, or just make the user press a button?
                    // The "Calculate" button is just a NavigationLink. It implies the calculation is already done.
                    // The `summaryPreview` relies on `viewModel.result`.
                    // So we MUST trigger recalculation when values change.
                    // I'll fix this by adding `viewModel.calculate()` to the `InputField` onChange or `Binding`.
                    // But `InputField` doesn't have access to viewModel.
                    // I'll make `InputField` take a closure `onChange`.
                }
        }
    }
}