//
//  QuickTranslateApp.swift
//  QuickTranslate
//
//  Created by AceXiamo on 2025/9/17.
//

import SwiftUI

@main
struct QuickTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 空 Scene，完全使用状态栏控制
        WindowGroup {
            EmptyView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var translationController: TranslationController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("🚀 应用启动完成")
        setupStatusBarItem()
        setupTranslationController()
        setupAppBehavior()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        print("👋 应用即将退出")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 防止应用在关闭窗口后退出
        print("📱 最后窗口关闭，但应用继续运行")
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 当用户点击 Dock 图标时的行为
        if !flag {
            showSettings()
        }
        return true
    }

    private func setupStatusBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "translate", accessibilityDescription: "QuickTranslate")
            button.target = self
            button.action = #selector(statusBarButtonClicked)
        }
        print("📍 状态栏图标设置完成")
    }

    private func setupTranslationController() {
        translationController = TranslationController()
        print("🔧 翻译控制器初始化完成")
    }

    private func setupAppBehavior() {
        // 设置为菜单栏应用，不在 Dock 中显示
        NSApp.setActivationPolicy(.accessory)

        // 确保应用不会意外退出
        NSApp.delegate = self

        print("⚙️ 应用行为设置完成")
    }

    @objc private func statusBarButtonClicked() {
        showSettings()
    }

    private func showSettings() {
        print("🔧 状态栏按钮被点击")

        // 临时切换到常规应用模式以显示设置窗口
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // 直接打开设置窗口，不使用可能导致崩溃的系统方法
        DispatchQueue.main.async {
            // 创建设置窗口
            let settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            settingsWindow.title = "QuickTranslate 设置"
            settingsWindow.center()
            settingsWindow.contentView = NSHostingView(rootView: SettingsView())
            settingsWindow.makeKeyAndOrderFront(nil)

            // 监听窗口关闭事件
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: settingsWindow,
                queue: .main
            ) { _ in
                // 窗口关闭后切换回菜单栏模式
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
}
