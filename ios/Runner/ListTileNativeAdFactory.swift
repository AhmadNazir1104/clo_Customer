import GoogleMobileAds
import UIKit

/// Native ad factory for the "listTile" factoryId.
/// Builds a programmatic GADNativeAdView styled to match
/// the app's Gun Metal (#2C3333) design language.
class ListTileNativeAdFactory: NSObject, FLTNativeAdFactory {

    func createNativeAd(
        _ nativeAd: GADNativeAd,
        customOptions: [AnyHashable: Any]? = nil
    ) -> GADNativeAdView? {

        let adView = GADNativeAdView()
        adView.backgroundColor = .white

        // ── Icon ─────────────────────────────────────────────────────────
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFill
        iconView.layer.cornerRadius = 8
        iconView.clipsToBounds = true
        iconView.translatesAutoresizingMaskIntoConstraints = false

        // ── Headline ─────────────────────────────────────────────────────
        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.boldSystemFont(ofSize: 14)
        headlineLabel.textColor = UIColor(red: 0.102, green: 0.125, blue: 0.125, alpha: 1)
        headlineLabel.numberOfLines = 1
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false

        // ── Body ─────────────────────────────────────────────────────────
        let bodyLabel = UILabel()
        bodyLabel.font = UIFont.systemFont(ofSize: 12)
        bodyLabel.textColor = UIColor(red: 0.478, green: 0.502, blue: 0.502, alpha: 1)
        bodyLabel.numberOfLines = 2
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false

        // ── CTA Button ───────────────────────────────────────────────────
        let ctaButton = UIButton(type: .system)
        ctaButton.backgroundColor = UIColor(red: 0.173, green: 0.2, blue: 0.2, alpha: 1)
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 11)
        ctaButton.layer.cornerRadius = 6
        ctaButton.isUserInteractionEnabled = false
        ctaButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false

        // ── Text stack ───────────────────────────────────────────────────
        let textStack = UIStackView(arrangedSubviews: [headlineLabel, bodyLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        adView.addSubview(iconView)
        adView.addSubview(textStack)
        adView.addSubview(ctaButton)

        NSLayoutConstraint.activate([
            // Icon: 40×40, leading
            iconView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),

            // CTA button: trailing, fixed width
            ctaButton.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            ctaButton.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
            ctaButton.heightAnchor.constraint(equalToConstant: 32),
            ctaButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 64),

            // Text stack: between icon and CTA
            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            textStack.trailingAnchor.constraint(equalTo: ctaButton.leadingAnchor, constant: -8),
            textStack.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
        ])

        // ── Populate data ────────────────────────────────────────────────
        iconView.image = nativeAd.icon?.image
        iconView.isHidden = nativeAd.icon == nil

        headlineLabel.text = nativeAd.headline

        bodyLabel.text = nativeAd.body
        bodyLabel.isHidden = nativeAd.body == nil

        ctaButton.setTitle(nativeAd.callToAction, for: .normal)
        ctaButton.isHidden = nativeAd.callToAction == nil

        // ── Wire up GADNativeAdView ───────────────────────────────────────
        adView.iconView        = iconView
        adView.headlineView    = headlineLabel
        adView.bodyView        = bodyLabel
        adView.callToActionView = ctaButton
        adView.nativeAd        = nativeAd

        return adView
    }
}
