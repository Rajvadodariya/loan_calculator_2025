import SwiftUI

struct SupportView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settings = SettingsManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                
                VStack(spacing: 16) {
                    supportCard(
                        title: L10n.string("email_support"),
                        subtitle: L10n.string("email_response"),
                        icon: "envelope.fill",
                        color: .blue,
                        action: {
                            // Link to email
                            let email = "support@loanpro.app"
                            if let url = URL(string: "mailto:\(email)") {
                                if UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url)
                                } else {
                                    // Fallback: Copy to clipboard or show alert
                                    UIPasteboard.general.string = email
                                }
                            }
                        }
                    )
                    
                    supportCard(
                        title: L10n.string("report_bug"),
                        subtitle: L10n.string("report_bug_subtitle"),
                        icon: "ladybug.fill",
                        color: .red,
                        action: {
                            // Link to bug report form or email
                        }
                    )
                    
                    supportCard(
                        title: L10n.string("common_questions"),
                        subtitle: L10n.string("common_questions_subtitle"),
                        icon: "questionmark.circle.fill",
                        color: .orange,
                        action: {
                            // This would be handled by navigation usually
                        }
                    )
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.string("app_version"))
                        .font(.headline)
                    
                    HStack {
                        Text("LoanPro 2025")
                        Spacer()
                        Text("v1.0.0")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
        }
        .id(settings.appLanguage)
        .navigationTitle(L10n.string("support"))
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.string("need_help"))
                .font(.largeTitle)
                .fontWeight(.bold)
            Text(L10n.string("help_subtitle"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }
    
    private func supportCard(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct SupportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SupportView()
        }
    }
}
