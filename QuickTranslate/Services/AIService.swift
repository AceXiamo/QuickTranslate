//
//  AIService.swift
//  QuickTranslate
//
//  Created by AceXiamo on 2025/9/17.
//

import Foundation

class AIService: ObservableObject {
    static let shared = AIService()

    private init() {}

    func translate(text: String, from sourceLanguage: Language, to targetLanguage: Language) async throws -> String {
        let config = UserSettings.shared.aiConfiguration

        guard !config.apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }

        let url = URL(string: "\(config.endpoint)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        let prompt = createTranslationPrompt(text: text, from: sourceLanguage, to: targetLanguage)

        let aiRequest = AIRequest(
            model: config.model,
            messages: [
                AIRequest.Message(role: "system", content: "You are a professional translator. Translate the given text accurately and naturally. Only return the translated text without any additional explanation."),
                AIRequest.Message(role: "user", content: prompt)
            ],
            temperature: 0.3,
            maxTokens: 1000
        )

        request.httpBody = try JSONEncoder().encode(aiRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw AIServiceError.httpError(httpResponse.statusCode)
        }

        let aiResponse = try JSONDecoder().decode(AIResponse.self, from: data)

        guard let translatedText = aiResponse.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw AIServiceError.emptyResponse
        }

        return translatedText
    }

    private func createTranslationPrompt(text: String, from sourceLanguage: Language, to targetLanguage: Language) -> String {
        return "Translate the following text from \(sourceLanguage.name) to \(targetLanguage.name):\n\n\(text)"
    }
}

enum AIServiceError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpError(Int)
    case emptyResponse
    case networkError

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key is missing. Please configure your AI settings."
        case .invalidResponse:
            return "Invalid response from AI service."
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .emptyResponse:
            return "Empty response from AI service."
        case .networkError:
            return "Network error occurred."
        }
    }
}