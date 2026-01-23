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
    let model: String
    let videoPath: String

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
        let model = environment["SORA_MODEL"] ??
            bundle.object(forInfoDictionaryKey: "SORA_MODEL") as? String ??
            "sora-1"
        let videoPath = environment["SORA_VIDEO_PATH"] ??
            bundle.object(forInfoDictionaryKey: "SORA_VIDEO_PATH") as? String ??
            "video/generations"

        return SoraAPIConfiguration(
            apiKey: apiKey,
            organization: organization,
            project: project,
            baseURL: baseURL,
            model: model,
            videoPath: videoPath
        )
    }
}

struct SoraVideoRequest: Encodable {
    let prompt: String
    let model: String
    let durationSeconds: Int
    let aspectRatio: String
    let resolution: String
    let inputImage: String?

    enum CodingKeys: String, CodingKey {
        case prompt
        case model
        case durationSeconds = "duration_seconds"
        case aspectRatio = "aspect_ratio"
        case resolution
        case inputImage = "input_image"
    }
}

private struct SoraVideoPayload: Decodable {
    let id: String?
    let status: SoraJobStatus?
    let downloadURL: URL?
    let thumbnailURL: URL?
    let eta: Int?
    let message: String?
    let output: [SoraVideoOutput]?
    let outputs: [SoraVideoOutput]?

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case downloadURL = "download_url"
        case thumbnailURL = "thumbnail_url"
        case eta
        case message
        case output
        case outputs
    }
}

private struct SoraVideoOutput: Decodable {
    let url: URL?
    let downloadURL: URL?
    let thumbnailURL: URL?
    let videoURL: URL?
    let imageURL: URL?
    let type: String?
    let kind: String?
    let role: String?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case url
        case downloadURL = "download_url"
        case thumbnailURL = "thumbnail_url"
        case videoURL = "video_url"
        case imageURL = "image_url"
        case type
        case kind
        case role
        case name
    }

    var resolvedURL: URL? {
        url ?? downloadURL ?? videoURL ?? imageURL ?? thumbnailURL
    }

    var normalizedType: String {
        (type ?? kind ?? role ?? name ?? "").lowercased()
    }
}

struct SoraVideoResponse: Decodable {
    let id: String
    let status: SoraJobStatus
    let downloadURL: URL?
    let thumbnailURL: URL?
    let eta: Int?
    let message: String?

    private enum RootKeys: String, CodingKey {
        case data
        case result
    }

    init(from decoder: Decoder) throws {
        if let payload = try? SoraVideoPayload(from: decoder), let id = payload.id {
            self = SoraVideoResponse.fromPayload(id: id, payload: payload)
            return
        }

        let root = try decoder.container(keyedBy: RootKeys.self)
        if let payload = try? root.decode(SoraVideoPayload.self, forKey: .data), let id = payload.id {
            self = SoraVideoResponse.fromPayload(id: id, payload: payload)
            return
        }

        if let payload = try? root.decode(SoraVideoPayload.self, forKey: .result), let id = payload.id {
            self = SoraVideoResponse.fromPayload(id: id, payload: payload)
            return
        }

        throw DecodingError.keyNotFound(
            SoraVideoPayload.CodingKeys.id,
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Missing Sora response ID.")
        )
    }

    private static func fromPayload(id: String, payload: SoraVideoPayload) -> SoraVideoResponse {
        let outputs = payload.output ?? payload.outputs
        let (videoURL, thumbnailURL) = extractOutputURLs(outputs)

        return SoraVideoResponse(
            id: id,
            status: payload.status ?? .unknown,
            downloadURL: payload.downloadURL ?? videoURL,
            thumbnailURL: payload.thumbnailURL ?? thumbnailURL,
            eta: payload.eta,
            message: payload.message
        )
    }

    private static func extractOutputURLs(_ outputs: [SoraVideoOutput]?) -> (URL?, URL?) {
        guard let outputs, !outputs.isEmpty else { return (nil, nil) }

        let videoOutput = outputs.first(where: { $0.normalizedType.contains("video") })
        let thumbnailOutput = outputs.first(where: { output in
            let type = output.normalizedType
            return type.contains("thumbnail") || type.contains("preview") || type.contains("image")
        })

        let fallback = outputs.first?.resolvedURL
        return (videoOutput?.resolvedURL ?? fallback, thumbnailOutput?.resolvedURL)
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
            model: configuration.model,
            durationSeconds: duration,
            aspectRatio: aspectRatio,
            resolution: resolution,
            inputImage: referenceImageData?.base64EncodedString()
        )

        var request = try makeRequest(path: configuration.videoPath, method: "POST")
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await session.data(for: request)
        return try decodeResponse(data: data, response: response)
    }

    func fetchVideoStatus(id: String) async throws -> SoraVideoResponse {
        let request = try makeRequest(path: "\(configuration.videoPath)/\(id)", method: "GET")
        let (data, response) = try await session.data(for: request)
        return try decodeResponse(data: data, response: response)
    }
    
    private func makeRequest(path: String, method: String) throws -> URLRequest {
        let trimmedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = configuration.baseURL.appendingPathComponent(trimmedPath)

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
