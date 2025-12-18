import Foundation

enum CalculatorType: String, CaseIterable, Identifiable {
    case simple = "Simple Loan"
    case auto = "Auto / Car"
    case home = "Home / Mortgage"
    case fha = "FHA Loan (USA)"
    case rv = "RV Loan"
    case student = "Student Loan"
    case personal = "Personal Loan"
    case reverse = "Loan Payment (Reverse)"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .simple: return "briefcase"
        case .auto: return "car"
        case .home: return "house"
        case .fha: return "building.columns"
        case .rv: return "bus"
        case .student: return "graduationcap"
        case .personal: return "person"
        case .reverse: return "arrow.left.arrow.right"
        }
    }
}
