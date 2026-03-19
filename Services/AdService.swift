import Foundation
import UIKit
import Combine
import GoogleMobileAds

// MARK: - Test Ad Unit IDs (Replace with production IDs before release)
enum AdUnitID {
    static let banner = "ca-app-pub-3940256099942544/2934735716"
    static let interstitial = "ca-app-pub-3940256099942544/4411468910"
    static let rewarded = "ca-app-pub-3940256099942544/1712485313"
    static let native = "ca-app-pub-3940256099942544/3986624511"
}

// MARK: - AdService
class AdService: NSObject, ObservableObject {
    static let shared = AdService()

    // MARK: - Published State
    @Published var isBannerReady: Bool = false
    @Published var isInterstitialReady: Bool = false
    @Published var isRewardedReady: Bool = false
    @Published var isNativeAdReady: Bool = false
    @Published var nativeAd: NativeAd?

    // MARK: - Interstitial Frequency Cap
    private var lastInterstitialTime: Date?
    private var interstitialCount: Int = 0
    private let interstitialCooldown: TimeInterval = 90
    private let maxInterstitialsPerSession: Int = 3

    // MARK: - Ad Objects
    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?
    private var nativeAdLoader: AdLoader?

    // MARK: - Callbacks
    private var rewardCompletion: ((Bool) -> Void)?
    private var interstitialCompletion: (() -> Void)?

    private override init() {
        super.init()
    }

    // MARK: - SDK Initialization
    func configure() {
        // Pro users don't need ads at all
        guard !StoreKitManager.shared.isPro else { return }
        
        MobileAds.shared.start { [weak self] _ in
            print("AdMob SDK initialized")
            Task { @MainActor [weak self] in
                self?.loadInterstitial()
                self?.loadRewarded()
                self?.loadNativeAd()
            }
        }
    }

    // MARK: - Interstitial Ad
    func loadInterstitial() {
        guard !StoreKitManager.shared.isPro else { return }
        let request = Request()
        InterstitialAd.load(with: AdUnitID.interstitial, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                print("AdMob: Failed to load interstitial: \(error.localizedDescription)")
                Task { @MainActor [weak self] in self?.isInterstitialReady = false }
                return
            }
            Task { @MainActor [weak self] in
                self?.interstitialAd = ad
                self?.interstitialAd?.fullScreenContentDelegate = self
                self?.isInterstitialReady = true
                print("AdMob: Interstitial loaded")
            }
        }
    }

    func canShowInterstitial() -> Bool {
        guard !StoreKitManager.shared.isPro else { return false }
        guard isInterstitialReady else { return false }
        guard interstitialCount < maxInterstitialsPerSession else { return false }
        if let lastTime = lastInterstitialTime {
            return Date().timeIntervalSince(lastTime) >= interstitialCooldown
        }
        return true
    }

    func showInterstitial(from viewController: UIViewController? = nil, completion: (() -> Void)? = nil) {
        guard canShowInterstitial() else {
            completion?()
            return
        }
        guard let rootVC = viewController ?? Self.topViewController() else {
            completion?()
            return
        }
        self.interstitialCompletion = completion
        interstitialAd?.present(from: rootVC)
        lastInterstitialTime = Date()
        interstitialCount += 1
    }

    // MARK: - Rewarded Ad
    func loadRewarded() {
        guard !StoreKitManager.shared.isPro else { return }
        let request = Request()
        RewardedAd.load(with: AdUnitID.rewarded, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                print("AdMob: Failed to load rewarded: \(error.localizedDescription)")
                Task { @MainActor [weak self] in self?.isRewardedReady = false }
                return
            }
            Task { @MainActor [weak self] in
                self?.rewardedAd = ad
                self?.rewardedAd?.fullScreenContentDelegate = self
                self?.isRewardedReady = true
                print("AdMob: Rewarded ad loaded")
            }
        }
    }

    func showRewarded(from viewController: UIViewController? = nil, completion: @escaping (Bool) -> Void) {
        guard isRewardedReady else {
            completion(false)
            return
        }
        guard let rootVC = viewController ?? Self.topViewController() else {
            completion(false)
            return
        }
        self.rewardCompletion = completion
        rewardedAd?.present(from: rootVC) {
            DispatchQueue.main.async {
                self.rewardCompletion?(true)
                self.rewardCompletion = nil
            }
        }
    }

    // MARK: - Native Ad
    func loadNativeAd() {
        guard !StoreKitManager.shared.isPro else { return }
        let options = MultipleAdsAdLoaderOptions()
        options.numberOfAds = 1

        nativeAdLoader = AdLoader(
            adUnitID: AdUnitID.native,
            rootViewController: Self.topViewController(),
            adTypes: [.native],
            options: [options]
        )
        nativeAdLoader?.delegate = self
        nativeAdLoader?.load(Request())
    }

    // MARK: - Helpers
    static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let base = base ?? UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
        if let nav = base as? UINavigationController { return topViewController(base: nav.visibleViewController) }
        if let tab = base as? UITabBarController { return topViewController(base: tab.selectedViewController) }
        if let presented = base?.presentedViewController { return topViewController(base: presented) }
        return base
    }
}

// MARK: - FullScreenContentDelegate
extension AdService: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        if ad is InterstitialAd {
            print("AdMob: Interstitial dismissed")
            Task { @MainActor in
                self.isInterstitialReady = false
                self.interstitialCompletion?()
                self.interstitialCompletion = nil
            }
            loadInterstitial()
        } else if ad is RewardedAd {
            print("AdMob: Rewarded dismissed")
            Task { @MainActor in self.isRewardedReady = false }
            loadRewarded()
        }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("AdMob: Failed to present ad: \(error.localizedDescription)")
        if ad is InterstitialAd {
            Task { @MainActor in
                self.isInterstitialReady = false
                self.interstitialCompletion?()
                self.interstitialCompletion = nil
            }
            loadInterstitial()
        } else if ad is RewardedAd {
            Task { @MainActor in
                self.rewardCompletion?(false)
                self.rewardCompletion = nil
                self.isRewardedReady = false
            }
            loadRewarded()
        }
    }
}

// MARK: - NativeAdLoaderDelegate
extension AdService: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        print("AdMob: Native ad loaded")
        Task { @MainActor in
            self.nativeAd = nativeAd
            self.isNativeAdReady = true
        }
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("AdMob: Failed to load native ad: \(error.localizedDescription)")
        Task { @MainActor in self.isNativeAdReady = false }
    }
}
