//
//  LoadingBubbleView.swift
//  QuickTranslate
//
//  Created by AceXiamo on 2025/9/17.
//

import SwiftUI

struct LoadingBubbleView: View {
    let selectedText: String

    @State private var animateGradient = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.blue)
                    .rotationEffect(Angle(degrees: animateGradient ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: animateGradient)
                Text("正在翻译...")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("原文:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(selectedText)
                    .font(.body)
                    .lineLimit(2)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 8)
        .frame(maxWidth: 300)
        .onAppear {
            animateGradient = true
        }
    }
}