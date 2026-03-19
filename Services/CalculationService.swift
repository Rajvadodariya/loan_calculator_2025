import Foundation

enum PaymentFrequency: Int {
    case monthly = 12
    case biWeekly = 26
}

class CalculationService {
    static let shared = CalculationService()
    
    func calculateLoan(
        amount: Double,
        annualRate: Double,
        years: Int,
        country: Country,
        type: CalculatorType,
        frequency: PaymentFrequency = .monthly,
        extraMonthlyPayment: Double = 0,
        processingFee: Double = 0,
        // New optional params
        monthlyEscrow: Double = 0, // Property Tax + Insurance + HOA
        gracePeriodMonths: Int = 0,
        autoSalesTax: Double = 0, // Auto-specific
        autoRegistrationFees: Double = 0 // Auto-specific
    ) -> LoanCalculation {
        var loanAmount = amount
        var upfrontFees = 0.0
        var periodicAddon = 0.0 // PMIs, MIPs adjusted for frequency
        
        // 1. Regional Fee/MIP Logic
        if country == .india && processingFee > 0 {
            // 18% GST on processing fees
            upfrontFees = processingFee * 0.18
        } else if country == .usa && type == .fha {
            // FHA MIP: 1.75% Upfront (usually rolled into loan)
            let upfrontMIP = amount * 0.0175
            loanAmount += upfrontMIP
            upfrontFees = upfrontMIP
            
            // 0.55% Annual MIP divided by frequency
            periodicAddon = (loanAmount * 0.0055) / Double(frequency.rawValue)
        } else if country == .uk {
            // UK: Placeholder for mortgage arrangement fees
            upfrontFees = 999.0 
        } else if country == .australia {
            // Australia: Lenders Mortgage Insurance (LMI) placeholder
            upfrontFees = 500.0 
        }
        
        // Auto-specific fees
        if type == .auto || type == .rv {
            upfrontFees += autoSalesTax + autoRegistrationFees
        }
        
        // Student Loan Grace Period (Capitalized Interest)
        if type == .student && gracePeriodMonths > 0 {
             let monthlyRateSimple = (annualRate / 100) / 12
             let accruedInterest = loanAmount * monthlyRateSimple * Double(gracePeriodMonths)
             loanAmount += accruedInterest
        }
        
        let periodicRate: Double
        let paymentsPerYear = Double(frequency.rawValue)
        
        // 2. Compounding Logic
        if country == .canada {
            // Semi-annual compounding converted to periodic
            periodicRate = pow(1 + (annualRate / 100) / 2, 2.0 / paymentsPerYear) - 1
        } else {
            periodicRate = (annualRate / 100) / paymentsPerYear
        }
        
        let numberOfPayments = years * frequency.rawValue
        var periodicPayment = 0.0
        
        if periodicRate > 0 {
            periodicPayment = loanAmount * (periodicRate * pow(1 + periodicRate, Double(numberOfPayments))) / (pow(1 + periodicRate, Double(numberOfPayments)) - 1)
        } else {
            periodicPayment = loanAmount / Double(numberOfPayments)
        }
        
        // Add FHA/PMI
        periodicPayment += periodicAddon
        
        var currentBalance = loanAmount
        var schedule: [AmortizationEntry] = []
        var totalInterest = 0.0
        var totalTax = upfrontFees
        
        let calendar = Calendar.current
        var periodCounter = 1
        
        // Adjust escrow for frequency
        let periodicEscrow = monthlyEscrow * 12 / paymentsPerYear
        
        // We cap at reasonable number of payments (e.g., 40 years * 26 = 1040)
        let maxPeriods = 40 * 26 + 100
        
        // Adjust extra payment from monthly to per-period
        // User always enters an amount they want to add PER MONTH,
        // so we scale it by (12 / paymentsPerYear) to get the per-period amount.
        let extraPerPeriod = extraMonthlyPayment * (12.0 / paymentsPerYear)
        
        while currentBalance > 0 && periodCounter <= maxPeriods {
            let interestPart = currentBalance * periodicRate
            var taxPart = 0.0
            
            // 3. Regional Recurring Tax Logic
            if country == .mexico {
                // IVA is 16% on the interest portion
                taxPart = interestPart * 0.16
            }
            
            var principalPart = (periodicPayment + extraPerPeriod - periodicAddon) - interestPart
            
            if principalPart > currentBalance {
                principalPart = currentBalance
            }
            
            currentBalance -= principalPart
            totalInterest += interestPart
            totalTax += taxPart
            
            schedule.append(AmortizationEntry(
                month: periodCounter, // Actually period number
                principal: principalPart,
                interest: interestPart,
                tax: taxPart + (country == .usa && type == .fha ? periodicAddon : 0) + periodicEscrow,
                balance: max(0, currentBalance)
            ))
            
            if currentBalance <= 0.001 { break }
            periodCounter += 1
        }
        
        let finalTotalTax = schedule.reduce(0) { $0 + $1.tax } + upfrontFees
        let finalTotalInterest = schedule.reduce(0) { $0 + $1.interest }
        let finalTotalPrincipal = schedule.reduce(0) { $0 + $1.principal }
        
        let totalPaid = finalTotalPrincipal + finalTotalInterest + finalTotalTax
        
        // Calculate Payoff Date
        let component = frequency == .monthly ? Calendar.Component.month : .day
        let valueToAdd = frequency == .monthly ? schedule.count : schedule.count * 14 // Approx 14 days for bi-weekly
        let payoffDate = calendar.date(byAdding: component == .month ? .month : .day, value: valueToAdd, to: Date()) ?? Date()
        
        return LoanCalculation(
            monthlyPayment: periodicPayment + extraPerPeriod + periodicEscrow, // Per-period payment (not necessarily monthly)
            totalInterest: finalTotalInterest,
            totalTax: finalTotalTax,
            totalPayment: totalPaid,
            payoffDate: payoffDate,
            amortizationSchedule: schedule
        )
    }
    
