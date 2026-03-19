import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case german = "de"
    case spanish = "es"
    case hindi = "hi"
    case indonesian = "id"
    case french = "fr"
    case italian = "it"
    case portuguese = "pt"
    case dutch = "nl"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .german: return "Deutsch"
        case .spanish: return "Español"
        case .hindi: return "हिन्दी"
        case .indonesian: return "Bahasa Indonesia"
        case .french: return "Français"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .dutch: return "Nederlands"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .german: return "🇩🇪"
        case .spanish: return "🇲🇽"
        case .hindi: return "🇮🇳"
        case .indonesian: return "🇮🇩"
        case .french: return "🇫🇷"
        case .italian: return "🇮🇹"
        case .portuguese: return "🇵🇹"
        case .dutch: return "🇳🇱"
        }
    }
}
