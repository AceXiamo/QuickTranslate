//
//  TranslationController.swift
//  QuickTranslate
//
//  Created by AceXiamo on 2025/9/17.
//

import Foundation
import SwiftUI
import AppKit

// 自定义窗口类，可以接收键盘事件
class FloatingWindow: NSWindow {
    override var canBecomeKey: Bool { true }  // 允许成为关键窗口以接收键盘事件
    override var canBecomeMain: Bool { false }

    var onEnterPressed: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 { // Enter key
            onEnterPressed?()
        } else {
            super.keyDown(with: event)
        }
    }
}

class TranslationController: ObservableObject {
    static let shared = TranslationController()

    private let translationService = TranslationService.shared
    private let accessibilityService = AccessibilityService.shared
    private let hotKeyService = HotKeyService.shared

    @Published var isTranslating = false
    @Published var currentTranslation: TranslationResult?
    @Published var showBubble = false

    private var bubbleWindow: FloatingWindow?
    private var originalApp: NSRunningApplication?
    private var preCreatedWindow: FloatingWindow?
    private var savedBubblePosition: NSPoint?

    init() {
        setupHotKey()
        prepareWindow()
    }

    private func setupHotKey() {
        hotKeyService.onHotKeyPressed = { [weak self] in
            Task { @MainActor in
                await self?.handleTranslationRequest()
            }
        }
        _ = hotKeyService.registerHotKey()
    }

    @MainActor
    func handleTranslationRequest() async {
        guard !isTranslating else { return }

        guard accessibilityService.requestAccessibilityPermissions() else {
            showAccessibilityAlert()
            return
        }

        // 保存当前前台应用
        originalApp = NSWorkspace.shared.frontmostApplication

        // 获取选中文本的位置信息
        let selectedTextPosition = accessibilityService.getSelectedTextPosition()
        guard let selectedText = accessibilityService.getSelectedText(), !selectedText.isEmpty else {
            showNoTextAlert()
            return
        }

        // 保存文本位置用于气泡定位
        if let textRect = selectedTextPosition {
            // 将文本位置转换为气泡位置（文本下方20px，与第一个字符对齐）
            savedBubblePosition = NSPoint(
                x: textRect.minX,
                y: textRect.minY - 20
            )
        }

        isTranslating = true

        // 先显示加载状态
        showLoadingBubble(selectedText: selectedText)

        let result = await translationService.translateText(selectedText)

        switch result {
        case .success(let translation):
            currentTranslation = translation
            showTranslationBubble()
        case .failure(let error):
            hideBubble()
            showErrorAlert(error)
        }

        isTranslating = false
    }

