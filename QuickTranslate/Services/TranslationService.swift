//
//  TranslationService.swift
//  QuickTranslate
//
//  Created by AceXiamo on 2025/9/17.
//

import Foundation

class TranslationService: ObservableObject {
    static let shared = TranslationService()
    private let aiService = AIService.shared

    private init() {}

    func translateText(_ text: String) async -> Result<TranslationResult, Error> {
        do {
            let request = TranslationRequest(text: text)

            let translatedText = try await aiService.translate(
                text: request.text,
                from: request.sourceLanguage,
                to: request.targetLanguage
            )

            let backTranslation = try await aiService.translate(
                text: translatedText,
                from: request.targetLanguage,
                to: request.sourceLanguage
            )

            let confidence = calculateConfidence(original: request.text, backTranslation: backTranslation)

            let result = TranslationResult(
                originalText: request.text,
                translatedText: translatedText,
                backTranslation: backTranslation,
                sourceLanguage: request.sourceLanguage,
                targetLanguage: request.targetLanguage,
                confidence: confidence
            )

            return .success(result)
        } catch {
            return .failure(error)
        }
    }

    private func calculateConfidence(original: String, backTranslation: String) -> Double {
        let separatorSet = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let originalWords = original.lowercased().components(separatedBy: separatorSet).filter { !$0.isEmpty }
        let backWords = backTranslation.lowercased().components(separatedBy: separatorSet).filter { !$0.isEmpty }

        guard !originalWords.isEmpty else { return 0.0 }

        let commonWords = Set(originalWords).intersection(Set(backWords))
        return Double(commonWords.count) / Double(originalWords.count)
    }
}