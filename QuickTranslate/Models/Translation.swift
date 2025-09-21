//
//  Translation.swift
//  QuickTranslate
//
//  Created by AceXiamo on 2025/9/17.
//

import Foundation

struct TranslationResult {
    let originalText: String
    let translatedText: String
    let backTranslation: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let confidence: Double

    init(originalText: String, translatedText: String, backTranslation: String, sourceLanguage: Language, targetLanguage: Language, confidence: Double = 1.0) {
        self.originalText = originalText
        self.translatedText = translatedText
        self.backTranslation = backTranslation
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.confidence = confidence
    }
}

struct TranslationRequest {
    let text: String
    let sourceLanguage: Language
    let targetLanguage: Language

    init(text: String, sourceLanguage: Language? = nil, targetLanguage: Language? = nil) {
        self.text = text
        let detectedLanguage = sourceLanguage ?? Language.detectLanguage(from: text)
        self.sourceLanguage = detectedLanguage
        self.targetLanguage = targetLanguage ?? detectedLanguage.getTargetLanguage()
    }
}

struct AIConfiguration {
    let endpoint: String
    let apiKey: String
    let model: String

    static let `default` = AIConfiguration(
        endpoint: "https://api.openai.com/v1",
        apiKey: "",
        model: "gpt-3.5-turbo"
    )
}

struct AIResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }
}

struct AIRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let maxTokens: Int

    struct Message: Codable {
        let role: String
        let content: String
    }

    private enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}