    private func prepareWindow() {
        // 预创建一个窗口以提高响应速度
        let window = FloatingWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 400),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .popUpMenu
        window.hasShadow = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        preCreatedWindow = window
        print("✅ 预创建窗口完成")
    }

    private func showTranslationBubble() {
        guard let translation = currentTranslation else { return }

        hideBubble()

        let bubbleView = TranslationBubbleView(
            translation: translation,
            onReplace: { [weak self] text in
                self?.replaceText(with: text)
            },
            onCancel: { [weak self] in
                self?.hideBubble()
            }
        )

        let hostingView = NSHostingView(rootView: bubbleView)

        // 使用预创建的窗口或创建新窗口
        let window = preCreatedWindow ?? createNewWindow()

        // 让 SwiftUI 计算所需的尺寸
        let fittingSize = hostingView.fittingSize
        let maxWidth: CGFloat = 450
        let maxHeight: CGFloat = 600

        // 确保不超过最大尺寸，但允许内容自适应
        let width = min(max(fittingSize.width, 300), maxWidth)
        let height = min(max(fittingSize.height, 150), maxHeight)

        hostingView.frame = NSRect(x: 0, y: 0, width: width, height: height)

        // 调整窗口大小
        window.setContentSize(NSSize(width: width, height: height))
        window.contentView = hostingView

        positionBubbleWindow(window)

        bubbleWindow = window
        showBubble = true

        window.orderFront(nil)

        // 设置回车键监听
        if let translation = currentTranslation {
            window.onEnterPressed = { [weak self] in
                self?.replaceText(with: translation.translatedText)
            }
        }

        // 如果使用了预创建窗口，创建新的预创建窗口
        if preCreatedWindow != nil {
            preCreatedWindow = nil
            DispatchQueue.main.async { [weak self] in
                self?.prepareWindow()
            }
        }

        scheduleHideBubble()
    }

    private func createNewWindow() -> FloatingWindow {
        let window = FloatingWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 400),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .popUpMenu
        window.hasShadow = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        return window
    }

    private func showLoadingBubble(selectedText: String) {
        hideBubble()

        let loadingView = LoadingBubbleView(selectedText: selectedText)
        let hostingView = NSHostingView(rootView: loadingView)

        let window = preCreatedWindow ?? createNewWindow()

        let width: CGFloat = 300
        let height: CGFloat = 120

        hostingView.frame = NSRect(x: 0, y: 0, width: width, height: height)
        window.setContentSize(NSSize(width: width, height: height))
        window.contentView = hostingView

        positionBubbleWindow(window)

        bubbleWindow = window
        showBubble = true

        window.orderFront(nil)

        // 如果使用了预创建窗口，创建新的预创建窗口
        if preCreatedWindow != nil {
            preCreatedWindow = nil
            DispatchQueue.main.async { [weak self] in
                self?.prepareWindow()
            }
        }
    }

    private func positionBubbleWindow(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }

        let windowSize = window.frame.size
        let screenFrame = screen.visibleFrame

        var position: NSPoint

        if let savedPosition = savedBubblePosition {
            // 使用保存的文本位置，确保位置一致
            position = calculateOptimalPosition(
                around: savedPosition,
                windowSize: windowSize,
                screenFrame: screenFrame
            )
        } else {
            // 备用方案：使用鼠标位置
            let mouseLocation = NSEvent.mouseLocation
            position = calculateOptimalPosition(
                around: mouseLocation,
                windowSize: windowSize,
                screenFrame: screenFrame
            )
        }

        window.setFrameOrigin(position)
    }

    private func calculateOptimalPosition(around anchorPoint: NSPoint, windowSize: NSSize, screenFrame: NSRect) -> NSPoint {
        // 如果是文本位置，左对齐；如果是鼠标位置，居中对齐
        var x: CGFloat
        if savedBubblePosition != nil {
            // 文本位置：与第一个字符左对齐
            x = anchorPoint.x
        } else {
            // 鼠标位置：居中对齐
            x = anchorPoint.x - windowSize.width / 2
        }

        var y = anchorPoint.y - windowSize.height

        // 边界检测和调整
        let margin: CGFloat = 10

        // 水平边界检测
        if x < screenFrame.minX + margin {
            x = screenFrame.minX + margin
        } else if x + windowSize.width > screenFrame.maxX - margin {
            x = screenFrame.maxX - windowSize.width - margin
        }

        // 垂直边界检测
        if y < screenFrame.minY + margin {
            // 如果下方空间不够，显示在锚点上方
            y = anchorPoint.y + 20
            // 如果上方也不够，使用屏幕顶部
            if y + windowSize.height > screenFrame.maxY - margin {
                y = screenFrame.maxY - windowSize.height - margin
            }
        } else if y + windowSize.height > screenFrame.maxY - margin {
            y = screenFrame.maxY - windowSize.height - margin
        }

        return NSPoint(x: x, y: y)
    }

    private func scheduleHideBubble() {
        DispatchQueue.main.asyncAfter(deadline: .now() + UserSettings.shared.bubbleDisplayTime) { [weak self] in
            self?.hideBubble()
        }
    }

    func hideBubble() {
        guard let window = bubbleWindow else { return }

        // 确保在主线程上关闭窗口
        DispatchQueue.main.async {
            window.orderOut(nil)
            window.contentView = nil
        }

        bubbleWindow = nil
        showBubble = false
        currentTranslation = nil
        savedBubblePosition = nil  // 清理保存的位置
    }

    private func replaceText(with newText: String) {
        // 先恢复原应用焦点
        if let app = originalApp {
            app.activate(options: [])
            // 等待焦点切换完成
            usleep(100000) // 100ms
        }

        let success = accessibilityService.replaceSelectedText(with: newText)
        if !success {
            copyToPasteboard(newText)
        }

        // 延迟关闭气泡，避免在UI事件处理过程中释放窗口
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.hideBubble()
        }
    }

    private func copyToPasteboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: NSPasteboard.PasteboardType.string)
    }

    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = "QuickTranslate 需要辅助功能权限来读取和替换文本。请在系统偏好设置中启用辅助功能权限。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }

    private func showNoTextAlert() {
        let alert = NSAlert()
        alert.messageText = "未选择文本"
        alert.informativeText = "请先选择要翻译的文本，然后按 ⌘+Shift+T 进行翻译。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }

    private func showErrorAlert(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "翻译失败"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .critical
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
}
