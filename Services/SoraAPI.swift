//
//  SoraAPI.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import Foundation

struct SoraAPIConfiguration {
    let apiKey: String
    let organization: String?
    let project: String?
    let baseURL: URL

    static func fromEnvironment(bundle: Bundle = .main) -> SoraAPIConfiguration? {
        let environment = ProcessInfo.processInfo.environment

        let apiKey = environment["SORA_API_KEY"] ?? bundle.object(forInfoDictionaryKey: "SORA_API_KEY") as? String
        guard let apiKey else { return nil }

        let baseURLString = environment["SORA_BASE_URL"] ??
            bundle.object(forInfoDictionaryKey: "SORA_BASE_URL") as? String ??
            "https://api.openai.com/v1"

        guard let baseURL = URL(string: baseURLString) else { return nil }

        let organization = environment["SORA_ORG_ID"] ?? bundle.object(forInfoDictionaryKey: "SORA_ORG_ID") as? String
        let project = environment["SORA_PROJECT_ID"] ?? bundle.object(forInfoDictionaryKey: "SORA_PROJECT_ID") as? String

        return SoraAPIConfiguration(
            apiKey: apiKey,
            organization: organization,
            project: project,
            baseURL: baseURL
        )
    }
}

struct SoraVideoRequest: Encodable {
    let prompt: String
    let model: String
    let duration: Int
    let aspectRatio: String
    let resolution: String
    let referenceImage: String?

    enum CodingKeys: String, CodingKey {
        case prompt
        case model
        case duration
        case aspectRatio = "aspect_ratio"
        case resolution
        case referenceImage = "reference_image"
    }
}

struct SoraVideoResponse: Decodable {
    let id: String
    let status: SoraJobStatus
    let downloadURL: URL?
    let thumbnailURL: URL?
    let eta: Int?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case downloadURL = "download_url"
        case thumbnailURL = "thumbnail_url"
        case eta
        case message
    }
}

struct SoraAPIErrorResponse: Decodable {
    struct APIError: Decodable {
        let message: String
    }

    let error: APIError?
}

enum SoraAPIError: LocalizedError {
    case missingConfiguration
    case invalidURL
    case invalidResponse
    case server(String)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Sora API is not configured."
        case .invalidURL:
            return "The Sora API URL is invalid."
        case .invalidResponse:
            return "The Sora API returned an unexpected response."
        case .server(let message):
            return message
        case .decoding(let error):
            return "Failed to decode Sora response: \(error.localizedDescription)"
        }
    }
}

final class SoraAPIClient {
    private let configuration: SoraAPIConfiguration
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init?(configuration: SoraAPIConfiguration?) {
        guard let configuration else { return nil }
        self.configuration = configuration
        self.session = URLSession(configuration: .default)
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func generateVideo(
        prompt: String,
        duration: Int = 10,
        aspectRatio: String = "16:9",
        resolution: String = "1280x720",
        referenceImageData: Data?
    ) async throws -> SoraVideoResponse {
        let requestBody = SoraVideoRequest(
            prompt: prompt,
            model: "sora-1.1",
            duration: duration,
            aspectRatio: aspectRatio,
            resolution: resolution,
            referenceImage: referenceImageData?.base64EncodedString()
        )

        var request = try makeRequest(path: "videos", method: "POST")
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await session.data(for: request)
        return try decodeResponse(data: data, response: response)
    }

    func fetchVideoStatus(id: String) async throws -> SoraVideoResponse {
        let request = try makeRequest(path: "videos/\(id)", method: "GET")
        let (data, response) = try await session.data(for: request)
        return try decodeResponse(data: data, response: response)
    }
    
    private func makeRequest(path: String, method: String) throws -> URLRequest {
        let url = configuration.baseURL.appendingPathComponent(path)

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")

        if let organization = configuration.organization {
            request.setValue(organization, forHTTPHeaderField: "OpenAI-Organization")
        }

        if let project = configuration.project {
            request.setValue(project, forHTTPHeaderField: "OpenAI-Project")
        }

        return request
    }

    private func decodeResponse<T: Decodable>(data: Data, response: URLResponse) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SoraAPIError.invalidResponse
        }

        if !(200...299).contains(httpResponse.statusCode) {
            if let errorResponse = try? decoder.decode(SoraAPIErrorResponse.self, from: data),
               let message = errorResponse.error?.message {
                throw SoraAPIError.server(message)
            }
            throw SoraAPIError.invalidResponse
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw SoraAPIError.decoding(error)
        }
    }
}
