import SwiftUI

struct HowToUseView: View {
    @ObservedObject var settings = SettingsManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Intro
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.string("understanding_loan_title"))
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text(L10n.string("understanding_loan_para"))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // General Inputs
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: L10n.string("general_inputs"), icon: "list.bullet.rectangle")
                    
                    VStack(spacing: 20) {
                        ExplanationRow(title: L10n.loanAmount, description: "The total amount of money you are borrowing. Also known as Principal.", tip: "Found on your loan offer or pre-approval letter.")
                        
                        ExplanationRow(title: L10n.interestRate, description: "The annual cost of the loan as a percentage.", tip: "Look for 'Annual Percentage Rate' (APR) on lender documents.")
                        
                        ExplanationRow(title: L10n.loanTerm, description: "The duration of the loan in years.", tip: "Standard terms are 15 or 30 years for home, 3-7 for auto.")
                    }
                }
                
                // Advanced Calculators
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: L10n.string("advanced_tools_title"), icon: "briefcase.fill")
                    
                    VStack(spacing: 20) {
                        ExplanationRow(title: L10n.borrowingPower, description: L10n.string("borrowing_power_desc"), tip: "Uses the standard 28% front-end ratio for calculation.")
                        
                        ExplanationRow(title: L10n.comparison, description: L10n.string("loan_comparison_desc"), tip: "Great for deciding between different interest rates or terms.")
                        
                        ExplanationRow(title: L10n.stampDuty, description: L10n.string("stamp_duty_desc"), tip: "Check your local government website for the most current rates.")
                    }
                }
                
                // Country Specific Rules
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: L10n.string("country_rules_title"), icon: "globe")
                    
                    VStack(alignment: .leading, spacing: 20) {
                        CountryRuleRow(flag: "🇺🇸", country: "USA", rules: "FHA MIP (Mortgage Insurance Premium) applied for FHA loans. Property taxes vary by state.")
                        CountryRuleRow(flag: "🇨🇦", country: "Canada", rules: "Mortgage compounding is semi-annual by law. Down payment requirements vary (usually 5% min).")
                        CountryRuleRow(flag: "🇮🇳", country: "India", rules: "18% GST (Goods and Services Tax) typically applied to processing fees and other charges.")
                        CountryRuleRow(flag: "🇲🇽", country: "Mexico", rules: "16% IVA (Value Added Tax) on interest payments is common for certain loan types.")
                        CountryRuleRow(flag: "🇬🇧", country: "United Kingdom", rules: "Stamp Duty Land Tax (SDLT) applies to property purchases above certain thresholds.")
                        CountryRuleRow(flag: "🇦🇺", country: "Australia", rules: "Stamp Duty (Transfer Duty) varies by state. Lenders Mortgage Insurance (LMI) if deposit < 20%.")
                        CountryRuleRow(flag: "🇩🇪", country: "Germany", rules: "Grunderwerbsteuer (property transfer tax) varies from 3.5% to 6.5% by Bundesland. No national mortgage insurance requirement.")
                        CountryRuleRow(flag: "🇫🇷", country: "France", rules: "Droits de mutation (~5.8%) apply to property purchases. New-build properties subject to TVA (20%) instead.")
                    }
                }
                .padding(.horizontal)
                
                // Where to Find
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: L10n.string("where_to_find_title"), icon: "doc.text.magnifyingglass")
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("• \(L10n.string("loan_estimate_title")):")
                            .fontWeight(.bold)
                        Text(L10n.string("loan_estimate_desc"))
                            .padding(.bottom, 4)
                        
                        Text("• \(L10n.string("closing_disclosure_title")):")
                            .fontWeight(.bold)
                        Text(L10n.string("closing_disclosure_desc"))
                            .padding(.bottom, 4)
                        
                        Text("• \(L10n.string("lender_website_title")):")
                            .fontWeight(.bold)
                        Text(L10n.string("lender_website_desc"))
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer(minLength: 50)
            }
            .padding(.vertical)
        }
        .id(settings.appLanguage)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(L10n.howToUse)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.indigo)
            Text(title)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
        }
        .padding(.horizontal)
    }
}

struct ExplanationRow: View {
    let title: String
    let description: String
    let tip: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
            
            Text(description)
                .font(.footnote)
                .foregroundColor(.secondary)
            
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                Text("Tip: \(tip)")
                    .font(.caption)
                    .italic()
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct CountryRuleRow: View {
    let flag: String
    let country: String
    let rules: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(flag)
                Text(country)
                    .fontWeight(.bold)
            }
            .font(.subheadline)
            
            Text(rules)
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        HowToUseView()
    }
}
