import Foundation

// MARK: - AnyCodable Wrapper
/// A type-erasing `Codable` wrapper for heterogeneous JSONB data in Supabase.
struct AnyCodableValue: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let arrayVal = try? container.decode([AnyCodableValue].self) {
            value = arrayVal.map { $0.value }
        } else if let dictVal = try? container.decode([String: AnyCodableValue].self) {
            value = dictVal.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intVal = value as? Int {
            try container.encode(intVal)
        } else if let doubleVal = value as? Double {
            try container.encode(doubleVal)
        } else if let boolVal = value as? Bool {
            try container.encode(boolVal)
        } else if let stringVal = value as? String {
            try container.encode(stringVal)
        } else if let arrayVal = value as? [Any] {
            try container.encode(arrayVal.map { AnyCodableValue($0) })
        } else if let dictVal = value as? [String: Any] {
            try container.encode(dictVal.mapValues { AnyCodableValue($0) })
        } else {
            try container.encodeNil()
        }
    }
}

// MARK: - Saved Calculation Model
struct SavedCalculation: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var name: String
    let calculatorType: String
    let inputs: [String: AnyCodableValue]
    let result: [String: AnyCodableValue]
    let createdAt: Date
    var isFavorite: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case calculatorType = "calculator_type"
        case inputs
        case result
        case createdAt = "created_at"
        case isFavorite = "is_favorite"
    }
    
    /// Creates a SavedCalculation from a CalculatorViewModel's current state.
    static func from(name: String, viewModel: CalculatorViewModel, userId: UUID) -> SavedCalculation {
        var inputsDict: [String: AnyCodableValue] = [
            "loanAmount": AnyCodableValue(viewModel.loanAmount),
            "interestRate": AnyCodableValue(viewModel.interestRate),
            "loanTermYears": AnyCodableValue(viewModel.loanTermYears),
            "calculatorType": AnyCodableValue(viewModel.calculatorType.rawValue),
            "country": AnyCodableValue(viewModel.selectedCountry.rawValue),
            "downPayment": AnyCodableValue(viewModel.downPayment),
            "extraMonthlyPayment": AnyCodableValue(viewModel.extraMonthlyPayment),
            "processingFee": AnyCodableValue(viewModel.processingFee),
            "frequency": AnyCodableValue(viewModel.frequency.rawValue)
        ]
        
        // Calculator-specific inputs
        switch viewModel.calculatorType {
        case .auto, .rv:
            inputsDict["tradeInValue"] = AnyCodableValue(viewModel.tradeInValue)
            inputsDict["salesTaxRate"] = AnyCodableValue(viewModel.salesTaxRate)
            inputsDict["registrationFees"] = AnyCodableValue(viewModel.registrationFees)
        case .home, .fha:
            inputsDict["propertyTax"] = AnyCodableValue(viewModel.propertyTax)
            inputsDict["homeInsurance"] = AnyCodableValue(viewModel.homeInsurance)
            inputsDict["hoaFees"] = AnyCodableValue(viewModel.hoaFees)
        case .student:
            inputsDict["gracePeriodMonths"] = AnyCodableValue(viewModel.gracePeriodMonths)
        case .eligibility:
            inputsDict["annualIncome"] = AnyCodableValue(viewModel.annualIncome)
            inputsDict["monthlyDebts"] = AnyCodableValue(viewModel.monthlyDebts)
        case .stampDuty:
            inputsDict["propertyValue"] = AnyCodableValue(viewModel.propertyValue)
            inputsDict["manualTaxRate"] = AnyCodableValue(viewModel.manualTaxRate)
            inputsDict["useManualTaxRate"] = AnyCodableValue(viewModel.useManualTaxRate)
        case .reverse:
            inputsDict["monthlyBudget"] = AnyCodableValue(viewModel.monthlyBudget)
        case .comparison:
            inputsDict["comparisonLoanAmount"] = AnyCodableValue(viewModel.comparisonLoanAmount)
            inputsDict["comparisonInterestRate"] = AnyCodableValue(viewModel.comparisonInterestRate)
            inputsDict["comparisonLoanTermYears"] = AnyCodableValue(viewModel.comparisonLoanTermYears)
        default:
            break
        }
        
        // Serialize result summary (not the full amortization schedule)
        var resultDict: [String: AnyCodableValue] = [:]
        if let res = viewModel.result {
            resultDict["monthlyPayment"] = AnyCodableValue(res.monthlyPayment)
            resultDict["totalInterest"] = AnyCodableValue(res.totalInterest)
            resultDict["totalTax"] = AnyCodableValue(res.totalTax)
            resultDict["totalPayment"] = AnyCodableValue(res.totalPayment)
            resultDict["principalAmount"] = AnyCodableValue(res.principalAmount)
        }
        if viewModel.calculatorType == .eligibility || viewModel.calculatorType == .reverse {
            resultDict["affordableLoanAmount"] = AnyCodableValue(viewModel.affordableLoanAmount)
        }
        if viewModel.calculatorType == .stampDuty {
            resultDict["stampDutyAmount"] = AnyCodableValue(viewModel.stampDutyAmount)
        }
        
        return SavedCalculation(
            id: UUID(),
            userId: userId,
            name: name,
            calculatorType: viewModel.calculatorType.rawValue,
            inputs: inputsDict,
            result: resultDict,
            createdAt: Date(),
            isFavorite: false
        )
    }
    
    /// Restores saved inputs onto a CalculatorViewModel.
    func restore(to viewModel: CalculatorViewModel) {
        if let v = inputs["loanAmount"]?.value as? Double { viewModel.loanAmount = v }
        if let v = inputs["interestRate"]?.value as? Double { viewModel.interestRate = v }
        if let v = inputs["loanTermYears"]?.value as? Int { viewModel.loanTermYears = v }
        if let v = inputs["downPayment"]?.value as? Double { viewModel.downPayment = v }
        if let v = inputs["extraMonthlyPayment"]?.value as? Double { viewModel.extraMonthlyPayment = v }
        if let v = inputs["processingFee"]?.value as? Double { viewModel.processingFee = v }
        
        // Calculator-specific
        if let v = inputs["tradeInValue"]?.value as? Double { viewModel.tradeInValue = v }
        if let v = inputs["salesTaxRate"]?.value as? Double { viewModel.salesTaxRate = v }
        if let v = inputs["registrationFees"]?.value as? Double { viewModel.registrationFees = v }
        if let v = inputs["propertyTax"]?.value as? Double { viewModel.propertyTax = v }
        if let v = inputs["homeInsurance"]?.value as? Double { viewModel.homeInsurance = v }
        if let v = inputs["hoaFees"]?.value as? Double { viewModel.hoaFees = v }
        if let v = inputs["gracePeriodMonths"]?.value as? Int { viewModel.gracePeriodMonths = v }
        if let v = inputs["annualIncome"]?.value as? Double { viewModel.annualIncome = v }
        if let v = inputs["monthlyDebts"]?.value as? Double { viewModel.monthlyDebts = v }
        if let v = inputs["propertyValue"]?.value as? Double { viewModel.propertyValue = v }
        if let v = inputs["manualTaxRate"]?.value as? Double { viewModel.manualTaxRate = v }
        if let v = inputs["useManualTaxRate"]?.value as? Bool { viewModel.useManualTaxRate = v }
        if let v = inputs["monthlyBudget"]?.value as? Double { viewModel.monthlyBudget = v }
        if let v = inputs["comparisonLoanAmount"]?.value as? Double { viewModel.comparisonLoanAmount = v }
        if let v = inputs["comparisonInterestRate"]?.value as? Double { viewModel.comparisonInterestRate = v }
        if let v = inputs["comparisonLoanTermYears"]?.value as? Int { viewModel.comparisonLoanTermYears = v }
    }
    
    /// Formatted date display for the history list.
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    /// Icon for the calculator type.
    var icon: String {
        CalculatorType(rawValue: calculatorType)?.icon ?? "briefcase"
    }
    
    /// Localized name of the calculator type.
    var localizedCalculatorType: String {
        CalculatorType(rawValue: calculatorType)?.localizedName ?? calculatorType
    }
    
    /// Summary value (monthly payment or stamp duty).
    var summaryValue: String {
        if let mp = result["monthlyPayment"]?.value as? Double, mp > 0 {
            return CurrencyFormatter.format(amount: mp, country: countryFromInputs)
        }
        if let sd = result["stampDutyAmount"]?.value as? Double, sd > 0 {
            return CurrencyFormatter.format(amount: sd, country: countryFromInputs)
        }
        if let af = result["affordableLoanAmount"]?.value as? Double, af > 0 {
            return CurrencyFormatter.format(amount: af, country: countryFromInputs)
        }
        return "--"
    }
    
    private var countryFromInputs: Country {
        if let raw = inputs["country"]?.value as? String,
           let country = Country(rawValue: raw) {
            return country
        }
        return .usa
    }
}
