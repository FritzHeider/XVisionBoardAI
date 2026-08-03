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

    /// Generate one image. Uses Nano Banana 2 edit when referenceImageData is
    /// provided, text-to-image otherwise.
    ///
    /// When a reference photo is supplied it is never optional: a failing edit
    /// throws rather than quietly producing a text-to-image result. A generic
    /// stranger's face in a board the user built from their own selfie is worse
    /// than an empty tile with a Retry button, and it looks like the upload was
    /// ignored — which is exactly how the silent fallback presented in practice.
    static func generateImage(
        prompt: String,
        referenceImageData: Data? = nil,
        imageSize: FalImageSize = .squareHD
    ) async throws -> String {
        // In proxy mode the key lives server-side; only the direct path needs it.
        let key = apiKey ?? ""
        if !APIConfig.usesProxy, key.isEmpty {
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
        // No text-to-image fallback: the caller asked for this face. Retry the
        // edit endpoint a couple of times to ride out transient queue/network
        // failures, then surface the error so the tile shows Retry.
        var lastError: Error?
        for attempt in 0..<3 {
            if attempt > 0 {
                try await Task.sleep(nanoseconds: UInt64(attempt) * 2_000_000_000)
            }
            do {
                return try await submitAndPoll(model: nanoBanana2Edit, body: body, apiKey: apiKey)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = error
                print("[FalAIService] face-consistent edit attempt \(attempt + 1)/3 failed: \(error)")
            }
        }
        throw FalAIError.generationFailed(
            "Couldn't generate this image from your photo. \(lastError?.localizedDescription ?? "Please try again.")"
        )
    }

    // MARK: - Queue Submit + Poll

    /// fal's queue *submit* route is the full model path ("fal-ai/nano-banana-2/edit"),
    /// but status/result/cancel live only under the base app id. Polling
    /// ".../nano-banana-2/edit/requests/<id>/status" returns HTTP 405, not JSON —
    /// which `poll` reads as "no status yet" and retries until it times out, after
    /// which the selfie path falls back to text-to-image and the user's photo is
    /// silently dropped. Strip the sub-path before building any polling URL.
    private static func queueAppID(for model: String) -> String {
        let parts = model.split(separator: "/")
        guard parts.count > 2 else { return model }
        return parts.prefix(2).joined(separator: "/")
    }

    private static func submitAndPoll(
        model: String,
        body: [String: Any],
        apiKey: String
    ) async throws -> String {
        // 1. Submit to queue.
        // When the proxy is configured, route through it (key injected server-side)
        // and attach an App Attest assertion; otherwise call fal.ai directly.
        let directSubmit = URL(string: "\(queueBase)/\(model)")!
        let submitURL = APIConfig.url(provider: "fal", directURL: directSubmit, proxyPath: model)
        var req = URLRequest(url: submitURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let httpBody = try JSONSerialization.data(withJSONObject: body)
        req.httpBody = httpBody
        if APIConfig.usesProxy {
            for (k, v) in await AppAttestManager.shared.assertionHeaders(for: httpBody) {
                req.setValue(v, forHTTPHeaderField: k)
            }
        } else {
            req.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        }

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

        // Status/result/cancel URLs. In proxy mode the absolute *.fal.run URLs
        // from the submit response would bypass the proxy (and lack the key), so
        // build proxy-relative paths from model + requestID instead — using the
        // *base* app id, never the submit path (see queueAppID).
        let queueModel = queueAppID(for: model)
        let statusURL: URL
        let resultURL: URL
        let cancelURLString: String?
        if APIConfig.usesProxy {
            let direct = URL(string: "\(queueBase)/\(queueModel)/requests/\(requestID)")!
            statusURL = APIConfig.url(provider: "fal", directURL: direct, proxyPath: "\(queueModel)/requests/\(requestID)/status")
            resultURL = APIConfig.url(provider: "fal", directURL: direct, proxyPath: "\(queueModel)/requests/\(requestID)")
            cancelURLString = APIConfig.url(provider: "fal", directURL: direct, proxyPath: "\(queueModel)/requests/\(requestID)/cancel").absoluteString
        } else if let statusStr = submitJSON["status_url"] as? String, let parsedStatus = URL(string: statusStr),
                  let responseStr = submitJSON["response_url"] as? String, let parsedResult = URL(string: responseStr) {
            statusURL = parsedStatus
            resultURL = parsedResult
            cancelURLString = submitJSON["cancel_url"] as? String
        } else {
            statusURL = URL(string: "\(queueBase)/\(queueModel)/requests/\(requestID)/status")!
            resultURL = URL(string: "\(queueBase)/\(queueModel)/requests/\(requestID)")!
            cancelURLString = submitJSON["cancel_url"] as? String
        }

        do {
            return try await poll(statusURL: statusURL, resultURL: resultURL, apiKey: apiKey)
        } catch {
            // If our Task was cancelled, tell fal.ai to stop the queued job too —
            // otherwise it runs to completion server-side and still bills.
            let wasCancelled = error is CancellationError || (error as? URLError)?.code == .cancelled
            if wasCancelled, let str = cancelURLString, let cancelURL = URL(string: str) {
                let usesProxy = APIConfig.usesProxy
                // Detached: the current task is already cancelled and can't await
                Task.detached {
                    var cancelReq = URLRequest(url: cancelURL)
                    cancelReq.httpMethod = "PUT"
                    await authorize(&cancelReq, apiKey: apiKey, usesProxy: usesProxy, body: Data())
                    _ = try? await URLSession.shared.data(for: cancelReq)
                }
            }
            throw error
        }
    }

    /// Attaches auth: App Attest assertion in proxy mode, else the fal.ai key.
    private static func authorize(_ req: inout URLRequest, apiKey: String, usesProxy: Bool, body: Data) async {
        if usesProxy {
            for (k, v) in await AppAttestManager.shared.assertionHeaders(for: body) {
                req.setValue(v, forHTTPHeaderField: k)
            }
        } else {
            req.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        }
    }

    private static func poll(
        statusURL: URL,
        resultURL: URL,
        apiKey: String
    ) async throws -> String {
        let usesProxy = APIConfig.usesProxy
        var consecutiveClientErrors = 0
        for attempt in 0..<60 {
            let delay: UInt64 = attempt < 5 ? 2_000_000_000 : 3_000_000_000
            try await Task.sleep(nanoseconds: delay)

            var statusReq = URLRequest(url: statusURL)
            await authorize(&statusReq, apiKey: apiKey, usesProxy: usesProxy, body: Data())
            let attemptResult = try? await URLSession.shared.data(for: statusReq)

            // A wrong route or bad auth never becomes valid by waiting. Allow a
            // few retries for queue eventual-consistency, then surface it rather
            // than burning the full ~3 minute timeout on a permanent failure.
            if let http = attemptResult?.1 as? HTTPURLResponse,
               (400..<500).contains(http.statusCode), http.statusCode != 408, http.statusCode != 429 {
                consecutiveClientErrors += 1
                if consecutiveClientErrors >= 3 {
                    throw FalAIError.requestFailed("status poll returned HTTP \(http.statusCode) for \(statusURL.path)")
                }
                continue
            }
            consecutiveClientErrors = 0

            guard let (statusData, _) = attemptResult,
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
            await authorize(&resultReq, apiKey: apiKey, usesProxy: usesProxy, body: Data())
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
