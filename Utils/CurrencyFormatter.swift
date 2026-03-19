import Foundation

struct CurrencyFormatter {
    static func format(amount: Double, country: Country) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = country.currencyCode

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
        case .uk:
            formatter.locale = Locale(identifier: "en_GB")
        case .australia:
            formatter.locale = Locale(identifier: "en_AU")
        case .germany:
            formatter.locale = Locale(identifier: "de_DE") // 1.000,00 €
        case .france:
            formatter.locale = Locale(identifier: "fr_FR") // 1 000,00 €
        }

        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}
