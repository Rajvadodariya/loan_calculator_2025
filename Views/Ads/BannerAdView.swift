import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    init(adUnitID: String = AdUnitID.banner) {
        self.adUnitID = adUnitID
    }

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: adSizeFor(cgSize: CGSize(width: 320, height: 50)))
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = AdService.topViewController()
        bannerView.delegate = context.coordinator
        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("AdMob: Banner loaded")
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("AdMob: Banner failed: \(error.localizedDescription)")
        }
    }
}
