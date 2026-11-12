//
//  ContentReportTests.swift
//  XVisionBoardAITests
//
//  Locks in the image-reporting path added for App Review (generated content
//  needs a report mechanism). The case that matters most is
//  `legacyImageDecodesUnreported`. Boards saved before `reportedAt` existed
//  must load as visible. A decode failure there would drop people's boards.
//

import Foundation
import Testing
@testable import XVisionBoardAI

@Suite("Reporting an AI image")
struct ContentReportTests {

    @Test("An image saved before reporting existed loads as not reported")
    func legacyImageDecodesUnreported() throws {
        let legacy = """
        {"id":"7C3A1E2B-4D5F-4A6B-8C9D-0E1F2A3B4C5D","prompt":"Sunrise over the ocean",
         "isPersonalized":true,"position":0,"aspectRatio":1.0}
        """.data(using: .utf8)!
        let image = try JSONDecoder().decode(VisionBoardImage.self, from: legacy)
        #expect(image.reportedAt == nil)
        #expect(image.isReported == false)
    }

    @Test("The reported flag survives a save and reload")
    func reportedRoundTrips() throws {
        var image = VisionBoardImage(prompt: "Corner office", position: 1)
        image.reportedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let data = try JSONEncoder().encode(image)
        let decoded = try JSONDecoder().decode(VisionBoardImage.self, from: data)
        #expect(decoded.reportedAt == image.reportedAt)
        #expect(decoded.isReported)
    }

    @Test("Reported images are left out of what the board shows and exports")
    func visibleImagesExcludeReported() {
        var board = VisionBoard.sampleVisionBoard
        var hidden = VisionBoardImage(prompt: "Hidden scene", position: 1)
        hidden.reportedAt = .now
        board.images.append(hidden)

        #expect(board.images.contains { $0.id == hidden.id })
        #expect(!board.visibleImages.contains { $0.id == hidden.id })
        #expect(board.visibleImages.count == board.images.count - 1)
    }

    @Test("Reason codes match the ones the proxy accepts")
    func reasonCodesMatchProxy() {
        // Mirror of REPORT_REASONS in proxy/src/index.js. A mismatch makes the
        // proxy reject every report of that kind with a 400.
        let proxyAccepted: Set<String> = ["sexual", "violent", "hateful", "not_me", "other"]
        #expect(Set(ContentReportReason.allCases.map(\.rawValue)) == proxyAccepted)
    }

    @Test("The report payload never carries image bytes or the selfie")
    func payloadHasNoImageData() throws {
        let report = ContentReport(
            reportId: UUID(), imageId: UUID(), reason: .notMe, details: "Wrong face",
            prompt: "Beach house", style: "cinematic", isPersonalized: true,
            appVersion: "1.0 (1)", createdAt: .now
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let json = try #require(
            try JSONSerialization.jsonObject(with: encoder.encode(report)) as? [String: Any]
        )
        #expect(Set(json.keys) == [
            "reportId", "imageId", "reason", "details", "prompt",
            "style", "isPersonalized", "appVersion", "createdAt",
        ])
        #expect(json["reason"] as? String == "not_me")
    }
}
