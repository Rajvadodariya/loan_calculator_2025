import SwiftUI

struct RewardAdButton: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    let onRewardEarned: () -> Void
    
    @ObservedObject private var adService = AdService.shared
    @State private var isLoading = false
    
    init(
        title: String = "Watch Ad to Unlock",
        subtitle: String? = nil,
        icon: String = "play.circle.fill",
        color: Color = .indigo,
        onRewardEarned: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.onRewardEarned = onRewardEarned
    }
    
    var body: some View {
        Button(action: showRewardAd) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: icon)
                        .font(.title3)
                }
                
                 VStack(alignment: .leading, spacing: 2) {
                     Text(title)
                         .font(.system(.subheadline, design: .rounded))
                         .fontWeight(.bold)
                         .tracking(-0.5) 
                     
                     if let subtitle = subtitle {
                         Text(subtitle)
                             .font(.system(.caption2, design: .rounded))
                             .opacity(0.8)
                             .tracking(-0.5)
                     }
                 }
                
                Spacer()
                
                Image(systemName: "gift.fill")
                    .font(.caption)
                    .padding(6)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isLoading || !adService.isRewardedReady)
        .opacity(adService.isRewardedReady ? 1.0 : 0.6)
    }
    
    private func showRewardAd() {
        isLoading = true
        adService.showRewarded { success in
            isLoading = false
            if success {
                onRewardEarned()
            }
        }
    }
}

// MARK: - Earn Coins Button (specific variant)
struct EarnCoinsButton: View {
    @ObservedObject private var coinManager = CoinManager.shared
    
    var body: some View {
        RewardAdButton(
            title: L10n.string("earn_coins_button"),
            subtitle: "+\(CoinManager.rewardAmount) coins",
            icon: "play.circle.fill",
            color: .orange
        ) {
            coinManager.earnCoins()
            HapticService.shared.impact(style: .heavy)
        }
    }
}
