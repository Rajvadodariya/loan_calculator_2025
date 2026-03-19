import Foundation

struct RentVsBuyResult {
    let totalRentCost: Double
    let totalBuyCost: Double
    let buyEquity: Double
    let breakEvenYear: Int? // nil if renting is always cheaper
    let yearlyComparison: [YearSnapshot]
    
    struct YearSnapshot: Identifiable {
        let id = UUID()
        let year: Int
        let cumulativeRent: Double
        let cumulativeBuy: Double
        let equity: Double
    }
    
    /// Net cost advantage of buying (positive = buying saves money)
    var buyAdvantage: Double {
        totalRentCost - (totalBuyCost - buyEquity)
    }
}
