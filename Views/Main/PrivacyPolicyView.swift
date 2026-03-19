import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                
                Group {
                    policySection(
                        title: "Data Privacy",
                        content: "LoanPro 2025 is designed with your privacy as a top priority. We do not collect, store, or transmit any of the financial data you enter into our calculators."
                    )
                    
                    policySection(
                        title: "Local Processing",
                        content: "All calculations are performed locally on your device. Your income, loan amounts, and personal financial details never leave your phone."
                    )
                    
                    policySection(
                        title: "Third-Party Services",
                        content: "The app does not use any third-party analytics or tracking SDKs that could identify you or monitor your financial behavior."
                    )
                    
                    policySection(
                        title: "Cookies & Tracking",
                        content: "We do not use cookies or any persistent tracking identifiers."
                    )
                    
                    policySection(
                        title: "Changes to Policy",
                        content: "We may update our Privacy Policy from time to time. Any changes will be reflected on this page with an updated effective date."
                    )
                }
                
                Divider()
                    .padding(.vertical)
                
                Text("Last Updated: December 2024")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "hand.raised.shield.fill")
                .font(.system(size: 44))
                .foregroundColor(.indigo)
                .padding(.bottom, 8)
            
            Text("Your Financial Data Stays Yours")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("We believe your private numbers should stay private.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }
    
    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrivacyPolicyView()
        }
    }
}
