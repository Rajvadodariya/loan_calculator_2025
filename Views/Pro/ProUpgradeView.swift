import SwiftUI
import StoreKit

struct ProUpgradeView: View {
    @ObservedObject var storeKit = StoreKitManager.shared
    @ObservedObject var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: String = StoreKitManager.yearlyProductID
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Feature comparison
                featureComparison
                
                // Subscription cards
                if storeKit.productsLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .tint(.white)
                        Text("Loading subscription options...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.vertical, 40)
                } else if storeKit.products.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text(storeKit.errorMessage ?? "No products available")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            Task { await storeKit.loadProducts() }
                        }) {
                            Text("Retry")
                                .fontWeight(.bold)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 30)
                } else if storeKit.isPro && !authService.isAuthenticated {
                    // Case: User is Pro locally but not logged in to sync with cloud
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                        
                        Text("LoanPro+ is Active")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("You've already upgraded on this device. Sign in to link your subscription with your account and use it on other devices.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            // Show sign in view (usually by dismissing and letting the caller handle it or triggering a sheet)
                            // For simplicity here, we'll dismiss and suggest going to settings
                            dismiss()
                        }) {
                            Text("Sign In to Sync")
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.vertical, 30)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(20)
                } else if storeKit.isPro && authService.isAuthenticated {
                    // Case: User is Pro and logged in
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.largeTitle)
                            .foregroundColor(.yellow)
                        
                        Text("You are a Pro Member!")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Your subscription is active and synced with your account (\(authService.userEmail)).")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: { dismiss() }) {
                            Text("Go Back")
                                .fontWeight(.bold)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 30)
                } else {
                    subscriptionCards
                    
                    // CTA button
                    purchaseButton
                }
                
                // Restore + Legal
                footerLinks
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.04, blue: 0.15),
                    Color(red: 0.12, green: 0.08, blue: 0.24)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("LoanPro+")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Welcome to LoanPro+! 🎉", isPresented: $showSuccessAlert) {
            Button("Continue") { dismiss() }
        } message: {
            if authService.isAuthenticated {
                Text("You now have access to all premium features. Your subscription is linked to your account.")
            } else {
                Text("You now have access to all premium features. Please sign in or create an account to link your subscription and use it on other devices.")
            }
        }
        .alert("Purchase Error", isPresented: $showErrorAlert) {
            Button("OK") {}
        } message: {
            Text(storeKit.errorMessage ?? "Something went wrong.")
        }
        .onChange(of: storeKit.products) { _, newProducts in
            // Default select the first product if nothing selected yet or selected is invalid
            if !newProducts.isEmpty {
                if !newProducts.contains(where: { $0.id == selectedPlan }) {
                    selectedPlan = newProducts.first?.id ?? StoreKitManager.yearlyProductID
                }
            }
        }
    }
    
    // MARK: - Header
    var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .orange.opacity(0.4), radius: 20)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
            }
            
            Text("Upgrade to LoanPro+")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.black)
                .foregroundColor(.white)
            
            Text("Unlock the full power of smart loan analysis")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Feature Comparison
    var featureComparison: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Text("Feature")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Free")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 60)
                
                Text("Pro")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .frame(width: 60)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            
            Divider().overlay(Color.white.opacity(0.1))
            
            // Features
            featureRow("All Calculators", free: "✅", pro: "✅")
            featureRow("Ads", free: "Shown", pro: "Hidden", proColor: .green)
            featureRow("PDF/CSV Export", free: "Coins", pro: "Free", proColor: .green)
            featureRow("Full Schedule", free: "Ad", pro: "Always", proColor: .green)
            featureRow("Saved Calcs", free: "5", pro: "∞", proColor: .green)
            featureRow("History", free: "10", pro: "∞", proColor: .green)
        }
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    func featureRow(_ name: String, free: String, pro: String, proColor: Color = .white) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(name)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(free)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 60)
                
                Text(pro)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(proColor)
                    .frame(width: 60)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            
            Divider().overlay(Color.white.opacity(0.05))
        }
    }
    
    // MARK: - Subscription Cards
    var subscriptionCards: some View {
        VStack(spacing: 12) {
            if let yearly = storeKit.yearlyProduct {
                subscriptionCard(
                    product: yearly,
                    title: "Yearly",
                    badge: storeKit.yearlySavingsPercentage > 0 ? "Save \(storeKit.yearlySavingsPercentage)%" : nil,
                    isSelected: selectedPlan == StoreKitManager.yearlyProductID
                )
                .onTapGesture { selectedPlan = StoreKitManager.yearlyProductID }
            }
            
            if let monthly = storeKit.monthlyProduct {
                subscriptionCard(
                    product: monthly,
                    title: "Monthly",
                    badge: nil,
                    isSelected: selectedPlan == StoreKitManager.monthlyProductID
                )
                .onTapGesture { selectedPlan = StoreKitManager.monthlyProductID }
            }
        }
    }
    
    func subscriptionCard(product: Product, title: String, badge: String?, isSelected: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)
                    
                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(6)
                    }
                }
                
                Text(product.displayPrice + (title == "Yearly" ? "/year" : "/month"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(isSelected ? .orange : .white.opacity(0.3))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.orange.opacity(0.15) : Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.orange.opacity(0.6) : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
        )
    }
    
    // MARK: - Purchase Button
    var purchaseButton: some View {
        Button(action: {
            Task {
                guard let product = storeKit.products.first(where: { $0.id == selectedPlan }) else { return }
                let success = await storeKit.purchase(product)
                if success {
                    // Force a sync if authenticated
                    if authService.isAuthenticated {
                        await storeKit.syncProStatusToCloud()
                    }
                    showSuccessAlert = true
                } else if storeKit.errorMessage != nil {
                    showErrorAlert = true
                }
            }
        }) {
            HStack {
                if storeKit.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "crown.fill")
                    Text("Subscribe Now")
                }
            }
            .font(.system(.headline, design: .rounded))
            .foregroundColor(Color(red: 0.07, green: 0.04, blue: 0.15))
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.yellow, .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .orange.opacity(0.3), radius: 15, y: 5)
        }
        .disabled(storeKit.isLoading || storeKit.products.isEmpty)
    }
    
    // MARK: - Footer
    var footerLinks: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task { await storeKit.restorePurchases() }
            }) {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            HStack(spacing: 16) {
                Link("Terms of Service", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.3))
                
                Link("Privacy Policy", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.3))
            }
            
            Text("Subscription auto-renews. Cancel anytime in Settings.")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.25))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom)
    }
}
