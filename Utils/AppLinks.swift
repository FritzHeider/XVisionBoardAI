import Foundation

/// Centralized external links and contact info.
///
/// ⚠️ SUBMISSION BLOCKERS: the two TODO values below must be real before App
/// Store review. The paywall requires a working Privacy Policy link, and the
/// support email is shown on the paywall and the Forgot Password flow.
enum AppLinks {

    // MARK: - Legal

    /// Apple's standard EULA — valid to use as-is unless you host a custom one.
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    // TODO(manifestme): Host a privacy policy (GitHub Pages / Termly / iubenda)
    // and replace this URL before submitting to the App Store.
    static let privacyPolicy = URL(string: "https://example.com/manifestme/privacy")!

    // MARK: - Contact

    // TODO(manifestme): Replace with a real support inbox before submission.
    static let supportEmail = "support@example.com"

    /// `true` while the placeholders above are still unset — used to hide/guard
    /// UI that would otherwise point users at a dead link in the meantime.
    static var legalLinksConfigured: Bool {
        !privacyPolicy.absoluteString.contains("example.com") &&
        !supportEmail.contains("example.com")
    }
}
