// Sources/FlowState/Views/ScreenTintOverlay.swift
import Cocoa
import QuartzCore

final class ScreenTintOverlay: NSPanel {
    private let overlayView: NSView

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init(for screen: NSScreen) {
        // Use bounds (local coordinates) for the view, not frame (global coordinates)
        let bounds = NSRect(origin: .zero, size: screen.frame.size)
        overlayView = NSView(frame: bounds)

        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Configure panel
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.hasShadow = false
        self.hidesOnDeactivate = false

        // Set content view
        self.contentView = overlayView
        overlayView.autoresizingMask = [.width, .height]

        // Configure layer AFTER view is added to window
        overlayView.wantsLayer = true
        overlayView.layer?.backgroundColor = NSColor(calibratedRed: 0.97, green: 0.65, blue: 0.21, alpha: 1.0).cgColor
        overlayView.layer?.opacity = 0
    }

    func animateDimming(duration: TimeInterval, intensity: Float) {
        guard let layer = overlayView.layer else { return }

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = layer.presentation()?.opacity ?? layer.opacity
        animation.toValue = intensity
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeIn)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.opacity = intensity
        CATransaction.commit()

        layer.add(animation, forKey: "dimming")
    }

    func clearTint(duration: TimeInterval = 1.0, completion: (() -> Void)? = nil) {
        guard let layer = overlayView.layer else {
            completion?()
            return
        }

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = layer.presentation()?.opacity ?? layer.opacity
        animation.toValue = 0.0
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.opacity = 0
        CATransaction.commit()

        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        layer.add(animation, forKey: "clearDimming")
        CATransaction.commit()
    }
}
