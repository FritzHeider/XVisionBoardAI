import Foundation

/// Text generation via Gemini (used for vision-board affirmations), so the app
/// needs only the fal.ai and Gemini keys — no Anthropic dependency.
struct GeminiTextService {

    // "latest" alias so affirmations don't break when a pinned model is retired.
    private static let model   = "gemini-flash-latest"
    private static let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"

    static var apiKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String
    }

    static func generateAffirmations(
        description: String,
        goals: [String],
        style: String
    ) async throws -> [String] {
        guard let key = apiKey, !key.isEmpty else {
            throw GeminiImageError.missingAPIKey
        }

        let endpoint = "\(baseURL)/\(model):generateContent?key=\(key)"
        guard let url = URL(string: endpoint) else {
            throw GeminiImageError.requestFailed("Invalid endpoint URL")
        }

        let body: [String: Any] = [
            "contents": [["parts": [["text": buildPrompt(description: description, goals: goals, style: style)]]]]
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
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.compactMap({ $0["text"] as? String }).first else {
            throw GeminiImageError.invalidResponse
        }
        let lines = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            // Strip any stray leading bullet/number the model might add
            .map { $0.replacingOccurrences(of: #"^[\-\*\d\.\)\s]+"#, with: "", options: .regularExpression) }
            .filter { !$0.isEmpty }
        guard !lines.isEmpty else { throw GeminiImageError.invalidResponse }
        return Array(lines.prefix(5))
    }
}
