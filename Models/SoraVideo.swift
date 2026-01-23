//
//  SoraVideo.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import Foundation

enum SoraJobStatus: String, Codable {
    case queued
    case processing
    case succeeded
    case failed
    case canceled
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self).lowercased()
        switch value {
        case "queued", "pending":
            self = .queued
        case "processing", "running", "in_progress":
            self = .processing
        case "succeeded", "completed", "success":
            self = .succeeded
        case "failed", "error":
            self = .failed
        case "canceled", "cancelled":
            self = .canceled
        default:
            self = .unknown
        }
    }
}

struct SoraVideoAsset: Codable {
    let jobId: String
    var status: SoraJobStatus
    var downloadURL: String?
    var thumbnailURL: String?
    var prompt: String
    var createdAt: Date
    var lastUpdated: Date

    init(
        jobId: String,
        status: SoraJobStatus,
        downloadURL: String? = nil,
        thumbnailURL: String? = nil,
        prompt: String,
        createdAt: Date = Date(),
        lastUpdated: Date = Date()
    ) {
        self.jobId = jobId
        self.status = status
        self.downloadURL = downloadURL
        self.thumbnailURL = thumbnailURL
        self.prompt = prompt
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
    }

    var isReady: Bool {
        status == .succeeded && downloadURL != nil
    }

    var isInProgress: Bool {
        status == .queued || status == .processing
    }
}
