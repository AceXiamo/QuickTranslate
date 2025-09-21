//
//  HotKeyService.swift
//  QuickTranslate
//
//  Created by AceXiamo on 2025/9/17.
//

import Foundation
import Carbon

class HotKeyService: ObservableObject {
    static let shared = HotKeyService()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let hotKeyID: EventHotKeyID = EventHotKeyID(signature: OSType(0x74726e73), id: 1)

    var onHotKeyPressed: (() -> Void)?

    private init() {}

    func registerHotKey() -> Bool {
        guard UserSettings.shared.hotKeyEnabled else { return false }

        unregisterHotKey()

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))

        let installResult = InstallEventHandler(
            GetEventDispatcherTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                return HotKeyService.hotKeyHandler(nextHandler, theEvent, userData)
            },
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        guard installResult == noErr else { return false }

        let registerResult = RegisterEventHotKey(
            UInt32(kVK_ANSI_T),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        return registerResult == noErr
    }

    func unregisterHotKey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    private static func hotKeyHandler(_ nextHandler: EventHandlerCallRef?, _ theEvent: EventRef?, _ userData: UnsafeMutableRawPointer?) -> OSStatus {
        guard let userData = userData else { return OSStatus(eventNotHandledErr) }

        let hotKeyService = Unmanaged<HotKeyService>.fromOpaque(userData).takeUnretainedValue()

        var hotKeyID = EventHotKeyID()
        let result = GetEventParameter(
            theEvent,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard result == noErr && hotKeyID.id == hotKeyService.hotKeyID.id else {
            return OSStatus(eventNotHandledErr)
        }

        DispatchQueue.main.async {
            hotKeyService.onHotKeyPressed?()
        }

        return noErr
    }

    deinit {
        unregisterHotKey()
    }
}