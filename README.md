Act as an expert iOS Swift Developer and Digital Marketer. Please update the LoanPro2025 codebase to implement the following 4 marketing and UX growth hacks. Make precise updates to the following 4 files:

1. Update `Models/CalculatorType.swift`:
- Add a new function: `func displayTitle(for country: Country) -> String`
- For `.home, .fha`: Return "Home Loan EMI" (India), "Kalkulator KPR" (Indonesia), "Hipoteca" (Mexico), "Mortgage & APR" (UK), and "Mortgage Calculator" as default.
- For `.auto`: Return "Car Loan EMI" (India), "Car Finance" (UK), and "Auto Loan" as default.
- For `.personal`: Return "Personal Loan EMI" (India) and "Personal Loan" as default.
- For all others, return `self.localizedName`.

2. Update `Services/AdService.swift`:
- Add granular "Kill Switches" as `@Published var` booleans (default to true): `enableBannerAds`, `enableInterstitialAds`, `enableNativeAds`, `enablePdfExportRewardAd`, and `enableAmortizationUnlockAd`.
- Update `canShowInterstitial()` to return false if `enableInterstitialAds` is false.
- Update `loadInterstitial()` and `showInterstitial()` to guard against `!enableInterstitialAds`.

3. Update `Views/Calculators/CalculatorView.swift`:
- Change the `.navigationTitle` modifier on the main ScrollView from `type.localizedName` to `type.displayTitle(for: viewModel.selectedCountry)`.
- In the `InputField` struct, locate the `TextField` that uses `.keyboardType(.decimalPad)`. Add a `.toolbar` modifier to it with a `ToolbarItemGroup(placement: .keyboard)`. Add a `Spacer()` and a "Done" Button that sets `isFocused = false`.

4. Update `Views/Results/ResultsView.swift`:
- Import `StoreKit`.
- Add `@State private var showAuthSheet = false` and `@State private var showProUpgradeSheet = false`.
- Locate the ToolbarItem for the bookmark/save button. Change its action to: if `authService.isAuthenticated` is true, set `showSaveSheet = true`. If false, trigger a haptic warning and set `showAuthSheet = true`.
- Add `.sheet(isPresented: $showAuthSheet) { SignInView() }` to the main view.
- Update the `attemptExport` function: First check if `StoreKitManager.shared.isPro` OR `!adService.enablePdfExportRewardAd` is true; if so, execute the action and call `triggerReviewPrompt()`. Next, check if `coinManager` can afford it; if so, spend coins, execute action, and call `triggerReviewPrompt()`. If neither, set `pendingExportType = type` and set `showProUpgradeSheet = true` (Do NOT show the coin alert here).
- Add a sheet for `$showProUpgradeSheet` that presents `ProUpgradeView()`. Add an `.onDisappear` modifier to this sheet: if `!StoreKitManager.shared.isPro` and `adService.enablePdfExportRewardAd` is true, set `showCoinAlert = true` (fallback to ad). If they did buy Pro, call `retryPendingExport(type)`.
- Add a private helper function `triggerReviewPrompt()` that uses `DispatchQueue.main.asyncAfter(deadline: .now() + 2.0)` to call `SKStoreReviewController.requestReview(in: scene)`. Call this inside `retryPendingExport` upon successful generation.
