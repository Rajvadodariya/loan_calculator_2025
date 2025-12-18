import Foundation

struct AmortizationEntry: Identifiable {
    let id = UUID()
    let month: Int
    let principal: Double
    let interest: Double
    let tax: Double
    let balance: Double
    
    var totalPayment: Double {
        principal + interest + tax
    }
}

struct LoanCalculation {
    let monthlyPayment: Double
    let totalInterest: Double
    let totalTax: Double
    let totalPayment: Double
    let payoffDate: Date
    let amortizationSchedule: [AmortizationEntry]
    
    // For charts
    var principalAmount: Double {
        amortizationSchedule.reduce(0) { $0 + $1.principal }
    }
}
