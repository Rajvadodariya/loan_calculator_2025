import Foundation

struct CurrencyFormatter {
    static func format(amount: Double, country: Country) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = country.currencyCode
        
        // Customizations for specific locales if needed
        switch country {
        case .india:
            formatter.locale = Locale(identifier: "en_IN")
        case .indonesia:
            formatter.locale = Locale(identifier: "id_ID")
        case .mexico:
            formatter.locale = Locale(identifier: "es_MX")
        case .canada:
            formatter.locale = Locale(identifier: "en_CA")
        case .usa:
            formatter.locale = Locale(identifier: "en_US")
        }
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}
