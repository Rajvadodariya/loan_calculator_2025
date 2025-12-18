import SwiftUI
import Charts

struct ResultsView: View {
    @ObservedObject var viewModel: CalculatorViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let result = viewModel.result {
                    summaryCards(result: result)
                    
                    chartSection(result: result)
                    
                    amortizationSection(result: result)
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Analysis")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Export PDF action
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
    
    func summaryCards(result: LoanCalculation) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ResultCard(title: "Total Interest", value: CurrencyFormatter.format(amount: result.totalInterest, country: viewModel.selectedCountry), icon: "percent", color: .orange)
                ResultCard(title: "Total Tax/Fees", value: CurrencyFormatter.format(amount: result.totalTax, country: viewModel.selectedCountry), icon: "building.columns", color: .red)
            }
            
            ResultCard(title: "Total Payment", value: CurrencyFormatter.format(amount: result.totalPayment, country: viewModel.selectedCountry), icon: "creditcard.fill", color: .indigo)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Payoff Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(result.payoffDate, style: .date)
                        .font(.headline)
                }
                Spacer()
                Image(systemName: "calendar")
                    .foregroundColor(.indigo)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
    
    func chartSection(result: LoanCalculation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Principal vs. Interest")
                .font(.headline)
            
            Chart {
                BarMark(
                    x: .value("Category", "Principal"),
                    y: .value("Amount", result.principalAmount)
                )
                .foregroundStyle(Color.indigo)
                
                BarMark(
                    x: .value("Category", "Interest"),
                    y: .value("Amount", result.totalInterest)
                )
                .foregroundStyle(Color.orange)
                
                if result.totalTax > 0 {
                    BarMark(
                        x: .value("Category", "Tax/Fees"),
                        y: .value("Amount", result.totalTax)
                    )
                    .foregroundStyle(Color.red)
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    func amortizationSection(result: LoanCalculation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Amortization Schedule")
                .font(.headline)
            
            VStack(spacing: 0) {
                HStack {
                    Text("Month").frame(width: 50, alignment: .leading)
                    Text("Principal").frame(maxWidth: .infinity, alignment: .trailing)
                    Text("Interest").frame(maxWidth: .infinity, alignment: .trailing)
                    Text("Balance").frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
                
                Divider()
                
                ForEach(result.amortizationSchedule.prefix(60)) { entry in
                    HStack {
                        Text("\(entry.month)").frame(width: 50, alignment: .leading)
                        Text(formatCompact(entry.principal)).frame(maxWidth: .infinity, alignment: .trailing)
                        Text(formatCompact(entry.interest)).frame(maxWidth: .infinity, alignment: .trailing)
                        Text(formatCompact(entry.balance)).frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .font(.system(.caption, design: .monospaced))
                    .padding(.vertical, 8)
                    
                    if entry.month % 12 == 0 {
                        Divider()
                        Text("Year \(entry.month / 12)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.vertical, 4)
                        Divider()
                    } else {
                        Divider()
                    }
                }
                
                if result.amortizationSchedule.count > 60 {
                    Text("Showing first 5 years...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    func formatCompact(_ value: Double) -> String {
        if value >= 1000000 {
            return String(format: "%.1fM", value / 1000000)
        } else if value >= 1000 {
            return String(format: "%.1fK", value / 1000)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

struct ResultCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.headline)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}
