//
//  ClaudeAPIService.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import Foundation

struct ClaudeAPIService {
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let model = "claude-haiku-4-5"

    static func generateAffirmations(
        description: String,
        goals: [String],
        style: String
    ) async throws -> [String] {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String,
              !apiKey.isEmpty else {
            throw ClaudeAPIError.missingAPIKey
        }

        let prompt = buildPrompt(description: description, goals: goals, style: style)
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 512,
            "messages": [["role": "user", "content": prompt]]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ClaudeAPIError.requestFailed
        }

        return try parseAffirmations(from: data)
    }

    private static func buildPrompt(description: String, goals: [String], style: String) -> String {
        let goalsText = goals.isEmpty ? "general life improvement" : goals.joined(separator: ", ")
        return """
        Generate exactly 5 short, powerful affirmations for a vision board.

        User's vision: \(description)
        Goals: \(goalsText)
        Visual style: \(style)

        Rules:
        - Each affirmation starts with "I am" or "I have" or "I attract"
        - Maximum 12 words each
        - Present tense, positive, personal
        - Tailored to the specific vision and goals

        Return ONLY the 5 affirmations, one per line, no numbering, no extra text.
        """
    }

    private static func parseAffirmations(from data: Data) throws -> [String] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            throw ClaudeAPIError.invalidResponse
        }
        let lines = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !lines.isEmpty else { throw ClaudeAPIError.invalidResponse }
        return Array(lines.prefix(5))
    }
}

enum ClaudeAPIError: LocalizedError {
    case missingAPIKey
    case requestFailed
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Anthropic API key not configured"
        case .requestFailed: return "Request to Claude API failed"
        case .invalidResponse: return "Invalid response from Claude API"
        }
    }
}
