// Sources/FlowState/Views/MenuBarIconRenderer.swift
import AppKit

enum MenuBarIconRenderer {
    static func render(score: Int) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let progress = CGFloat(max(0, min(100, score))) / 100.0
            let symbolRect = rect.insetBy(dx: 2.0, dy: 2.0)

            // Outer focus ring.
            let ringPath = NSBezierPath(ovalIn: symbolRect)
            ringPath.lineWidth = 1.6
            NSColor.white.withAlphaComponent(0.85).setStroke()
            ringPath.stroke()

            // Inner flow wave. The asymmetric wave gives the template icon a recognizable silhouette.
            let wave = NSBezierPath()
            let baseline = symbolRect.minY + symbolRect.height * (0.32 + progress * 0.28)
            wave.move(to: NSPoint(x: symbolRect.minX + 2.0, y: baseline))
            wave.curve(
                to: NSPoint(x: symbolRect.midX, y: baseline + 1.8),
                controlPoint1: NSPoint(x: symbolRect.minX + 3.8, y: baseline + 3.0),
                controlPoint2: NSPoint(x: symbolRect.midX - 2.4, y: baseline - 1.6)
            )
            wave.curve(
                to: NSPoint(x: symbolRect.maxX - 2.0, y: baseline + 0.4),
                controlPoint1: NSPoint(x: symbolRect.midX + 2.4, y: baseline + 4.0),
                controlPoint2: NSPoint(x: symbolRect.maxX - 3.4, y: baseline - 1.8)
            )
            wave.lineWidth = 1.8
            wave.lineCapStyle = .round
            NSColor.white.setStroke()
            wave.stroke()

            // Anchor dot.
            let dotSize: CGFloat = 3.0
            let dotRect = NSRect(
                x: symbolRect.midX - dotSize / 2,
                y: symbolRect.midY - dotSize / 2,
                width: dotSize,
                height: dotSize
            )
            NSColor.white.setFill()
            NSBezierPath(ovalIn: dotRect).fill()

            return true
        }

        image.isTemplate = true
        return image
    }

    static func renderBreakSuggestion() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let inset: CGFloat = 1.5
            let circleRect = rect.insetBy(dx: inset, dy: inset)

            let circlePath = NSBezierPath(ovalIn: circleRect)
            NSColor.white.withAlphaComponent(0.3).setFill()
            circlePath.fill()

            circlePath.lineWidth = 1.5
            NSColor.white.withAlphaComponent(0.8).setStroke()
            circlePath.stroke()

            let pauseWidth: CGFloat = 2.0
            let pauseHeight: CGFloat = 8.0
            let pauseGap: CGFloat = 3.0
            let centerX = rect.midX
            let centerY = rect.midY

            let leftBar = NSRect(
                x: centerX - pauseGap / 2 - pauseWidth,
                y: centerY - pauseHeight / 2,
                width: pauseWidth,
                height: pauseHeight
            )
            let rightBar = NSRect(
                x: centerX + pauseGap / 2,
                y: centerY - pauseHeight / 2,
                width: pauseWidth,
                height: pauseHeight
            )

            NSColor.white.setFill()
            NSBezierPath(roundedRect: leftBar, xRadius: 0.5, yRadius: 0.5).fill()
            NSBezierPath(roundedRect: rightBar, xRadius: 0.5, yRadius: 0.5).fill()

            return true
        }

        image.isTemplate = true
        return image
    }
}
