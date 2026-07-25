import Foundation
import UIKit

// MARK: - fal.ai Image Generation Service
// Queue-based API: POST → poll status → fetch result
// Models (Gemini Nano Banana 2):
//   fal-ai/nano-banana-2       — text-to-image
//   fal-ai/nano-banana-2/edit  — face-consistent, takes selfie via image_urls

enum FalAIError: Error, LocalizedError {
    case missingAPIKey
    case requestFailed(String)
    case generationFailed(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:    return "fal.ai API key not configured"
        case .requestFailed(let msg): return "Request failed: \(msg)"
        case .generationFailed(let msg): return "Generation failed: \(msg)"
        case .timeout: return "Generation timed out"
        }
    }
}

struct FalAIService {

    // MARK: - Config

    private static let queueBase = "https://queue.fal.run"
    private static let nanoBanana2     = "fal-ai/nano-banana-2"
    private static let nanoBanana2Edit = "fal-ai/nano-banana-2/edit"

    static var apiKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "FAL_API_KEY") as? String
    }

    // MARK: - Public API

    /// Generate one image. Uses Nano Banana 2 edit when referenceImageData is provided, text-to-image otherwise.
    static func generateImage(
        prompt: String,
        referenceImageData: Data? = nil,
        imageSize: FalImageSize = .squareHD
    ) async throws -> String {
        guard let key = apiKey, !key.isEmpty else {
            throw FalAIError.missingAPIKey
        }

        if let refData = referenceImageData {
            return try await generateWithFace(
                prompt: prompt,
                referenceData: refData,
                imageSize: imageSize,
                apiKey: key
            )
        } else {
            return try await generateTextToImage(
                prompt: prompt,
                imageSize: imageSize,
                apiKey: key
            )
        }
    }

    // MARK: - Nano Banana 2 text-to-image (no face)

    private static func generateTextToImage(
        prompt: String,
        imageSize: FalImageSize,
        apiKey: String
    ) async throws -> String {
        let body: [String: Any] = [
            "prompt": prompt,
            "aspect_ratio": imageSize.aspectRatio,
            "num_images": 1
        ]
        return try await submitAndPoll(model: nanoBanana2, body: body, apiKey: apiKey)
    }

    // MARK: - Nano Banana 2 edit (face-consistent)

    private static func generateWithFace(
        prompt: String,
        referenceData: Data,
        imageSize: FalImageSize,
        apiKey: String
    ) async throws -> String {
        let base64 = referenceData.base64EncodedString()
        let dataURI = "data:image/jpeg;base64,\(base64)"

        let body: [String: Any] = [
            "prompt": prompt,
            "image_urls": [dataURI],
            "aspect_ratio": imageSize.aspectRatio,
            "num_images": 1
        ]
        // Edit falls back to text-to-image on non-cancellation errors only
        do {
            return try await submitAndPoll(model: nanoBanana2Edit, body: body, apiKey: apiKey)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return try await generateTextToImage(prompt: prompt, imageSize: imageSize, apiKey: apiKey)
        }
    }

    // MARK: - Queue Submit + Poll

    private static func submitAndPoll(
        model: String,
        body: [String: Any],
        apiKey: String
    ) async throws -> String {
        // 1. Submit to queue
        let submitURL = URL(string: "\(queueBase)/\(model)")!
        var req = URLRequest(url: submitURL)
        req.httpMethod = "POST"
        req.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (submitData, submitResponse) = try await URLSession.shared.data(for: req)

        guard let http = submitResponse as? HTTPURLResponse,
              http.statusCode == 200 || http.statusCode == 202 else {
            let msg = String(data: submitData, encoding: .utf8) ?? "unknown"
            throw FalAIError.requestFailed(msg)
        }

        guard let submitJSON = try? JSONSerialization.jsonObject(with: submitData) as? [String: Any],
              let requestID = submitJSON["request_id"] as? String else {
            throw FalAIError.requestFailed("No request_id in response")
        }

        // Prefer status_url/response_url from submit response over manual construction
        let statusURL: URL
        let resultURL: URL
        if let statusStr = submitJSON["status_url"] as? String, let parsedStatus = URL(string: statusStr),
           let responseStr = submitJSON["response_url"] as? String, let parsedResult = URL(string: responseStr) {
            statusURL = parsedStatus
            resultURL = parsedResult
        } else {
            statusURL = URL(string: "\(queueBase)/\(model)/requests/\(requestID)/status")!
            resultURL = URL(string: "\(queueBase)/\(model)/requests/\(requestID)")!
        }
        let cancelURLString = submitJSON["cancel_url"] as? String

        do {
            return try await poll(statusURL: statusURL, resultURL: resultURL, apiKey: apiKey)
        } catch {
            // If our Task was cancelled, tell fal.ai to stop the queued job too —
            // otherwise it runs to completion server-side and still bills.
            let wasCancelled = error is CancellationError || (error as? URLError)?.code == .cancelled
            if wasCancelled, let str = cancelURLString, let cancelURL = URL(string: str) {
                var cancelReq = URLRequest(url: cancelURL)
                cancelReq.httpMethod = "PUT"
                cancelReq.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
                // Detached: the current task is already cancelled and can't await
                Task.detached { _ = try? await URLSession.shared.data(for: cancelReq) }
            }
            throw error
        }
    }

    private static func poll(
        statusURL: URL,
        resultURL: URL,
        apiKey: String
    ) async throws -> String {
        for attempt in 0..<60 {
            let delay: UInt64 = attempt < 5 ? 2_000_000_000 : 3_000_000_000
            try await Task.sleep(nanoseconds: delay)

            var statusReq = URLRequest(url: statusURL)
            statusReq.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
            guard let (statusData, _) = try? await URLSession.shared.data(for: statusReq),
                  let statusJSON = try? JSONSerialization.jsonObject(with: statusData) as? [String: Any],
                  let status = statusJSON["status"] as? String else {
                continue
            }

            switch status {
            case "COMPLETED":
                break
            case "FAILED":
                let detail = (statusJSON["error"] as? String) ?? "unknown error"
                throw FalAIError.generationFailed(detail)
            default:
                continue  // IN_QUEUE, IN_PROGRESS
            }

            // 3. Fetch result
            var resultReq = URLRequest(url: resultURL)
            resultReq.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
            let (resultData, _) = try await URLSession.shared.data(for: resultReq)

            guard let resultJSON = try? JSONSerialization.jsonObject(with: resultData) as? [String: Any],
                  let images = resultJSON["images"] as? [[String: Any]],
                  let firstImage = images.first,
                  let imageURL = firstImage["url"] as? String else {
                throw FalAIError.requestFailed("No image URL in result")
            }
            return imageURL
        }
        throw FalAIError.timeout
    }
}

// MARK: - Image Size

enum FalImageSize: String {
    case squareHD        = "square_hd"         // 1024×1024
    case square          = "square"             // 512×512
    case portrait43      = "portrait_4_3"       // 768×1024
    case portrait169     = "portrait_16_9"      // 576×1024
    case landscape43     = "landscape_4_3"      // 1024×768
    case landscape169    = "landscape_16_9"     // 1024×576

    /// Nano Banana 2 takes aspect_ratio strings rather than named sizes.
    var aspectRatio: String {
        switch self {
        case .squareHD, .square: return "1:1"
        case .portrait43:        return "3:4"
        case .portrait169:       return "9:16"
        case .landscape43:       return "4:3"
        case .landscape169:      return "16:9"
        }
    }

    static func forLayout(_ layout: VisionBoardLayout) -> FalImageSize {
        switch layout {
        case .grid3x3: return .squareHD
        case .collage:  return .landscape43
        case .singlePoster: return .portrait43
        }
    }
}
