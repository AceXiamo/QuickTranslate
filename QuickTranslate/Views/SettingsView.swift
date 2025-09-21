//
//  SettingsView.swift
//  QuickTranslate
//
//  Created by AceXiamo on 2025/9/17.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = UserSettings.shared
    @State private var showingTestResult = false
    @State private var testResult = ""
    @State private var isTestingConnection = false

    var body: some View {
        TabView {
            AISettingsTab()
                .tabItem {
                    Label("AI 设置", systemImage: "brain.head.profile")
                }

            GeneralSettingsTab()
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct AISettingsTab: View {
    @ObservedObject private var settings = UserSettings.shared
    @State private var showingTestResult = false
    @State private var testResult = ""
    @State private var isTestingConnection = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI 翻译设置")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                Text("API Endpoint")
                    .font(.headline)
                TextField("https://api.openai.com/v1", text: $settings.aiEndpoint)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("支持 OpenAI 兼容的 API，如 OpenRouter 等")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.headline)
                SecureField("sk-...", text: $settings.apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("请确保 API Key 有足够的余额")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("模型")
                    .font(.headline)
                TextField("gpt-3.5-turbo", text: $settings.model)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("建议使用 gpt-3.5-turbo 或 gpt-4")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Button(isTestingConnection ? "测试中..." : "测试连接") {
                    testConnection()
                }
                .disabled(isTestingConnection || !settings.isConfigured)

                Spacer()

                if settings.isConfigured {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("配置完成")
                            .foregroundColor(.green)
                    }
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("请完成配置")
                            .foregroundColor(.orange)
                    }
                }
            }

            if showingTestResult {
                VStack(alignment: .leading, spacing: 4) {
                    Text("测试结果:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(testResult)
                        .font(.caption)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
            }

            Spacer()
        }
        .padding()
    }

    private func testConnection() {
        isTestingConnection = true
        showingTestResult = false

        Task {
            do {
                let result = try await AIService.shared.translate(
                    text: "Hello",
                    from: .english,
                    to: .chinese
                )
                await MainActor.run {
                    testResult = "✅ 连接成功！测试翻译：Hello → \(result)"
                    showingTestResult = true
                    isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    testResult = "❌ 连接失败：\(error.localizedDescription)"
                    showingTestResult = true
                    isTestingConnection = false
                }
            }
        }
    }
}

struct GeneralSettingsTab: View {
    @ObservedObject private var settings = UserSettings.shared
    private let accessibilityService = AccessibilityService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("通用设置")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Toggle("启用快捷键", isOn: $settings.hotKeyEnabled)
                    Spacer()
                    Text("⌘ + Shift + T")
                        .font(.caption)
                        .padding(4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }

                if settings.hotKeyEnabled && !accessibilityService.requestAccessibilityPermissions() {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("需要辅助功能权限才能使用快捷键")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("请在系统偏好设置中手动添加 QuickTranslate")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("打开设置") {
                            accessibilityService.openAccessibilitySettings()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("气泡显示时间")
                    .font(.headline)
                HStack {
                    Slider(value: $settings.bubbleDisplayTime, in: 5...30, step: 1)
                    Text("\(Int(settings.bubbleDisplayTime)) 秒")
                        .frame(width: 40)
                }
            }

            GroupBox("使用说明") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. 配置 AI 设置并测试连接")
                    Text("2. 启用快捷键并授权辅助功能权限")
                    Text("3. 如权限设置失败，请手动操作：")
                        .fontWeight(.medium)
                    Text("   • 打开 系统偏好设置 → 安全性与隐私 → 隐私")
                        .font(.caption2)
                    Text("   • 选择 辅助功能，点击锁图标解锁")
                        .font(.caption2)
                    Text("   • 点击 + 添加 QuickTranslate 应用")
                        .font(.caption2)
                    Text("4. 选择要翻译的文本")
                    Text("5. 按 ⌘ + Shift + T 进行翻译")
                    Text("6. 在弹出的气泡中选择操作")
                }
                .font(.caption)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}