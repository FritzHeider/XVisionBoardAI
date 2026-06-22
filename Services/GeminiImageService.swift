import Foundation

enum GeminiImageError: Error, LocalizedError {
    case missingAPIKey
    case requestFailed(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:          return "Gemini API key not configured"
        case .requestFailed(let msg): return "Gemini request failed: \(msg)"
        case .invalidResponse:        return "Invalid response from Gemini"
        }
    }
}

struct GeminiImageService {

    private static let imagenModel = "imagen-3.0-generate-001"
    private static let flashModel  = "gemini-2.0-flash-preview-image-generation"
    private static let baseURL     = "https://generativelanguage.googleapis.com/v1beta/models"

    static var apiKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String
    }

    // MARK: - Personalized generation (Gemini 2.0 Flash)

    /// Generates an image of the person from the selfie placed in the described scene.
    /// Uses Gemini 2.0 Flash which understands image references and generates images.
    static func generatePersonalizedImage(
        prompt: String,
        selfieData: Data,
        aspectRatio: String = "1:1"
    ) async throws -> Data {
        guard let key = apiKey, !key.isEmpty else {
            throw GeminiImageError.missingAPIKey
        }

        let endpoint = "\(baseURL)/\(flashModel):generateContent?key=\(key)"
        guard let url = URL(string: endpoint) else {
            throw GeminiImageError.requestFailed("Invalid endpoint URL")
        }

        let base64Selfie = selfieData.base64EncodedString()

        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    [
                        "inlineData": [
                            "mimeType": "image/jpeg",
                            "data": base64Selfie
                        ]
                    ],
                    [
                        "text": prompt
                    ]
                ]
            ]],
            "generationConfig": [
                "responseModalities": ["TEXT", "IMAGE"]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8)
                ?? "status \((response as? HTTPURLResponse)?.statusCode ?? -1)"
            throw GeminiImageError.requestFailed(msg)
        }

        // Parse generateContent response: candidates[0].content.parts[*].inlineData
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let imagePart = parts.first(where: { ($0["inlineData"] as? [String: Any]) != nil }),
              let inlineData = imagePart["inlineData"] as? [String: Any],
              let base64 = inlineData["data"] as? String,
              let imageData = Data(base64Encoded: base64) else {
            throw GeminiImageError.invalidResponse
        }

        return imageData
    }

    // MARK: - Text-to-image (Imagen 3 fallback)

    /// Generates an image from a text prompt only (no face reference).
    static func generateImage(
        prompt: String,
        aspectRatio: String = "1:1"
    ) async throws -> Data {
        guard let key = apiKey, !key.isEmpty else {
            throw GeminiImageError.missingAPIKey
        }

        let endpoint = "\(baseURL)/\(imagenModel):predict?key=\(key)"
        let url = URL(string: endpoint)!

        let body: [String: Any] = [
            "instances": [["prompt": prompt]],
            "parameters": [
                "sampleCount": 1,
                "aspectRatio": aspectRatio
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8)
                ?? "status \((response as? HTTPURLResponse)?.statusCode ?? -1)"
            throw GeminiImageError.requestFailed(msg)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let predictions = json["predictions"] as? [[String: Any]],
              let first = predictions.first,
              let base64 = first["bytesBase64Encoded"] as? String,
              let imageData = Data(base64Encoded: base64) else {
            throw GeminiImageError.invalidResponse
        }

        return imageData
    }

    // MARK: - Helpers

    static func aspectRatio(for layout: VisionBoardLayout) -> String {
        switch layout {
        case .grid3x3:      return "1:1"
        case .collage:      return "4:3"
        case .singlePoster: return "3:4"
        }
    }
}
