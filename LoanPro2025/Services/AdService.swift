import Foundation
import UIKit

class AdService: ObservableObject {
    static let shared = AdService()
    
    @Published var isAdReady: Bool = false
    
    func loadInterstitial() {
        print("AdMob: Loading Interstitial...")
    }
    
    func showInterstitial() {
        print("AdMob: Showing Interstitial...")
    }
}
