import SwiftUI

struct GuidanceView: View {
    let type: CalculatorType
    let country: Country
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        let guidance = type.guidance(for: country)
        
        return NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack(spacing: 20) {
                        Image(systemName: type.icon)
                            .font(.system(size: 40))
                            .foregroundColor(.indigo)
                            .frame(width: 80, height: 80)
                            .background(Color.indigo.opacity(0.1))
                            .cornerRadius(20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(type.localizedName)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(String(format: L10n.string("guidance_for"), country.rawValue))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Description
                    Text(guidance.description)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.indigo.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    
                    // Key Inputs
                    VStack(alignment: .leading, spacing: 16) {
                        Label(L10n.string("key_inputs"), systemImage: "keyboard")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(guidance.inputs, id: \.name) { input in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(input.name)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text(input.explanation)
                                    .font(.footnote)
                                    .foregroundColor(.primary)
                                
                                HStack(alignment: .top, spacing: 4) {
                                    Image(systemName: "magnifyingglass.circle.fill")
                                        .foregroundColor(.indigo)
                                    Text(String(format: L10n.string("where_to_find_label"), input.source))
                                        .font(.caption2)
                                        .italic()
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 4)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Tips
                    VStack(alignment: .leading, spacing: 16) {
                        Label(L10n.string("expert_tips"), systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundColor(.orange)
                            .padding(.horizontal)
                        
                        ForEach(guidance.tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(tip)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Rules
                    if !guidance.rules.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Label(String(format: L10n.string("rules_header"), country.rawValue), systemImage: "building.columns.fill")
                                .font(.headline)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                            
                            ForEach(guidance.rules, id: \.self) { rule in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    Text(rule)
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Formula
                    VStack(alignment: .leading, spacing: 12) {
                        Label(L10n.string("calculation_logic"), systemImage: "function")
                            .font(.headline)
                        
                        Text(guidance.formula)
                            .font(.system(.subheadline, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(12)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.string("done")) {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

#Preview {
    GuidanceView(type: .home, country: .usa)
}
