import SwiftUI
import Combine

class CalculatorViewModel: ObservableObject {
    // Inputs
    @Published var loanAmount: Double = 100000 { didSet { calculate() } }
    @Published var monthlyBudget: Double = 2000 { didSet { calculate() } } // For Reverse
    @Published var interestRate: Double = 5.0 { didSet { calculate() } }
    @Published var loanTermYears: Int = 30 { didSet { calculate() } }
    @Published var selectedCountry: Country { didSet { calculate() } }
    @Published var extraMonthlyPayment: Double = 0 { didSet { calculate() } }
    @Published var processingFee: Double = 0 { didSet { calculate() } }
    @Published var calculatorType: CalculatorType = .simple { didSet { calculate() } }
    @Published var frequency: PaymentFrequency = .monthly { didSet { calculate() } }
    
    // Auto specific
    @Published var tradeInValue: Double = 0 { didSet { calculate() } }
    @Published var downPayment: Double = 0 { didSet { calculate() } }
    @Published var salesTaxRate: Double = 0 { didSet { calculate() } }
    @Published var registrationFees: Double = 0 { didSet { calculate() } }
    
    // Home/FHA specific
    @Published var propertyTax: Double = 0 { didSet { calculate() } } // Monthly
    @Published var homeInsurance: Double = 0 { didSet { calculate() } } // Monthly
    @Published var hoaFees: Double = 0 { didSet { calculate() } } // Monthly
    
    // Student specific
    @Published var gracePeriodMonths: Int = 0 { didSet { calculate() } }
    
    // Outputs
    @Published var result: LoanCalculation?
    @Published var affordableLoanAmount: Double = 0
    
    private let calculationService = CalculationService.shared
    
    init(type: CalculatorType = .simple) {
        self.calculatorType = type
        self.selectedCountry = SettingsManager.shared.selectedCountry
        calculate()
    }
    
    func calculate() {
        if calculatorType == .reverse {
            affordableLoanAmount = calculationService.calculateMaxLoan(
                monthlyBudget: monthlyBudget,
                annualRate: interestRate,
                years: loanTermYears,
                country: selectedCountry
            )
            return
        }
        
        var principal = loanAmount
        
        if calculatorType == .auto {
            let taxAmount = loanAmount * (salesTaxRate / 100)
            principal = loanAmount + taxAmount + registrationFees - downPayment - tradeInValue
        } else {
            principal = loanAmount - downPayment - tradeInValue
        }
        
        let monthlyEscrow = propertyTax + homeInsurance + hoaFees
        
        result = calculationService.calculateLoan(
            amount: max(0, principal),
            annualRate: interestRate,
            years: loanTermYears,
            country: selectedCountry,
            type: calculatorType,
            frequency: frequency,
            extraMonthlyPayment: extraMonthlyPayment,
            processingFee: processingFee,
            monthlyEscrow: monthlyEscrow,
            gracePeriodMonths: gracePeriodMonths
        )
        
        HapticService.shared.impact(style: .medium)
    }
    
    func updateCountry(_ country: Country) {
        self.selectedCountry = country
        calculate()
    }
}
