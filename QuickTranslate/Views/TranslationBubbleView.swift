//
//  TranslationBubbleView.swift
//  QuickTranslate
//
//  Created by AceXiamo on 2025/9/17.
//

import SwiftUI

struct TranslationBubbleView: View {
    let translation: TranslationResult
    let onReplace: (String) -> Void
    let onCancel: () -> Void

    @State private var editMode = false
    @State private var editedText: String

    init(translation: TranslationResult, onReplace: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.translation = translation
        self.onReplace = onReplace
        self.onCancel = onCancel
        self._editedText = State(initialValue: translation.translatedText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.blue)
                    Text("\(translation.sourceLanguage.name) → \(translation.targetLanguage.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if translation.confidence < 0.5 {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .help("Translation confidence is low")
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "doc.plaintext")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Text("原文:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(translation.originalText)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Image(systemName: "doc.badge.arrow.up")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("译文:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if editMode {
                        TextField("编辑译文", text: $editedText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Text(translation.translatedText)
                            .padding(8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack {
                        Image(systemName: "arrow.uturn.left")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("验证:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(translation.backTranslation)
                        .font(.caption)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                if editMode {
                    Button("保存") {
                        onReplace(editedText)
                        editMode = false
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [])

                    Button("取消编辑") {
                        editedText = translation.translatedText
                        editMode = false
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("替换") {
                        onReplace(translation.translatedText)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [])

                    Button("编辑") {
                        editMode = true
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut("e", modifiers: [])

                    Button("取消") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.escape, modifiers: [])
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 8)
        .frame(maxWidth: 450, maxHeight: 600)
    }
}