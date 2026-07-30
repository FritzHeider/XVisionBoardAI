import Foundation

/// Centralized external links and contact info.
///
/// Every URL here is user-reachable from inside the app and is checked by App
/// Review: the privacy policy and terms are linked from both the paywall and
/// Profile → Legal, and the support address backs Profile → Contact Support and
/// the Forgot Password flow. If any of these stops resolving, that is a
/// Guideline 5.1.1(i) / 2.1 finding — verify them before each submission.
enum AppLinks {

    // MARK: - Legal

    /// Apple's standard EULA — valid to use as-is unless you host a custom one.
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    // Served from docs/privacy-policy.html via GitHub Pages on the custom domain
    // manifestme.fritzthatcat.com (see docs/CNAME + Cloudflare DNS).
    static let privacyPolicy = URL(string: "https://manifestme.fritzthatcat.com/privacy-policy.html")!

    // MARK: - Marketing

    /// Doubles as the App Store Connect Support/Marketing URL and the payload
    /// for Profile → Share App. Replace with the App Store product URL once the
    /// app is live if you'd rather share the listing directly.
    static let marketingSite = URL(string: "https://manifestme.fritzthatcat.com/")!

    // MARK: - Contact

    static let supportEmail = "support@fritzthatcat.com"

    /// Pre-addressed support mail, subject included so inbound mail is
    /// attributable to the app rather than arriving blank.
    static var supportMailto: URL {
        var comps = URLComponents()
        comps.scheme = "mailto"
        comps.path = supportEmail
        comps.queryItems = [URLQueryItem(name: "subject", value: "ManifestMe Support")]
        return comps.url ?? URL(string: "mailto:\(supportEmail)")!
    }
}
