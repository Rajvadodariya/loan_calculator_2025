import SwiftUI

struct LanguageSelectionView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            Section(footer: Text("Language changes are saved automatically.")) {
                ForEach(AppLanguage.allCases) { language in
                    Button(action: {
                        settings.appLanguage = language
                        HapticService.shared.impact(style: .light)
                    }) {
                        HStack {
                            Text(language.flag)
                                .font(.title2)
                            
                            Text(language.displayName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if settings.appLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.indigo)
                                    .fontWeight(.bold)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(L10n.appLanguage)
        .navigationBarTitleDisplayMode(.inline)
    }
}
