import SwiftUI
import GoogleMobileAds

struct NativeAdCardView: View {
    @ObservedObject var adService = AdService.shared

    var body: some View {
        Group {
            if let nativeAd = adService.nativeAd, !StoreKitManager.shared.isPro {
                NativeAdRepresentable(nativeAd: nativeAd)
                    .frame(height: 120)
                    .overlay(
                        Text("Ad")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.9))
                            .cornerRadius(4)
                            .padding(8),
                        alignment: .topLeading
                    )
                    .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterial))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.indigo.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            }
        }
    }
}

struct NativeAdRepresentable: UIViewRepresentable {
    let nativeAd: NativeAd

    func makeUIView(context: Context) -> NativeAdView {
        let nativeAdView = NativeAdView()
        nativeAdView.backgroundColor = .clear

        // Headline
        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        headlineLabel.textColor = .label
        headlineLabel.numberOfLines = 2
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(headlineLabel)
        nativeAdView.headlineView = headlineLabel

        // Icon
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 8
        iconView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(iconView)
        nativeAdView.iconView = iconView

        // Body
        let bodyLabel = UILabel()
        bodyLabel.font = UIFont.systemFont(ofSize: 12)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(bodyLabel)
        nativeAdView.bodyView = bodyLabel

        // CTA Button
        var config = UIButton.Configuration.filled()
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemIndigo
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            return outgoing
        }
        let ctaButton = UIButton(configuration: config)
        ctaButton.layer.cornerRadius = 8
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(ctaButton)
        nativeAdView.callToActionView = ctaButton

        // Layout
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: nativeAdView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48),

            headlineLabel.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 20),
            headlineLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            headlineLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -16),

            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
            bodyLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: ctaButton.leadingAnchor, constant: -8),

            ctaButton.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -16),
            ctaButton.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor, constant: -16),
        ])

        return nativeAdView
    }

    func updateUIView(_ nativeAdView: NativeAdView, context: Context) {
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView.callToActionView?.isUserInteractionEnabled = false
        nativeAdView.nativeAd = nativeAd
    }
}
