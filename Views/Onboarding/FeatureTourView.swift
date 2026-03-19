import SwiftUI

struct FeatureTourView: View {
    @ObservedObject var settings = SettingsManager.shared
    @State private var currentPage = 0
    
    private let pages: [(icon: String, color: Color, titleKey: String, subtitleKey: String)] = [
        ("square.grid.2x2.fill", .indigo, "tour_calculators_title", "tour_calculators_subtitle"),
        ("chart.bar.doc.horizontal.fill", .teal, "tour_analysis_title", "tour_analysis_subtitle"),
        ("circle.fill", .orange, "tour_coins_title", "tour_coins_subtitle")
    ]
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            LinearGradient(
                colors: [
                    pages[currentPage].color.opacity(0.15),
                    Color(uiColor: .systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(L10n.string("skip")) {
                        completeTour()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding()
                }
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        tourPage(
                            icon: page.icon,
                            color: page.color,
                            title: L10n.string(page.titleKey),
                            subtitle: L10n.string(page.subtitleKey)
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Page indicator + button
                VStack(spacing: 24) {
                    // Custom page dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? pages[currentPage].color : Color.gray.opacity(0.3))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    
                    // Action button
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            completeTour()
                        }
                    }) {
                        HStack {
                            Text(currentPage < pages.count - 1 ? L10n.string("next") : L10n.string("get_started"))
                                .fontWeight(.bold)
                            Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                                .font(.subheadline.bold())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [pages[currentPage].color, pages[currentPage].color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: pages[currentPage].color.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal, 32)
                    .animation(.easeInOut, value: currentPage)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func tourPage(icon: String, color: Color, title: String, subtitle: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon with animated circle background
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(color.opacity(0.08))
                    .frame(width: 180, height: 180)
                
                Image(systemName: icon)
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.black)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
    }
    
    private func completeTour() {
        settings.hasSeenFeatureTour = true
        HapticService.shared.notification(type: .success)
    }
}
