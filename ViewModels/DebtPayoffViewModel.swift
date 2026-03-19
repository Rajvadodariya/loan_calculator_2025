import SwiftUI
import Combine

struct DebtEntry: Identifiable {
    let id = UUID()
    var name: String = ""
    var balance: Double = 0
    var interestRate: Double = 0
    var minPayment: Double = 0
}

struct DebtPayoffResult {
    let totalMonths: Int
    let totalInterestPaid: Double
    let debtFreeDate: Date
    let monthlyBreakdown: [DebtMonthSnapshot]
    
    struct DebtMonthSnapshot: Identifiable {
        let id = UUID()
        let month: Int
        let totalBalance: Double
    }
}

class DebtPayoffViewModel: ObservableObject {
    @Published var debts: [DebtEntry] = [
        DebtEntry(name: "Credit Card", balance: 8000, interestRate: 22.0, minPayment: 200),
        DebtEntry(name: "Personal Loan", balance: 3000, interestRate: 8.0, minPayment: 100),
        DebtEntry(name: "Car Loan", balance: 15000, interestRate: 5.5, minPayment: 300)
    ]
    @Published var extraBudget: Double = 200
    @Published var selectedCountry: Country
    
    @Published var snowballResult: DebtPayoffResult?
    @Published var avalancheResult: DebtPayoffResult?
    
    init() {
        self.selectedCountry = SettingsManager.shared.selectedCountry
        calculate()
    }
    
    func addDebt() {
        debts.append(DebtEntry())
        calculate()
    }
    
    func removeDebt(at index: Int) {
        guard debts.count > 1 else { return }
        debts.remove(at: index)
        calculate()
    }
    
    func calculate() {
        let validDebts = debts.filter { $0.balance > 0 && $0.minPayment > 0 }
        guard !validDebts.isEmpty else {
            snowballResult = nil
            avalancheResult = nil
            return
        }
        
        snowballResult = simulatePayoff(debts: validDebts, strategy: .snowball)
        avalancheResult = simulatePayoff(debts: validDebts, strategy: .avalanche)
    }
    
    enum PayoffStrategy {
        case snowball  // Smallest balance first
        case avalanche // Highest interest rate first
    }
    
    private func simulatePayoff(debts: [DebtEntry], strategy: PayoffStrategy) -> DebtPayoffResult {
        var balances = debts.map { $0.balance }
        let rates = debts.map { $0.interestRate / 100 / 12 } // Monthly rates
        let minPayments = debts.map { $0.minPayment }
        let totalMinPayment = minPayments.reduce(0, +)
        let totalBudget = totalMinPayment + extraBudget
        
        var totalInterest: Double = 0
        var snapshots: [DebtPayoffResult.DebtMonthSnapshot] = []
        var month = 0
        let maxMonths = 600 // 50 years cap
        
        while balances.reduce(0, +) > 0.01 && month < maxMonths {
            month += 1
            
            // Accrue interest
            for i in 0..<balances.count {
                if balances[i] > 0 {
                    let interest = balances[i] * rates[i]
                    balances[i] += interest
                    totalInterest += interest
                }
            }
            
            // Determine order of extra payment
            let priorityOrder: [Int]
            switch strategy {
            case .snowball:
                priorityOrder = balances.enumerated()
                    .filter { $0.element > 0 }
                    .sorted { $0.element < $1.element }
                    .map { $0.offset }
            case .avalanche:
                priorityOrder = rates.enumerated()
                    .filter { balances[$0.offset] > 0 }
                    .sorted { $0.element > $1.element }
                    .map { $0.offset }
            }
            
            // Pay minimums on all debts
            var remaining = totalBudget
            for i in 0..<balances.count {
                if balances[i] > 0 {
                    let payment = min(minPayments[i], balances[i])
                    balances[i] -= payment
                    remaining -= payment
                }
            }
            
            // Apply extra to priority debt
            for i in priorityOrder {
                if remaining <= 0 { break }
                if balances[i] > 0 {
                    let extra = min(remaining, balances[i])
                    balances[i] -= extra
                    remaining -= extra
                }
            }
            
            let totalBalance = balances.reduce(0, +)
            snapshots.append(DebtPayoffResult.DebtMonthSnapshot(month: month, totalBalance: max(0, totalBalance)))
            
            if totalBalance <= 0.01 { break }
        }
        
        let calendar = Calendar.current
        let debtFreeDate = calendar.date(byAdding: .month, value: month, to: Date()) ?? Date()
        
        return DebtPayoffResult(
            totalMonths: month,
            totalInterestPaid: totalInterest,
            debtFreeDate: debtFreeDate,
            monthlyBreakdown: snapshots
        )
    }
}
