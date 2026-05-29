import Foundation
import UIKit

// MARK: - fal.ai Image Generation Service
// Queue-based API: POST → poll status → fetch result
// Models:
//   fal-ai/flux/schnell  — fast (4 steps, ~3s), no face reference
//   fal-ai/pulid         — face-consistent (FLUX + PuLID), uses selfie reference

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
    private static let fluxSchnell = "fal-ai/flux/schnell"
    private static let fluxDev     = "fal-ai/flux/dev"
    private static let pulidModel  = "fal-ai/pulid"

    static var apiKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "FAL_API_KEY") as? String
    }

    // MARK: - Public API

    /// Generate one image. Uses PuLID when referenceImageData is provided, FLUX Schnell otherwise.
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
            return try await generateFluxSchnell(
                prompt: prompt,
                imageSize: imageSize,
                apiKey: key
            )
        }
    }

    // MARK: - FLUX Schnell (no face)

    private static func generateFluxSchnell(
        prompt: String,
        imageSize: FalImageSize,
        apiKey: String
    ) async throws -> String {
        let body: [String: Any] = [
            "prompt": prompt,
            "image_size": imageSize.rawValue,
            "num_inference_steps": 4,
            "num_images": 1,
            "enable_safety_checker": false
        ]
        return try await submitAndPoll(model: fluxSchnell, body: body, apiKey: apiKey)
    }

    // MARK: - PuLID (face-consistent)

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
            "reference_images": [["image_url": dataURI]],
            "image_size": imageSize.rawValue,
            "num_inference_steps": 20,
            "guidance_scale": 7.5,
            "num_images": 1,
            "true_cfg": 1.0,
            "id_weight": 0.85,
            "enable_safety_checker": false
        ]
        // PuLID falls back to flux/schnell if unavailable
        do {
            return try await submitAndPoll(model: pulidModel, body: body, apiKey: apiKey)
        } catch {
            return try await generateFluxSchnell(prompt: prompt, imageSize: imageSize, apiKey: apiKey)
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

        guard let http = submitResponse as? HTTPURLResponse, http.statusCode == 200 else {
            let msg = String(data: submitData, encoding: .utf8) ?? "unknown"
            throw FalAIError.requestFailed(msg)
        }

        guard let submitJSON = try? JSONSerialization.jsonObject(with: submitData) as? [String: Any],
              let requestID = submitJSON["request_id"] as? String else {
            throw FalAIError.requestFailed("No request_id in response")
        }

        // 2. Poll status
        let statusURL = URL(string: "\(queueBase)/\(model)/requests/\(requestID)/status")!
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
            let resultURL = URL(string: "\(queueBase)/\(model)/requests/\(requestID)")!
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

    static func forLayout(_ layout: VisionBoardLayout) -> FalImageSize {
        switch layout {
        case .grid3x3: return .squareHD
        case .collage:  return .landscape43
        case .singlePoster: return .portrait43
        }
    }
}
