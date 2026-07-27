import Foundation
import DeviceCheck
import CryptoKit

/// App Attest client. Proves to the proxy that a request comes from a genuine,
/// unmodified ManifestMe on real Apple hardware, so a leaked proxy URL can't be
/// driven from a fake client.
///
/// This is only meaningful once `APIConfig.proxyBaseURL` is set AND the proxy's
/// server-side attestation validation is completed (see `proxy/src/index.js`).
/// `DCAppAttestService` is unsupported in the Simulator, so `isSupported` guards
/// every call and the manager degrades to a no-op there (requests still succeed;
/// they're just treated as lower-trust by the server).
actor AppAttestManager {
    static let shared = AppAttestManager()

    private let service = DCAppAttestService.shared
    private let keyIdAccount = "appAttestKeyId"
    private var cachedKeyId: String?

    private var storedKeyId: String? {
        if let cachedKeyId { return cachedKeyId }
        if let data = KeychainStore.load(account: keyIdAccount) {
            cachedKeyId = String(data: data, encoding: .utf8)
        }
        return cachedKeyId
    }

    /// Ensures a device key exists and has been attested with the proxy. Safe to
    /// call repeatedly; the network round-trip only happens once per install.
    func prepare() async {
        guard service.isSupported, APIConfig.usesProxy else { return }
        guard storedKeyId == nil else { return }
        do {
            let keyId = try await service.generateKey()
            try await attest(keyId: keyId)
            KeychainStore.save(Data(keyId.utf8), account: keyIdAccount)
            cachedKeyId = keyId
        } catch {
            print("[AppAttest] prepare failed: \(error.localizedDescription)")
        }
    }

    /// Headers to attach to a proxied request, asserting over `body`. Empty when
    /// unsupported/unconfigured so callers can attach unconditionally.
    func assertionHeaders(for body: Data) async -> [String: String] {
        guard service.isSupported, APIConfig.usesProxy, let keyId = storedKeyId else { return [:] }
        do {
            let hash = Data(SHA256.hash(data: body))
            let assertion = try await service.generateAssertion(keyId, clientDataHash: hash)
            return [
                "X-Attest-Key-Id": keyId,
                "X-Attest-Assertion": assertion.base64EncodedString()
            ]
        } catch {
            print("[AppAttest] assertion failed: \(error.localizedDescription)")
            return [:]
        }
    }

    // MARK: - Attestation (once per key)

    private func attest(keyId: String) async throws {
        guard let base = APIConfig.proxyBaseURL else { return }

        // 1. One-time challenge from the proxy.
        var challengeReq = URLRequest(url: base.appendingPathComponent("attest/challenge"))
        challengeReq.httpMethod = "POST"
        challengeReq.timeoutInterval = 30
        let (cData, cResp) = try await URLSession.shared.data(for: challengeReq)
        try Self.ensureSuccess(cResp, body: cData, step: "challenge")
        guard let cJSON = try? JSONSerialization.jsonObject(with: cData) as? [String: Any],
              let challenge = cJSON["challenge"] as? String,
              let challengeData = Data(base64Encoded: challenge) else {
            throw AppAttestError.badChallenge
        }

        // 2. Attest the key against Apple, then register with the proxy.
        let hash = Data(SHA256.hash(data: challengeData))
        let attestation = try await service.attestKey(keyId, clientDataHash: hash)

        var verifyReq = URLRequest(url: base.appendingPathComponent("attest/verify"))
        verifyReq.httpMethod = "POST"
        verifyReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        verifyReq.timeoutInterval = 30
        verifyReq.httpBody = try JSONSerialization.data(withJSONObject: [
            "keyId": keyId,
            "attestation": attestation.base64EncodedString(),
            "challenge": challenge
        ])
        // Must throw on a rejected attestation. If this is ignored, prepare()
        // still persists keyId to the Keychain and its `storedKeyId == nil` guard
        // means the device never re-attests — every later request then carries an
        // assertion the proxy never validated, surfacing as opaque 401s elsewhere.
        let (vData, vResp) = try await URLSession.shared.data(for: verifyReq)
        try Self.ensureSuccess(vResp, body: vData, step: "verify")
    }

    /// Throws unless the response carries a 2xx status.
    private static func ensureSuccess(_ response: URLResponse, body: Data, step: String) throws {
        guard let http = response as? HTTPURLResponse else {
            throw AppAttestError.verificationFailed(step: step, status: -1, body: "non-HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw AppAttestError.verificationFailed(
                step: step,
                status: http.statusCode,
                body: String(data: body, encoding: .utf8) ?? "<unreadable>"
            )
        }
    }

    enum AppAttestError: Error {
        case badChallenge
        case verificationFailed(step: String, status: Int, body: String)
    }
}
