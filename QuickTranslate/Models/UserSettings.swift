//
//  UserSettings.swift
//  QuickTranslate
//
//  Created by AceXiamo on 2025/9/17.
//

import Foundation

class UserSettings: ObservableObject {
    static let shared = UserSettings()

    @Published var aiEndpoint: String {
        didSet {
            UserDefaults.standard.set(aiEndpoint, forKey: "aiEndpoint")
        }
    }

    @Published var apiKey: String {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: "apiKey")
        }
    }

    @Published var model: String {
        didSet {
            UserDefaults.standard.set(model, forKey: "model")
        }
    }

    @Published var hotKeyEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hotKeyEnabled, forKey: "hotKeyEnabled")
        }
    }

    @Published var bubbleDisplayTime: Double {
        didSet {
            UserDefaults.standard.set(bubbleDisplayTime, forKey: "bubbleDisplayTime")
        }
    }

    private init() {
        self.aiEndpoint = UserDefaults.standard.string(forKey: "aiEndpoint") ?? "https://api.openai.com/v1"
        self.apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? ""
        self.model = UserDefaults.standard.string(forKey: "model") ?? "gpt-3.5-turbo"
        self.hotKeyEnabled = UserDefaults.standard.bool(forKey: "hotKeyEnabled")
        self.bubbleDisplayTime = UserDefaults.standard.double(forKey: "bubbleDisplayTime") == 0 ? 10.0 : UserDefaults.standard.double(forKey: "bubbleDisplayTime")
    }

    var aiConfiguration: AIConfiguration {
        return AIConfiguration(endpoint: aiEndpoint, apiKey: apiKey, model: model)
    }

    var isConfigured: Bool {
        return !aiEndpoint.isEmpty && !apiKey.isEmpty && !model.isEmpty
    }
}