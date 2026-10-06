import Foundation

/// Gemini, par l'API `generateContent` de Google.
public struct GeminiClient: AIClient {
    public let provider = AIProvider.gemini
    private let apiKey: String
    private let model: String
    private let transport: any HTTPTransport

    public init(
        apiKey: String, model: String = AIProvider.gemini.defaultModel,
        transport: any HTTPTransport = URLSessionTransport()
    ) {
        self.apiKey = apiKey
        self.model = model
        self.transport = transport
    }

    public func answer(_ prompt: AIPrompt) async throws -> String {
        try Self.answerText(in: try await AIHTTP.send(try request(for: prompt), with: transport))
    }

    func request(for prompt: AIPrompt) throws -> URLRequest {
        let model = model.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? model
        var body: [String: Any] = [
            "systemInstruction": ["parts": [["text": prompt.instructions]]],
            "contents": prompt.messages.map { message in
                // Chez Gemini, l'IA s'appelle « model ».
                ["role": message.role == .user ? "user" : "model", "parts": [["text": message.text]]]
            },
        ]
        if let format = prompt.format {
            body["generationConfig"] = ["responseMimeType": "application/json", "responseSchema": format.openAPISchema]
        }
        return try AIHTTP.jsonRequest(
            url: AIHTTP.url("https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"),
            headers: ["x-goog-api-key": apiKey],
            body: body)
    }

    private struct Response: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable {
                    let text: String?
                    let thought: Bool?
                }

                let parts: [Part]?
            }

            let content: Content?
            let finishReason: String?
        }

        struct Feedback: Decodable { let blockReason: String? }

        let candidates: [Candidate]?
        let promptFeedback: Feedback?
    }

    /// Le texte de la première réponse (sans les éventuelles pensées du modèle).
    static func answerText(in data: Data) throws -> String {
        guard let response = try? JSONDecoder().decode(Response.self, from: data) else {
            throw AIFailure.invalidResponse
        }
        if response.promptFeedback?.blockReason != nil { throw AIFailure.refused }
        guard let candidate = response.candidates?.first else { throw AIFailure.invalidResponse }
        switch candidate.finishReason {
        case "SAFETY", "BLOCKLIST", "PROHIBITED_CONTENT", "SPII", "RECITATION": throw AIFailure.refused
        case "MAX_TOKENS": throw AIFailure.truncated
        default: break
        }
        let text = (candidate.content?.parts ?? []).filter { $0.thought != true }.compactMap(\.text).joined()
        guard !text.isEmpty else { throw AIFailure.invalidResponse }
        return text
    }
}
