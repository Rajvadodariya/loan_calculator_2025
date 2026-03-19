import SwiftUI

struct SaveCalculationSheet: View {
    @ObservedObject var storageService = CalculationStorageService.shared
    @ObservedObject var viewModel: CalculatorViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var calculationName: String = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.indigo, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "bookmark.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Text("Save Calculation")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text("Give your calculation a name so you can find it later.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g. Home Loan — Mar 2026", text: $calculationName)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                }
                .padding(.horizontal)
                
                // Summary preview
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: viewModel.calculatorType.icon)
                            .foregroundColor(.indigo)
                        Text(viewModel.calculatorType.localizedName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        if let result = viewModel.result {
                            Text(CurrencyFormatter.format(amount: result.monthlyPayment, country: viewModel.selectedCountry))
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.indigo)
                        }
                    }
                    .padding()
                    .background(Color.indigo.opacity(0.06))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Save button
                Button(action: save) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: calculationName.trimmingCharacters(in: .whitespaces).isEmpty
                                ? [.gray, .gray]
                                : [.indigo, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .disabled(calculationName.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorText)
            }
            .onAppear {
                // Auto-suggest a name
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM yyyy"
                let dateString = dateFormatter.string(from: Date())
                calculationName = "\(viewModel.calculatorType.localizedName) — \(dateString)"
            }
        }
        .presentationDetents([.medium])
    }
    
    private func save() {
        let name = calculationName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        
        isSaving = true
        Task {
            let success = await storageService.saveCalculation(name: name, viewModel: viewModel)
            isSaving = false
            if success {
                dismiss()
            } else {
                errorText = storageService.errorMessage ?? "Unknown error"
                showError = true
            }
        }
    }
}
