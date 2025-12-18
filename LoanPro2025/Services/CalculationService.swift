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
        gracePeriodMonths: Int = 0
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
        
        while currentBalance > 0 && periodCounter <= maxPeriods {
            let interestPart = currentBalance * periodicRate
            var taxPart = 0.0
            
            // 3. Regional Recurring Tax Logic
            if country == .mexico {
                // IVA is 16% on the interest portion
                taxPart = interestPart * 0.16
            }
            
            var principalPart = (periodicPayment + extraMonthlyPayment - periodicAddon) - interestPart
            
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
            monthlyPayment: periodicPayment + extraMonthlyPayment + periodicEscrow, // This is actually Periodic Payment
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
}
