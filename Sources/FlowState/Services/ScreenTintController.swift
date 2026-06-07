// Sources/FlowState/Services/ScreenTintController.swift
import Cocoa
import SwiftUI

@MainActor
@Observable
final class ScreenTintController {
    private var overlays: [ScreenTintOverlay] = []
    private var screenChangeObserver: NSObjectProtocol?
    private var terminationObserver: NSObjectProtocol?
    private(set) var isTinting: Bool = false

    @ObservationIgnored
    @AppStorage("tintAnimationDuration") private var animationDuration: Double = 30.0

    @ObservationIgnored
    @AppStorage("tintIntensity") private var tintIntensity: Double = 0.6

    func show() {
        guard !isTinting else { return }

        isTinting = true
        rebuildOverlays()
        startObservers()
    }

    func hide() {
        guard isTinting else { return }

        stopObservers()
        let activeOverlays = overlays
        overlays.removeAll()
        isTinting = false

        for overlay in activeOverlays {
            overlay.clearTint {
                overlay.orderOut(nil)
            }
        }
    }

    private func rebuildOverlays() {
        for overlay in overlays {
            overlay.orderOut(nil)
        }
        overlays.removeAll()

        for screen in NSScreen.screens {
            let overlay = ScreenTintOverlay(for: screen)
            overlay.orderFrontRegardless()
            overlay.animateDimming(duration: animationDuration, intensity: Float(tintIntensity))
            overlays.append(overlay)
        }
    }

    private func startObservers() {
        stopObservers()

        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isTinting else { return }
                self.rebuildOverlays()
            }
        }

        terminationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.hide()
            }
        }
    }

    private func stopObservers() {
        if let screenChangeObserver {
            NotificationCenter.default.removeObserver(screenChangeObserver)
            self.screenChangeObserver = nil
        }
        if let terminationObserver {
            NotificationCenter.default.removeObserver(terminationObserver)
            self.terminationObserver = nil
        }
    }
}
