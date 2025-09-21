//
//  Language.swift
//  QuickTranslate
//
//  Created by AceXiamo on 2025/9/17.
//

import Foundation

enum Language: String, CaseIterable, Identifiable {
    case chinese = "zh"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"
    case french = "fr"
    case german = "de"
    case spanish = "es"
    case italian = "it"
    case portuguese = "pt"
    case russian = "ru"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .chinese: return "中文"
        case .english: return "English"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .spanish: return "Español"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .russian: return "Русский"
        }
    }

    var displayName: String {
        switch self {
        case .chinese: return "中文 (Chinese)"
        case .english: return "English"
        case .japanese: return "日本語 (Japanese)"
        case .korean: return "한국어 (Korean)"
        case .french: return "Français (French)"
        case .german: return "Deutsch (German)"
        case .spanish: return "Español (Spanish)"
        case .italian: return "Italiano (Italian)"
        case .portuguese: return "Português (Portuguese)"
        case .russian: return "Русский (Russian)"
        }
    }

    static func detectLanguage(from text: String) -> Language {
        let chineseCharacterSet = CharacterSet(charactersIn: "\u{4e00}"..."\u{9fff}")
        let japaneseCharacterSet = CharacterSet(charactersIn: "\u{3040}"..."\u{309f}").union(CharacterSet(charactersIn: "\u{30a0}"..."\u{30ff}"))
        let koreanCharacterSet = CharacterSet(charactersIn: "\u{ac00}"..."\u{d7af}")

        let textCharacterSet = CharacterSet(charactersIn: text)

        if !textCharacterSet.isDisjoint(with: chineseCharacterSet) {
            return .chinese
        } else if !textCharacterSet.isDisjoint(with: japaneseCharacterSet) {
            return .japanese
        } else if !textCharacterSet.isDisjoint(with: koreanCharacterSet) {
            return .korean
        } else {
            return .english
        }
    }

    func getTargetLanguage() -> Language {
        switch self {
        case .chinese:
            return .english
        default:
            return .chinese
        }
    }
}