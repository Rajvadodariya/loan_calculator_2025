import Foundation

enum Country: String, CaseIterable, Identifiable {
    case usa = "USA"
    case canada = "Canada"
    case mexico = "Mexico"
    case india = "India"
    case indonesia = "Indonesia"

    case uk = "United Kingdom"
    case australia = "Australia"
    case germany = "Germany"
    case france = "France"

    var id: String { self.rawValue }
    
    var currencyCode: String {
        switch self {
        case .usa: return "USD"
        case .canada: return "CAD"
        case .mexico: return "MXN"
        case .india: return "INR"
        case .indonesia: return "IDR"
        case .uk: return "GBP"
        case .australia: return "AUD"
        case .germany, .france: return "EUR"
        }
    }
    
    var currencySymbol: String {
        switch self {
        case .usa, .canada, .australia, .mexico: return "$"
        case .india: return "₹"
        case .indonesia: return "Rp"
        case .uk: return "£"
        case .germany, .france: return "€"
        }
    }
    
    var flag: String {
        switch self {
        case .usa: return "🇺🇸"
        case .canada: return "🇨🇦"
        case .mexico: return "🇲🇽"
        case .india: return "🇮🇳"
        case .indonesia: return "🇮🇩"
        case .uk: return "🇬🇧"
        case .australia: return "🇦🇺"
        case .germany: return "🇩🇪"
        case .france: return "🇫🇷"
        }
    }
    
    var compoundingType: CompoundingType {
        switch self {
        case .canada: return .semiAnnual
        default: return .monthly
        }
    }
    
    var taxRules: String {
        switch self {
        case .mexico: return "16% IVA on Interest"
        case .india: return "18% GST on Fees"
        case .usa: return "FHA MIP Rules"
        case .uk: return "SDLT Stamp Duty"
        case .australia: return "State Stamp Duty"
        case .germany: return "Grunderwerbsteuer (3.5–6.5%)"
        case .france: return "Droits de mutation (~5.8%)"
        default: return "Standard"
        }
    }

    var stampDutyBasis: String {
        switch self {
        case .usa:
            return L10n.string("stamp_duty_basis_usa")
        case .canada:
            return L10n.string("stamp_duty_basis_canada")
        case .mexico:
            return L10n.string("stamp_duty_basis_mexico")
        case .india:
            return L10n.string("stamp_duty_basis_india")
        case .indonesia:
            return L10n.string("stamp_duty_basis_indonesia")
        case .uk:
            return L10n.string("stamp_duty_basis_uk")
        case .australia:
            return L10n.string("stamp_duty_basis_australia")
        case .germany:
            return L10n.string("stamp_duty_basis_germany")
        case .france:
            return L10n.string("stamp_duty_basis_france")
        }
    }
    
    var maxLoanAmount: Double {
        switch self {
        case .indonesia: return 100_000_000_000 // 100 Billion IDR
        case .india: return 500_000_000 // 50 Crore INR
        case .mexico: return 200_000_000 // 200 Million MXN
        default: return 10_000_000 // 10 Million for USD, CAD, GBP, AUD, EUR
        }
    }
    
    var maxAnnualIncome: Double {
        switch self {
        case .indonesia: return 20_000_000_000 // 20 Billion IDR
        case .india: return 100_000_000 // 10 Crore INR
        case .mexico: return 40_000_000 // 40 Million MXN
        default: return 2_000_000 // 2 Million for USD, CAD, GBP, AUD, EUR
        }
    }
    
    var maxMonthlyBudget: Double {
        return maxAnnualIncome / 12
    }
    
    var maxMonthlyDebt: Double {
        return maxAnnualIncome / 20 // Reasonable cap for sliding debt
    }
    
    /// Step size for loan amount slider — scales with currency magnitude
    var loanStep: Double {
        switch self {
        case .indonesia: return 5_000_000   // 5 Juta — practical step for IDR
        case .india:     return 100_000     // 1 Lakh
        case .mexico:    return 50_000      // 50K MXN
        default:         return 1_000       // 1K for USD/GBP/EUR etc.
        }
    }
    
    /// Step size for extra payment slider
    var extraPaymentStep: Double {
        switch self {
        case .indonesia: return 500_000  // 500K IDR
        case .india:     return 1_000    // 1K INR
        case .mexico:    return 500      // 500 MXN
        default:         return 50       // 50 USD/GBP/EUR
        }
    }
    
    var defaultLanguage: AppLanguage {
        switch self {
        case .mexico:    return .spanish
        case .indonesia: return .indonesian
        case .germany:   return .german
        case .france:    return .french
        // India, USA, Canada, UK, Australia all default to English
        default:         return .english
        }
    }
}

enum CompoundingType {
    case monthly
    case semiAnnual
}
