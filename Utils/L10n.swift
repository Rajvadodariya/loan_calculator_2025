import Foundation

/// Localization helper that uses the user's selected language preference
struct L10n {
    
    /// Cache for the current language bundle
    private static var cachedBundle: Bundle?
    private static var cachedLanguage: String?
    
    /// Get the bundle for the current language
    private static func getBundle() -> Bundle {
        let language = SettingsManager.shared.appLanguage.rawValue
        
        // Return cached bundle if language hasn't changed
        if let cached = cachedBundle, cachedLanguage == language {
            return cached
        }
        
        // Try to find the language bundle
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            cachedBundle = bundle
            cachedLanguage = language
            return bundle
        }
        
        // Fallback to English
        if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let bundle = Bundle(path: path) {
            cachedBundle = bundle
            cachedLanguage = "en"
            return bundle
        }
        
        // Last resort: main bundle
        cachedBundle = Bundle.main
        cachedLanguage = language
        return Bundle.main
    }
    
    /// Get localized string for the given key
    static func string(_ key: String) -> String {
        let bundle = getBundle()
        let value = bundle.localizedString(forKey: key, value: nil, table: nil)
        
        // If value equals key, try main bundle as fallback
        if value == key {
            return Bundle.main.localizedString(forKey: key, value: key, table: nil)
        }
        
        return value
    }
    
    /// Get localized string with format arguments
    static func string(_ key: String, _ args: CVarArg...) -> String {
        let format = string(key)
        return String(format: format, arguments: args)
    }
    
    /// Clear the cached bundle (call when language changes)
    static func clearCache() {
        cachedBundle = nil
        cachedLanguage = nil
    }
}

// MARK: - Common Strings
extension L10n {
    // Navigation & Titles
    static var welcome: String { string("welcome") }
    static var selectCountry: String { string("select_country") }
    static var selectCountrySubtitle: String { string("select_country_subtitle") }
    static var appLanguage: String { string("app_language") }
    static var continueButton: String { string("continue") }
    static var settings: String { string("settings") }
    static var analysis: String { string("analysis") }
    static var home: String { string("home") }
    
    // Calculator Types
    static var emiCalculator: String { string("emi_calculator") }
    static var autoLoan: String { string("auto_loan") }
    static var homeLoan: String { string("home_loan") }
    static var personalLoan: String { string("personal_loan") }
    static var studentLoan: String { string("student_loan") }
    static var fhaLoan: String { string("fha_loan") }
    static var eligibility: String { string("eligibility") }
    static var stampDuty: String { string("stamp_duty") }
    static var reverseCalc: String { string("reverse_calc") }
    static var comparison: String { string("comparison") }
    static var rvLoan: String { string("rv_loan") }
    
    // Input Fields
    static var loanAmount: String { string("loan_amount") }
    static var interestRate: String { string("interest_rate") }
    static var loanTerm: String { string("loan_term") }
    static var downPayment: String { string("down_payment") }
    static var tradeInValue: String { string("trade_in_value") }
    static var salesTax: String { string("sales_tax") }
    static var registrationFees: String { string("registration_fees") }
    static var propertyTax: String { string("property_tax") }
    static var homeInsurance: String { string("home_insurance") }
    static var hoaFees: String { string("hoa_fees") }
    static var gracePeriod: String { string("grace_period") }
    static var annualIncome: String { string("annual_income") }
    static var monthlyDebts: String { string("monthly_debts") }
    static var propertyValue: String { string("property_value") }
    static var extraPayment: String { string("extra_payment") }
    static var monthlyBudget: String { string("monthly_budget") }
    
    // Results
    static var monthlyPayment: String { string("monthly_payment") }
    static var totalInterest: String { string("total_interest") }
    static var totalPayment: String { string("total_payment") }
    static var totalTaxFees: String { string("total_tax_fees") }
    static var payoffDate: String { string("payoff_date") }
    static var borrowingPower: String { string("borrowing_power") }
    static var interestSaved: String { string("interest_saved") }
    static var timeSaved: String { string("time_saved") }
    
    // Sections
    static var loanSummary: String { string("loan_summary") }
    static var amortizationSchedule: String { string("amortization_schedule") }
    static var monthlyEscrow: String { string("monthly_escrow") }
    static var paymentBreakdown: String { string("payment_breakdown") }
    static var preferences: String { string("preferences") }
    static var supportFeedback: String { string("support_feedback") }
    static var legal: String { string("legal") }
    static var appInfo: String { string("app_info") }
    
    // Actions
    static var calculate: String { string("calculate") }
    static var viewDetailedReport: String { string("view_detailed_report") }
    static var share: String { string("share") }
    static var shareAsImage: String { string("share_as_image") }
    static var shareAsPDF: String { string("share_as_pdf") }
    static var shareAsExcel: String { string("share_as_excel") }
    static var shareFullReport: String { string("share_full_report") }
    static var shareAmortization: String { string("share_amortization") }
    
    // Settings
    static var country: String { string("country") }
    static var language: String { string("language") }
    static var howToUse: String { string("how_to_use") }
    static var getSupport: String { string("get_support") }
    static var shareApp: String { string("share_app") }
    static var rateApp: String { string("rate_app") }
    static var privacyPolicy: String { string("privacy_policy") }
    static var termsOfService: String { string("terms_of_service") }
    static var version: String { string("version") }
    
    // Units
    static var years: String { string("years") }
    static var months: String { string("months") }
    static var monthly: String { string("monthly") }
    static var yearly: String { string("yearly") }
    static var biWeekly: String { string("bi_weekly") }
    
    // Misc
    static var principal: String { string("principal") }
    static var interest: String { string("interest") }
    static var balance: String { string("balance") }
    static var month: String { string("month") }
    static var year: String { string("year") }
    static var showAll: String { string("show_all") }
    static var viewMore: String { string("view_more") }
    
    // ResultsView – Previously Hardcoded
    static var grossMonthlyIncome: String { string("gross_monthly_income") }
    static var maxEmiAllowed: String { string("max_emi_allowed") }
    static var existingMonthlyDebts: String { string("existing_monthly_debts") }
    static var netMonthlyForLoan: String { string("net_monthly_for_loan") }
    static var taxBreakdown: String { string("tax_breakdown") }
    static var appliedCustomRate: String { string("applied_custom_rate") }
    static var calculationBasis: String { string("calculation_basis") }
    static var vehicleDetails: String { string("vehicle_details") }
    static var rvDetails: String { string("rv_details") }
    static var studentLoanDetails: String { string("student_loan_details") }
    static var savingsAchievement: String { string("savings_achievement") }
    static var totalSavedLabel: String { string("total_saved_label") }
    static var timeSavedLabel: String { string("time_saved_label") }
    static var vehiclePrice: String { string("vehicle_price") }
    static var tuitionAmount: String { string("tuition_amount") }
    static var estimatedStampDuty: String { string("estimated_stamp_duty") }
    static var generatedByApp: String { string("generated_by_app") }
    static var eligibilityAnalysisTitle: String { string("eligibility_analysis_title") }
}
