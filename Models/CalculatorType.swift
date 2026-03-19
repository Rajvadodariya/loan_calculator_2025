
import Foundation

enum CalculatorType: String, CaseIterable, Identifiable {
    case simple = "EMI Calculator"
    case auto = "Auto / Car"
    case home = "Home / Mortgage"
    case fha = "FHA Loan (USA)"
    case rv = "RV Loan"
    case student = "Student Loan"
    case personal = "Personal Loan"
    case reverse = "Loan Payment (Reverse)"
    case eligibility = "Borrowing Power"
    case comparison = "Loan Comparison"
    case stampDuty = "Stamp Duty / Tax"
    case rentVsBuy = "Rent vs. Buy"
    case debtPayoff = "Debt Payoff Planner"
    
    var id: String { self.rawValue }
    
    /// Localized display name
    var localizedName: String {
        switch self {
        case .simple: return L10n.emiCalculator
        case .auto: return L10n.autoLoan
        case .home: return L10n.homeLoan
        case .fha: return L10n.fhaLoan
        case .rv: return L10n.rvLoan
        case .student: return L10n.studentLoan
        case .personal: return L10n.personalLoan
        case .reverse: return L10n.reverseCalc
        case .eligibility: return L10n.eligibility
        case .comparison: return L10n.comparison
        case .stampDuty: return L10n.stampDuty
        case .rentVsBuy: return L10n.string("rent_vs_buy")
        case .debtPayoff: return L10n.string("debt_payoff")
        }
    }
    
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
        case .eligibility: return "chart.bar.fill"
        case .comparison: return "equal.square"
        case .stampDuty: return "percent"
        case .rentVsBuy: return "house.and.flag"
        case .debtPayoff: return "chart.line.downtrend.xyaxis"
        }
    }
    
    var supportedCountries: [Country] {
        switch self {
        case .fha:
            return [.usa]
        default:
            return Country.allCases
        }
    }
    
    func guidance(for country: Country) -> CalculatorGuidance {
        func getSource(for input: String) -> String {
            switch (input, country) {
            case ("Loan Amount", .usa): return L10n.string("source_loan_amount_usa")
            case ("Loan Amount", .india): return L10n.string("source_loan_amount_india")
            case ("Annual Income", .usa): return L10n.string("source_annual_income_usa")
            case ("Annual Income", .india): return L10n.string("source_annual_income_india")
            case ("Property Tax", .usa): return L10n.string("source_property_tax_usa")
            case ("Property Tax", .india): return L10n.string("source_property_tax_india")
            case ("Sales Tax", .usa): return L10n.string("source_sales_tax_usa")
            case ("Sales Tax", .india): return L10n.string("source_sales_tax_india")
            case ("Property Value", .usa): return L10n.string("source_property_value_usa")
            case ("Property Value", .india): return L10n.string("source_property_value_india")
            default: return L10n.string("source_financial_statements")
            }
        }
        
        func getRules() -> [String] {
            var rules: [String] = []
            switch country {
            case .usa:
                rules = [L10n.string("rule_usa_fha"), L10n.string("rule_usa_pmi")]
            case .india:
                rules = [L10n.string("rule_india_gst")]
            case .uk:
                rules = [L10n.string("rule_uk_sdlt"), L10n.string("rule_uk_erc")]
            case .australia:
                rules = [L10n.string("rule_aus_daily_int"), L10n.string("rule_aus_lmi")]
            default:
                break
            }
            return rules
        }

        switch self {
        case .simple, .personal:
            return CalculatorGuidance(
                description: L10n.string("desc_simple_guidance"),
                inputs: [
                    (L10n.loanAmount, L10n.string("explain_loan_amount"), getSource(for: "Loan Amount")),
                    (L10n.interestRate, L10n.string("explain_interest_rate"), L10n.string("source_lender_rates")),
                    (L10n.loanTerm, L10n.string("explain_loan_term"), L10n.string("source_repayment_schedule"))
                ],
                tips: [L10n.string("tip_total_interest_comp"), L10n.string("tip_loan_fees")],
                rules: getRules(),
                formula: L10n.string("formula_emi")
            )
        case .auto, .rv:
            let secondaryInputs = self == .auto ? [
                (L10n.string("input_trade_in"), L10n.string("explain_trade_in"), getSource(for: "Trade-In Value")),
                (L10n.string("input_sales_tax"), L10n.string("explain_sales_tax"), getSource(for: "Sales Tax"))
            ] : [
                (L10n.string("input_registration"), L10n.string("explain_registration"), L10n.string("source_dmv"))
            ]
            return CalculatorGuidance(
                description: self == .auto ? L10n.string("desc_auto_guidance") : L10n.string("desc_rv_guidance"),
                inputs: [
                    (L10n.loanAmount, L10n.string("explain_loan_amount"), getSource(for: "Loan Amount")),
                    (L10n.interestRate, L10n.string("explain_interest_rate"), L10n.string("source_lender_rates")),
                    (L10n.downPayment, L10n.string("explain_down_payment"), "Personal savings.")
                ] + secondaryInputs,
                tips: [L10n.string("tip_rv_terms"), L10n.string("tip_drive_away")],
                rules: getRules(),
                formula: L10n.string("formula_auto")
            )
        case .home, .fha:
            return CalculatorGuidance(
                description: self == .home ? L10n.string("desc_home_guidance") : L10n.string("desc_fha_guidance"),
                inputs: [
                    (L10n.string("input_property_value"), L10n.string("explain_property_value"), getSource(for: "Property Value")),
                    (L10n.downPayment, L10n.string("explain_down_payment"), "Savings or equity."),
                    (L10n.propertyTax, L10n.string("explain_property_tax"), getSource(for: "Property Tax")),
                    (L10n.homeInsurance, L10n.string("explain_home_insurance"), L10n.string("source_insurance_quote"))
                ],
                tips: [L10n.string("tip_hoa_fees"), L10n.string("tip_fha_down")],
                rules: getRules(),
                formula: L10n.string("formula_home")
            )
        case .student:
            return CalculatorGuidance(
                description: L10n.string("desc_student_guidance"),
                inputs: [
                    (L10n.loanAmount, L10n.string("explain_loan_amount"), L10n.string("source_student_finance")),
                    (L10n.interestRate, L10n.string("explain_interest_rate"), L10n.string("source_lender_rates")),
                    (L10n.string("input_grace_period"), L10n.string("explain_grace_period"), "Financial aid office or student loan servicer.")
                ],
                tips: [L10n.string("tip_student_interest"), L10n.string("tip_student_forgiveness")],
                rules: getRules(),
                formula: L10n.string("formula_student")
            )
        case .eligibility:
            return CalculatorGuidance(
                description: L10n.string("desc_eligibility_guidance"),
                inputs: [
                    (L10n.string("input_annual_income"), L10n.string("explain_annual_income"), getSource(for: "Annual Income")),
                    (L10n.string("input_monthly_debts"), L10n.string("explain_monthly_debts"), getSource(for: "Monthly Debts"))
                ],
                tips: [L10n.string("tip_dti_ratio"), L10n.string("tip_dti_reduction")],
                rules: [L10n.string("rule_dti_cap")],
                formula: L10n.string("formula_eligibility")
            )
        case .stampDuty:
            return CalculatorGuidance(
                description: L10n.string("desc_stamp_duty_guidance"),
                inputs: [
                    (L10n.string("input_property_value"), L10n.string("explain_property_value"), getSource(for: "Property Value"))
                ],
                tips: [L10n.string("tip_first_time_buyer"), L10n.string("tip_concessions")],
                rules: [L10n.string("rule_progressive_rates")],
                formula: L10n.string("formula_tax_bands")
            )
        case .reverse:
            return CalculatorGuidance(
                description: L10n.string("desc_reverse_guidance"),
                inputs: [
                    (L10n.string("input_monthly_budget"), L10n.string("explain_monthly_budget"), L10n.string("source_budget_analysis")),
                    (L10n.interestRate, L10n.string("explain_interest_rate"), L10n.string("source_lender_rates")),
                    (L10n.loanTerm, L10n.string("explain_loan_term"), L10n.string("source_repayment_schedule"))
                ],
                tips: [L10n.string("tip_price_range")],
                rules: getRules(),
                formula: L10n.string("formula_reverse")
            )
        case .comparison:
            return CalculatorGuidance(
                description: L10n.string("desc_comparison_guidance"),
                inputs: [
                    (L10n.string("input_loan_a_b"), L10n.string("explain_loan_a_b"), L10n.string("source_loan_offers"))
                ],
                tips: [L10n.string("tip_total_interest_comp"), L10n.string("tip_lower_payment_cost")],
                rules: getRules(),
                formula: L10n.string("formula_comparison")
            )
        case .rentVsBuy:
            return CalculatorGuidance(
                description: L10n.string("desc_rent_vs_buy_guidance"),
                inputs: [
                    (L10n.string("monthly_rent"), L10n.string("explain_monthly_budget"), L10n.string("source_budget_analysis")),
                    (L10n.string("input_property_value"), L10n.string("explain_property_value"), getSource(for: "Property Value")),
                    (L10n.string("home_appreciation"), "Average annual home value increase.", L10n.string("source_financial_statements"))
                ],
                tips: [L10n.string("tip_total_interest_comp"), L10n.string("tip_hoa_fees")],
                rules: getRules(),
                formula: "Rent: ΣRent*(1+g)^n vs Buy: Mortgage + Costs - Equity"
            )
        case .debtPayoff:
            return CalculatorGuidance(
                description: L10n.string("desc_debt_payoff_guidance"),
                inputs: [
                    (L10n.string("debt_balance"), "Outstanding balance on each debt.", L10n.string("source_financial_statements")),
                    (L10n.interestRate, L10n.string("explain_interest_rate"), L10n.string("source_lender_rates")),
                    (L10n.string("minimum_payment"), "Required minimum monthly payment.", "Your loan statement.")
                ],
                tips: [L10n.string("tip_total_interest_comp")],
                rules: getRules(),
                formula: "Snowball: smallest balance first. Avalanche: highest rate first."
            )
        }
    }
}

struct CalculatorGuidance {
    let description: String
    let inputs: [(name: String, explanation: String, source: String)]
    let tips: [String]
    let rules: [String]
    let formula: String
}