    // Reverse calculation: Budget to Loan Amount
    func calculateMaxLoan(
        monthlyBudget: Double,
        annualRate: Double,
        years: Int,
        country: Country
    ) -> Double {
        let monthlyRate: Double
        if country == .canada {
            monthlyRate = pow(1 + (annualRate / 100) / 2, 2.0 / 12.0) - 1
        } else {
            monthlyRate = (annualRate / 100) / 12
        }
        
        let n = Double(years * 12)
        
        // Reverse EMI: P = EMI * [ (1+r)^n - 1 ] / [ r * (1+r)^n ]
        if monthlyRate > 0 {
            return monthlyBudget * (pow(1 + monthlyRate, n) - 1) / (monthlyRate * pow(1 + monthlyRate, n))
        } else {
            return monthlyBudget * n
        }
    }
    
    // Eligibility: Borrowing Power based on 28/36 rule (simplified)
    func calculateBorrowingPower(
        grossAnnualIncome: Double,
        monthlyDebts: Double,
        interestRate: Double,
        years: Int,
        country: Country
    ) -> Double {
        let monthlyIncome = grossAnnualIncome / 12
        let maxMonthlyPayment = (monthlyIncome * 0.28) - monthlyDebts
        
        return calculateMaxLoan(
            monthlyBudget: max(0, maxMonthlyPayment),
            annualRate: interestRate,
            years: years,
            country: country
        )
    }
    
    func calculateStampDuty(
        propertyValue: Double,
        country: Country,
        manualRate: Double? = nil,
        taxType: TaxCalculationType = .percentage,
        unitBase: Double = 100
    ) -> Double {
        if let rate = manualRate, rate > 0 {
            switch taxType {
            case .percentage:
                return propertyValue * (rate / 100)
            case .amountPerUnit:
                let denominator = unitBase > 0 ? unitBase : 100
                return (propertyValue / denominator) * rate
            case .flat:
                return rate
            }
        }
        
        switch country {
        case .uk:
            if propertyValue <= 250000 { return 0 }
            else if propertyValue <= 925000 { return (propertyValue - 250000) * 0.05 }
            else if propertyValue <= 1500000 { return 33750 + (propertyValue - 925000) * 0.10 }
            else { return 91250 + (propertyValue - 1500000) * 0.12 }
            
        case .australia:
            if propertyValue <= 300000 { return propertyValue * 0.03 }
            else if propertyValue <= 1000000 { return 9000 + (propertyValue - 300000) * 0.04 }
            else { return 37000 + (propertyValue - 1000000) * 0.05 }
            
        case .india:
            return propertyValue * 0.06
            
        case .germany:
            // Grunderwerbsteuer: varies by state (3.5% to 6.5%), average ~5%
            return propertyValue * 0.05
            
        case .france:
            // Droits de mutation à titre onéreux: ~5.80% for existing properties
            return propertyValue * 0.058
            
        default:
            return 0
        }
    }
}
