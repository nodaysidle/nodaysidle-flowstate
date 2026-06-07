// Sources/FlowState/Views/MenuBarIconRenderer.swift
import AppKit

enum MenuBarIconRenderer {
    static func render(score: Int) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let inset: CGFloat = 1.5
            let circleRect = rect.insetBy(dx: inset, dy: inset)
            let fillPercent = CGFloat(max(0, min(100, score))) / 100.0

            // Draw fill from bottom up (liquid effect)
            if fillPercent > 0 {
                let fillHeight = circleRect.height * fillPercent
                let fillRect = NSRect(
                    x: circleRect.origin.x,
                    y: circleRect.origin.y,
                    width: circleRect.width,
                    height: fillHeight
                )

                // Create clipping path for circle
                let circlePath = NSBezierPath(ovalIn: circleRect)

                NSGraphicsContext.saveGraphicsState()
                circlePath.addClip()

                // Draw gradient fill for liquid/glass effect
                let gradient = NSGradient(colors: [
                    NSColor.white.withAlphaComponent(0.6),
                    NSColor.white.withAlphaComponent(0.9)
                ])
                gradient?.draw(in: fillRect, angle: 90)

                NSGraphicsContext.restoreGraphicsState()
            }

            // Draw circle outline
            let outlinePath = NSBezierPath(ovalIn: circleRect)
            outlinePath.lineWidth = 1.5
            NSColor.white.withAlphaComponent(0.8).setStroke()
            outlinePath.stroke()

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

            // Draw filled circle background
            let circlePath = NSBezierPath(ovalIn: circleRect)
            NSColor.white.withAlphaComponent(0.3).setFill()
            circlePath.fill()

            // Draw outline
            circlePath.lineWidth = 1.5
            NSColor.white.withAlphaComponent(0.8).setStroke()
            circlePath.stroke()

            // Draw pause icon in center
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
