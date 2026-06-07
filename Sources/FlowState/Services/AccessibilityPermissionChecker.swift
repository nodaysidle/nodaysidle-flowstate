// Sources/FlowState/Services/AccessibilityPermissionChecker.swift
import Cocoa
import ApplicationServices

@MainActor
@Observable
final class AccessibilityPermissionChecker {
    private(set) var hasPermission: Bool = false
    private var pollTimer: Timer?

    init() {
        checkPermission()
    }

    func checkPermission() {
        hasPermission = AXIsProcessTrusted()
    }

    func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPermission()
            }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    func promptForPermission() {
        // Using string literal for Swift 6 concurrency compatibility
        // (kAXTrustedCheckOptionPrompt is a mutable global in C, unsafe to access directly)
        let options: [String: Any] = ["AXTrustedCheckOptionPrompt": true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
        checkPermission()
    }
}
