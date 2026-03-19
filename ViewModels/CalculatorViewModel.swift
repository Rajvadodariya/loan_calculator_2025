import SwiftUI
import Combine
import StoreKit

enum TaxCalculationType: String, CaseIterable, Identifiable {
    case percentage
    case amountPerUnit
    case flat
    
    var id: String { self.rawValue }
    
    var localizedName: String {
        switch self {
        case .percentage: return L10n.string("percentage")
        case .amountPerUnit: return L10n.string("amount_per_unit")
        case .flat: return L10n.string("flat_fee")
        }
    }
}

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
    
    // Eligibility specific
    @Published var annualIncome: Double = 60000 { didSet { calculate() } }
    @Published var monthlyDebts: Double = 500 { didSet { calculate() } }
    
    // Stamp Duty specific
    @Published var propertyValue: Double = 500000 { didSet { calculate() } }
    @Published var manualTaxRate: Double = 0 { didSet { calculate() } } 
    @Published var taxUnitBase: Double = 100 { didSet { calculate() } } // Default to 100
    @Published var useManualTaxRate: Bool = false { didSet { calculate() } }
    @Published var customTaxType: TaxCalculationType = .percentage { didSet { calculate() } }
    
    // Comparison specific
    @Published var comparisonLoanAmount: Double = 100000 { didSet { calculate() } }
    @Published var comparisonInterestRate: Double = 4.5 { didSet { calculate() } }
    @Published var comparisonLoanTermYears: Int = 30 { didSet { calculate() } }
    @Published var comparisonResult: LoanCalculation?
    
    // Rent vs Buy specific
    @Published var monthlyRent: Double = 1500 { didSet { calculate() } }
    @Published var annualRentIncrease: Double = 3.0 { didSet { calculate() } }
    @Published var homeAppreciation: Double = 3.0 { didSet { calculate() } }
    @Published var closingCostsPercent: Double = 3.0 { didSet { calculate() } }
    
    // Outputs
    @Published var result: LoanCalculation?
    @Published var affordableLoanAmount: Double = 0
    @Published var stampDutyAmount: Double = 0
    @Published var rentVsBuyResult: RentVsBuyResult?
    
    // Eligibility Breakdown
    @Published var grossMonthlyIncome: Double = 0
    @Published var maxMonthlyEMI: Double = 0
    
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
            // Also generate a full result based on this affordablity
            result = calculationService.calculateLoan(
                amount: affordableLoanAmount,
                annualRate: interestRate,
                years: loanTermYears,
                country: selectedCountry,
                type: .simple,
                frequency: .monthly
            )
            return
        }
        
        if calculatorType == .eligibility {
            grossMonthlyIncome = annualIncome / 12
            maxMonthlyEMI = (grossMonthlyIncome * 0.28) - monthlyDebts
            
            affordableLoanAmount = calculationService.calculateBorrowingPower(
                grossAnnualIncome: annualIncome,
                monthlyDebts: monthlyDebts,
                interestRate: interestRate,
                years: loanTermYears,
                country: selectedCountry
            )
            // Generate full result for the affordable loan
            result = calculationService.calculateLoan(
                amount: affordableLoanAmount,
                annualRate: interestRate,
                years: loanTermYears,
                country: selectedCountry,
                type: .simple,
                frequency: .monthly
            )
            return
        }
        
        if calculatorType == .stampDuty {
            stampDutyAmount = calculationService.calculateStampDuty(
                propertyValue: propertyValue,
                country: selectedCountry,
                manualRate: useManualTaxRate ? manualTaxRate : nil,
                taxType: customTaxType,
                unitBase: taxUnitBase
            )
            // No full loan result for just stamp duty
            result = nil
            return
        }
        
        if calculatorType == .comparison {
            // First loan
            result = calculationService.calculateLoan(
                amount: loanAmount,
                annualRate: interestRate,
                years: loanTermYears,
                country: selectedCountry,
                type: .simple
            )
            // Second loan
            comparisonResult = calculationService.calculateLoan(
                amount: comparisonLoanAmount,
                annualRate: comparisonInterestRate,
                years: comparisonLoanTermYears,
                country: selectedCountry,
                type: .simple
            )
            return
        }
        
        if calculatorType == .rentVsBuy {
            calculateRentVsBuy()
            return
        }
        
        if calculatorType == .debtPayoff {
            // Handled by DebtPayoffViewModel
            return
        }
        
        var principal = loanAmount
        var salesTaxAmount = 0.0
        var regFees = 0.0
        
        if calculatorType == .auto || calculatorType == .rv {
            salesTaxAmount = loanAmount * (salesTaxRate / 100)
            regFees = registrationFees
            principal = loanAmount + salesTaxAmount + regFees - downPayment - tradeInValue
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
            gracePeriodMonths: gracePeriodMonths,
            autoSalesTax: salesTaxAmount,
            autoRegistrationFees: regFees
        )
        
        // Bonus: Calculate Savings (Baseline comparison)
        if extraMonthlyPayment > 0 {
            let baseResult = calculationService.calculateLoan(
                amount: max(0, principal),
                annualRate: interestRate,
                years: loanTermYears,
                country: selectedCountry,
                type: calculatorType,
                frequency: frequency,
                extraMonthlyPayment: 0, // Baseline
                processingFee: processingFee,
                monthlyEscrow: monthlyEscrow,
                gracePeriodMonths: gracePeriodMonths
            )
            
            let interestSaved = baseResult.totalInterest - (result?.totalInterest ?? 0)
            let payoffMonthsSaved = baseResult.amortizationSchedule.count - (result?.amortizationSchedule.count ?? 0)
            
            // We could store these in the result or separate published properties
            self.interestSaved = interestSaved
            self.monthsSaved = payoffMonthsSaved
        } else {
            self.interestSaved = 0
            self.monthsSaved = 0
        }
        
    }
    
    @Published var interestSaved: Double = 0
    @Published var monthsSaved: Int = 0
    
    func updateCountry(_ country: Country) {
        self.selectedCountry = country
        calculate()
    }
    
    // MARK: - Rent vs Buy Calculation
    private func calculateRentVsBuy() {
        let homePrice = loanAmount
        let dp = downPayment
        let loanPrincipal = max(0, homePrice - dp)
        let closingCosts = homePrice * (closingCostsPercent / 100)
        
        // Calculate mortgage payment
        let monthlyRate = (interestRate / 100) / 12
        let n = Double(loanTermYears * 12)
        var mortgagePayment: Double = 0
        if monthlyRate > 0 && loanPrincipal > 0 {
            mortgagePayment = loanPrincipal * (monthlyRate * pow(1 + monthlyRate, n)) / (pow(1 + monthlyRate, n) - 1)
        } else if loanPrincipal > 0 {
            mortgagePayment = loanPrincipal / n
        }
        
        var cumulativeRent: Double = 0
        var cumulativeBuy: Double = closingCosts + dp
        var currentRent = monthlyRent
        var remainingBalance = loanPrincipal
        var homeValue = homePrice
        var snapshots: [RentVsBuyResult.YearSnapshot] = []
        var breakEven: Int? = nil
        
        for year in 1...loanTermYears {
            // Rent cost for this year
            let yearlyRent = currentRent * 12
            cumulativeRent += yearlyRent
            
            // Buy cost for this year (mortgage + property tax + insurance + HOA)
            let yearlyMortgage = mortgagePayment * 12
            let yearlyPropertyTax = propertyTax * 12
            let yearlyInsurance = homeInsurance * 12
            let yearlyHOA = hoaFees * 12
            cumulativeBuy += yearlyMortgage + yearlyPropertyTax + yearlyInsurance + yearlyHOA
            
            // Update home value (appreciation)
            homeValue *= (1 + homeAppreciation / 100)
            
            // Calculate principal paid this year
            var yearPrincipalPaid: Double = 0
            for _ in 0..<12 {
                if remainingBalance <= 0 { break }
                let interestPart = remainingBalance * monthlyRate
                var principalPart = mortgagePayment - interestPart
                if principalPart > remainingBalance { principalPart = remainingBalance }
                remainingBalance -= principalPart
                yearPrincipalPaid += principalPart
            }
            
            // Equity = home value - remaining mortgage
            let equity = homeValue - remainingBalance
            
            snapshots.append(RentVsBuyResult.YearSnapshot(
                year: year,
                cumulativeRent: cumulativeRent,
                cumulativeBuy: cumulativeBuy,
                equity: equity
            ))
            
            // Check break-even: net buy cost < rent cost
            let netBuyCost = cumulativeBuy - equity
            if breakEven == nil && netBuyCost < cumulativeRent {
                breakEven = year
            }
            
            // Increase rent for next year
            currentRent *= (1 + annualRentIncrease / 100)
        }
        
        let finalEquity = homeValue - remainingBalance
        
        rentVsBuyResult = RentVsBuyResult(
            totalRentCost: cumulativeRent,
            totalBuyCost: cumulativeBuy,
            buyEquity: finalEquity,
            breakEvenYear: breakEven,
            yearlyComparison: snapshots
        )
        
        // Also generate a mortgage result for the details view
        result = calculationService.calculateLoan(
            amount: loanPrincipal,
            annualRate: interestRate,
            years: loanTermYears,
            country: selectedCountry,
            type: .simple,
            frequency: .monthly
        )
    }
    
    func performImpactCalculation() {
        HapticService.shared.impact(style: .medium)
        
        // Track calculations and prompt for review after 3rd
        SettingsManager.shared.incrementCalculationCount()
        
        if SettingsManager.shared.calculationCount >= 3 && !SettingsManager.shared.hasRequestedReview {
            SettingsManager.shared.hasRequestedReview = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let scene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    AppStore.requestReview(in: scene)
                }
            }
        }
    }
}
