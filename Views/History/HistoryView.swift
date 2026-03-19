import SwiftUI

struct HistoryView: View {
    @ObservedObject var storageService = CalculationStorageService.shared
    @ObservedObject var authService = AuthService.shared
    @State private var searchText = ""
    @State private var showDeleteAlert = false
    @State private var calculationToDelete: SavedCalculation?
    
    var body: some View {
        Group {
            if !authService.isAuthenticated {
                signInPrompt
            } else if storageService.savedCalculations.isEmpty && !storageService.isLoading {
                emptyState
            } else {
                calculationList
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search calculations...")
        .task {
            if authService.isAuthenticated {
                await storageService.loadCalculations()
            }
        }
        .alert("Delete Calculation", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let calc = calculationToDelete {
                    Task { await storageService.deleteCalculation(id: calc.id) }
                }
            }
            Button("Cancel", role: .cancel) {
                calculationToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete \"\(calculationToDelete?.name ?? "")\"?")
        }
    }
    
    // MARK: - Sign In Prompt
    var signInPrompt: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.indigo.opacity(0.6))
            
            Text("Sign In to Save Calculations")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
            
            Text("Your saved calculations will sync across devices when you sign in.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
    
    // MARK: - Empty State
    var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.indigo.opacity(0.4))
            
            Text("No Saved Calculations")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
            
            Text("After running a calculation, tap the bookmark icon to save it here for quick access later.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
    
    // MARK: - Calculation List
    var calculationList: some View {
        List {
            let grouped = storageService.grouped()
            let filtered = searchText.isEmpty ? grouped : [("Results", storageService.filtered(by: searchText))]
                .map { (key: $0.0, calculations: $0.1) }
            
            ForEach(filtered, id: \.key) { group in
                Section(header: Text(group.key)) {
                    ForEach(group.calculations) { calc in
                        NavigationLink {
                            restoredCalculatorView(for: calc)
                        } label: {
                            HistoryRow(calculation: calc) {
                                Task { await storageService.toggleFavorite(id: calc.id) }
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                calculationToDelete = calc
                                showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                Task { await storageService.toggleFavorite(id: calc.id) }
                            } label: {
                                Label(
                                    calc.isFavorite ? "Unfavorite" : "Favorite",
                                    systemImage: calc.isFavorite ? "star.slash" : "star.fill"
                                )
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if storageService.isLoading {
                ProgressView()
                    .scaleEffect(1.2)
            }
        }
    }
    
    // MARK: - Restore Navigation
    private func restoredCalculatorView(for calc: SavedCalculation) -> some View {
        let type = CalculatorType(rawValue: calc.calculatorType) ?? .simple
        let vm = CalculatorViewModel(type: type)
        calc.restore(to: vm)
        return CalculatorView(type: type, restoredViewModel: vm)
    }
}

// MARK: - History Row
struct HistoryRow: View {
    let calculation: SavedCalculation
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Calculator type icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.indigo.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: calculation.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.indigo)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(calculation.name)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    if calculation.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                
                Text(calculation.localizedCalculatorType)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(calculation.summaryValue)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.indigo)
                
                Text(calculation.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
