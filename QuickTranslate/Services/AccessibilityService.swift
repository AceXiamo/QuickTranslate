//
//  AccessibilityService.swift
//  QuickTranslate
//
//  Created by AceXiamo on 2025/9/17.
//

import Foundation
import ApplicationServices
import AppKit

class AccessibilityService: ObservableObject {
    static let shared = AccessibilityService()

    private init() {}

    func requestAccessibilityPermissions() -> Bool {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            let result = AXIsProcessTrustedWithOptions(options)

            // 如果仍然没有权限，打开系统偏好设置
            if !result {
                openAccessibilitySettings()
            }
            return result
        }
        return trusted
    }

    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    func getSelectedText() -> String? {
        print("🔍 开始获取选中文本...")

        // 检查辅助功能权限
        let isTrusted = AXIsProcessTrusted()
        print("📋 辅助功能权限状态: \(isTrusted)")
        guard isTrusted else {
            print("❌ 辅助功能权限未授权")
            return nil
        }

        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        print("🎯 获取焦点元素结果: \(result == .success ? "成功" : "失败")")

        if result != .success {
            let errorMessage = getAccessibilityErrorMessage(result)
            print("❌ 获取焦点元素失败，错误代码: \(result.rawValue) (\(errorMessage))")
            print("🔄 尝试备用方案...")
            return getTextViaAlternativeMethod()
        }

        guard let element = focusedElement as! AXUIElement? else {
            print("❌ 焦点元素为空")
            return getTextViaAlternativeMethod()
        }

        // 尝试获取选中文本
        var selectedText: CFTypeRef?
        let selectedTextResult = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText)
        print("📝 获取选中文本结果: \(selectedTextResult == .success ? "成功" : "失败")")

        if selectedTextResult == .success, let text = selectedText as? String, !text.isEmpty {
            print("✅ 获取到选中文本: \"\(text)\"")
            return text
        }

        // 尝试获取整个输入框的值
        var value: CFTypeRef?
        let valueResult = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
        print("📄 获取元素值结果: \(valueResult == .success ? "成功" : "失败")")

        if valueResult == .success, let text = value as? String, !text.isEmpty {
            print("✅ 获取到元素值: \"\(text)\"")
            return text
        }

        print("❌ 无法获取选中文本")
        return nil
    }

    func replaceSelectedText(with newText: String) -> Bool {
        print("🔄 开始替换文本: \"\(newText)\"")

        guard AXIsProcessTrusted() else {
            print("❌ 无辅助功能权限")
            return false
        }

        // 方法1: 尝试直接替换选中文本
        if replaceViaAccessibility(newText: newText) {
            print("✅ 直接替换成功")
            return true
        }

        // 方法2: 使用剪贴板 + 粘贴 (更通用的 macOS 方式)
        print("🔄 尝试剪贴板替换...")
        return replaceViaPasteboard(newText: newText)
    }

    private func replaceViaAccessibility(newText: String) -> Bool {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        guard result == .success, let element = focusedElement as! AXUIElement? else {
            print("❌ 无法获取焦点元素")
            return false
        }

        // 尝试设置选中文本
        var selectedText: CFTypeRef?
        let selectedTextResult = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText)

        if selectedTextResult == .success, selectedText as? String != nil {
            let setResult = AXUIElementSetAttributeValue(element, kAXSelectedTextAttribute as CFString, newText as CFString)
            if setResult == .success {
                return true
            }
        }

        // 尝试设置元素值
        let setValueResult = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, newText as CFString)
        return setValueResult == .success
    }

    private func replaceViaPasteboard(newText: String) -> Bool {
        // 保存当前剪贴板内容
        let originalPasteboard = getTextFromPasteboard()

        // 将新文本放入剪贴板
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(newText, forType: .string)

        guard success else {
            print("❌ 无法设置剪贴板")
            return false
        }

        // 模拟 Cmd+V 粘贴
        simulateKeyPress(keyCode: 9, flags: .maskCommand) // V key

        // 等待粘贴完成
        usleep(100000) // 100ms

        // 恢复原剪贴板内容（如果有的话）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let original = originalPasteboard {
                pasteboard.clearContents()
                pasteboard.setString(original, forType: .string)
            }
        }

        print("✅ 剪贴板替换完成")
        return true
    }

    func getCurrentTextElement() -> AXUIElement? {
        guard AXIsProcessTrusted() else { return nil }

        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        return result == .success ? focusedElement as! AXUIElement? : nil
    }

    func getSelectedTextPosition() -> NSRect? {
        print("📍 开始获取选中文本位置...")

        guard AXIsProcessTrusted() else {
            print("❌ 无辅助功能权限，无法获取位置")
            return nil
        }

        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        guard result == .success, let element = focusedElement as! AXUIElement? else {
            print("❌ 无法获取焦点元素位置")
            return nil
        }

        // 尝试获取选中文本的范围和位置
        var selectedTextRange: CFTypeRef?
        let rangeResult = AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &selectedTextRange)

        if rangeResult == .success, let range = selectedTextRange {
            // 获取选中文本范围的边界框
            var bounds: CFTypeRef?
            let boundsResult = AXUIElementCopyParameterizedAttributeValue(
                element,
                kAXBoundsForRangeParameterizedAttribute as CFString,
                range,
                &bounds
            )

            if boundsResult == .success, let boundsValue = bounds {
                var rect = CGRect.zero
                if AXValueGetValue(boundsValue as! AXValue, AXValueType.cgRect, &rect) {
                    print("✅ 获取到选中文本位置: \(rect)")
                    return rect
                }
            }
        }

        // 备用方案：获取元素的位置和大小
        var position: CFTypeRef?
        var size: CFTypeRef?

        let posResult = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &position)
        let sizeResult = AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &size)

        if posResult == .success && sizeResult == .success,
           let posValue = position, let sizeValue = size {

            var point = CGPoint.zero
            var cgSize = CGSize.zero

            if AXValueGetValue(posValue as! AXValue, AXValueType.cgPoint, &point) &&
               AXValueGetValue(sizeValue as! AXValue, AXValueType.cgSize, &cgSize) {

                let rect = CGRect(origin: point, size: cgSize)
                print("✅ 获取到元素位置 (备用): \(rect)")
                return rect
            }
        }

        print("❌ 无法获取文本位置")
        return nil
    }

    private func getTextFromPasteboard() -> String? {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: NSPasteboard.PasteboardType.string)
    }

    func simulateKeyPress(keyCode: CGKeyCode, flags: CGEventFlags = []) {
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
              let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
            return
        }

        keyDownEvent.flags = flags
        keyUpEvent.flags = flags

        keyDownEvent.post(tap: .cghidEventTap)
        keyUpEvent.post(tap: .cghidEventTap)
    }

    func selectAllText() {
        simulateKeyPress(keyCode: 0, flags: .maskCommand)
    }

    // 备用文本获取方法
    private func getTextViaAlternativeMethod() -> String? {
        print("🔄 使用备用方法获取文本...")

        // 方法1: 先尝试模拟 Cmd+C 复制选中文本
        let originalPasteboard = getTextFromPasteboard()
        print("📋 原始剪贴板内容: \(originalPasteboard ?? "空")")

        // 清空剪贴板
        NSPasteboard.general.clearContents()

        // 模拟 Cmd+C 复制
        simulateKeyPress(keyCode: 8, flags: .maskCommand) // C key

        // 等待一小段时间让复制操作完成
        usleep(150000) // 150ms

        let copiedText = getTextFromPasteboard()
        print("📝 复制后剪贴板内容: \(copiedText ?? "空")")

        // 立即恢复原剪贴板内容，避免污染用户剪贴板
        if let original = originalPasteboard {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(original, forType: .string)
        }

        if let text = copiedText, !text.isEmpty {
            print("✅ 通过Cmd+C获取到文本: \"\(text)\"")
            return text
        }

        // 方法2: 尝试使用当前应用信息进行重试
        if let frontmostApp = NSWorkspace.shared.frontmostApplication {
            print("🎯 当前前台应用: \(frontmostApp.localizedName ?? "未知")")

            // 对于某些应用，可能需要特殊处理
            return tryAppSpecificTextExtraction(appName: frontmostApp.localizedName ?? "")
        }

        print("❌ 所有备用方法都失败了")
        return nil
    }

    private func tryAppSpecificTextExtraction(appName: String) -> String? {
        print("🔧 尝试针对 \(appName) 的通用文本提取...")

        // 对于所有浏览器，使用统一的重试策略
        if appName.lowercased().contains("safari") ||
           appName.lowercased().contains("chrome") ||
           appName.lowercased().contains("firefox") ||
           appName.lowercased().contains("arc") {

            // 等待一下再重试
            usleep(200000) // 200ms
            return retryGetSelectedTextDirectly()
        }

        return nil
    }

    private func retryGetSelectedTextDirectly() -> String? {
        print("🔄 重试直接获取选中文本...")

        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        if result == .success, let element = focusedElement as! AXUIElement? {
            var selectedText: CFTypeRef?
            let selectedTextResult = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText)

            if selectedTextResult == .success, let text = selectedText as? String, !text.isEmpty {
                print("✅ 重试成功获取选中文本: \"\(text)\"")
                return text
            }
        }

        return nil
    }

    private func getAccessibilityErrorMessage(_ error: AXError) -> String {
        switch error {
        case .success:
            return "成功"
        case .failure:
            return "通用失败"
        case .illegalArgument:
            return "非法参数"
        case .invalidUIElement:
            return "无效UI元素"
        case .invalidUIElementObserver:
            return "无效UI元素观察者"
        case .cannotComplete:
            return "无法完成操作"
        case .attributeUnsupported:
            return "属性不支持"
        case .actionUnsupported:
            return "操作不支持"
        case .notificationUnsupported:
            return "通知不支持"
        case .notImplemented:
            return "未实现"
        case .notificationAlreadyRegistered:
            return "通知已注册"
        case .notificationNotRegistered:
            return "通知未注册"
        case .apiDisabled:
            return "API被禁用 - 应用限制了辅助功能访问"
        case .noValue:
            return "无值"
        case .parameterizedAttributeUnsupported:
            return "参数化属性不支持"
        case .notEnoughPrecision:
            return "精度不足"
        @unknown default:
            return "未知错误"
        }
    }
}
