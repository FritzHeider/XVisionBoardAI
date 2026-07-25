import Foundation

/// Central switch between calling AI providers directly (keys in the app, the
/// interim state) and routing through the ManifestMe proxy (keys server-side).
///
/// While `proxyBaseURL` is nil, every service uses its direct client-key path so
/// the app keeps working for TestFlight. Once you deploy `proxy/` and set this to
/// the Worker URL, services route through it and attach an App Attest assertion —
/// at which point you should remove the `$(…)_API_KEY` entries from Info.plist and
/// rotate the old keys.
enum APIConfig {

    // TODO(manifestme): set to your deployed Worker URL, e.g.
    // URL(string: "https://manifestme-proxy.<subdomain>.workers.dev")
    static let proxyBaseURL: URL? = URL(string: "https://manifestme-proxy.blueloke.workers.dev")
    static var usesProxy: Bool { proxyBaseURL != nil }

    /// Builds the request URL for a provider path: proxied when configured,
    /// otherwise the provider's direct URL.
    /// - provider: the proxy route segment ("fal", "gemini").
    /// - directURL: the URL to use when the proxy is not configured.
    /// - proxyPath: the path appended after `/<provider>/` on the proxy.
    static func url(provider: String, directURL: URL, proxyPath: String, query: String? = nil) -> URL {
        guard let base = proxyBaseURL else { return directURL }
        var url = base.appendingPathComponent(provider).appendingPathComponent(proxyPath)
        if let query, !query.isEmpty {
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
            comps?.query = query
            if let composed = comps?.url { url = composed }
        }
        return url
    }
}
