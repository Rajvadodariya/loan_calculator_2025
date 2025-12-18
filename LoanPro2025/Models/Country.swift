import Foundation

enum Country: String, CaseIterable, Identifiable {
    case usa = "USA"
    case canada = "Canada"
    case mexico = "Mexico"
    case india = "India"
    case indonesia = "Indonesia"
    
    var id: String { self.rawValue }
    
    var currencyCode: String {
        switch self {
        case .usa: return "USD"
        case .canada: return "CAD"
        case .mexico: return "MXN"
        case .india: return "INR"
        case .indonesia: return "IDR"
        }
    }
    
    var flag: String {
        switch self {
        case .usa: return "🇺🇸"
        case .canada: return "🇨🇦"
        case .mexico: return "🇲🇽"
        case .india: return "🇮🇳"
        case .indonesia: return "🇮🇩"
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
        default: return "Standard"
        }
    }
}

enum CompoundingType {
    case monthly
    case semiAnnual
}
