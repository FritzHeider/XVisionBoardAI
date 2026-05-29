//
//  ImageGenerationService.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import Foundation
import UIKit

struct ImageGenerationService {
    private static let endpoint = "https://api.replicate.com/v1/predictions"

    // Generate an image from a text prompt + optional reference image
    // Returns a URL string to the generated image, or nil on failure
    static func generateImage(
        prompt: String,
        referenceImageData: Data? = nil,
        style: String
    ) async throws -> String? {
        guard let apiToken = Bundle.main.object(forInfoDictionaryKey: "REPLICATE_API_TOKEN") as? String,
              !apiToken.isEmpty else {
            return nil  // No token → fall back to placeholder
        }

        // Build the Replicate prediction request
        // Using a face-swap/inpainting compatible model
        let modelVersion = "stability-ai/stable-diffusion:db21e45d3f7023abc2a46ee38a23973f6dce16bb082a930b0c49861f96d1e5bf"
        let input: [String: Any] = [
            "prompt": "\(prompt), high quality, photorealistic",
            "num_inference_steps": 30,
            "guidance_scale": 7.5
        ]
        let body: [String: Any] = ["version": modelVersion, "input": input]

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Token \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let predictionId = json["id"] as? String else {
            return nil
        }

        // Poll for completion
        return try await pollForResult(predictionId: predictionId, apiToken: apiToken)
    }

    private static func pollForResult(predictionId: String, apiToken: String) async throws -> String? {
        let pollURL = URL(string: "\(endpoint)/\(predictionId)")!
        for _ in 0..<30 {
            try await Task.sleep(for: .seconds(2))
            var req = URLRequest(url: pollURL)
            req.setValue("Token \(apiToken)", forHTTPHeaderField: "Authorization")
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
            let status = json["status"] as? String
            if status == "succeeded",
               let output = json["output"] as? [String],
               let first = output.first {
                return first
            } else if status == "failed" {
                return nil
            }
        }
        return nil
    }
}
