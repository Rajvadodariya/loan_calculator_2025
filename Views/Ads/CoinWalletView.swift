import SwiftUI

struct CoinWalletView: View {
    @ObservedObject var coinManager = CoinManager.shared
    @State private var showEarnSheet = false
    
    var body: some View {
        Button(action: {
            showEarnSheet = true
            HapticService.shared.impact(style: .light)
        }) {
            HStack(spacing: 4) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.5), radius: 2)
                
                Text("\(coinManager.coinBalance)")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.yellow.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(coinManager.showCoinAnimation ? 1.2 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: coinManager.showCoinAnimation)
        }
        .sheet(isPresented: $showEarnSheet) {
            EarnCoinsSheet()
        }
    }
}

struct EarnCoinsSheet: View {
    @ObservedObject var coinManager = CoinManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Coin Balance Display
                VStack(spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow.opacity(0.4), radius: 10)
                    
                    Text("\(coinManager.coinBalance)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                    
                    Text(L10n.string("your_coins"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                Divider()
                
                // Pricing Info
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.string("coin_pricing"))
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "doc.richtext")
                            .foregroundColor(.indigo)
                        Text(L10n.string("pdf_report"))
                        Spacer()
                        Text("\(CoinManager.pdfCost) coins")
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    .font(.subheadline)
                    
                    HStack {
                        Image(systemName: "tablecells")
                            .foregroundColor(.indigo)
                        Text(L10n.string("csv_report"))
                        Spacer()
                        Text("\(CoinManager.csvCost) coins")
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                .cornerRadius(16)
                
                // Earn Coins
                if !StoreKitManager.shared.isPro {
                    VStack(spacing: 12) {
                        Text(L10n.string("earn_more_coins"))
                            .font(.headline)
                        
                        EarnCoinsButton()
                    }
                }
                
                Spacer()
                
                Text(L10n.string("coin_info_text"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle(L10n.string("coin_wallet"))
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
