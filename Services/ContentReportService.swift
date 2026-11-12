//
//  ContentReportService.swift
//  XVisionBoardAI
//
//  Sends a report about an AI-generated image to the ManifestMe proxy, which
//  stores it for review (see `handleReport` in proxy/src/index.js).
//
//  App Review asks generative-AI apps for a way to flag objectionable output.
//  Boards are private, so there is no other user to block. The report covers
//  the image itself. What leaves the device is the scene description, style
//  and reason. The selfie and the image pixels are never sent.
//

import Foundation

/// Why someone is reporting an image. The raw values are the exact strings the
/// proxy accepts (`REPORT_REASONS` in proxy/src/index.js). Keep the two in sync.
enum ContentReportReason: String, CaseIterable, Identifiable, Codable {
    case sexual
    case violent
    case hateful
    case notMe = "not_me"
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sexual:  return "Sexual or suggestive"
        case .violent: return "Violent or disturbing"
        case .hateful: return "Hateful or offensive"
        case .notMe:   return "Doesn’t look like me"
        case .other:   return "Something else"
        }
    }
}

struct ContentReport: Encodable {
    let reportId: UUID
    let imageId: UUID
    let reason: ContentReportReason
    let details: String
    let prompt: String
    let style: String
    let isPersonalized: Bool
    let appVersion: String
    let createdAt: Date
}

enum ContentReportError: LocalizedError {
    case notConfigured
    case server(status: Int)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Reporting isn't available in this build."
        case .server(let status):
            return "The report couldn't be delivered (HTTP \(status))."
        }
    }
}

enum ContentReportService {

    /// Matches the proxy's limit for the free-text field.
    static let maxDetailsLength = 500

    static var appVersion: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(short) (\(build))"
    }

    static func send(_ report: ContentReport) async throws {
        guard let base = APIConfig.proxyBaseURL else { throw ContentReportError.notConfigured }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(report)

        var request = URLRequest(url: base.appendingPathComponent("report"))
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in await AppAttestManager.shared.assertionHeaders(for: body) {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = body

        let (_, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(status) else { throw ContentReportError.server(status: status) }
    }
}
