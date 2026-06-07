# Screen Tinting Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a desaturation overlay that gradually grays out the screen, triggered by manual buttons in the menu dropdown.

**Architecture:** NSPanel-based overlay with CIColorControls filter for desaturation, controlled by ScreenTintController service, integrated into AppState and MenuBarDropdown.

**Tech Stack:** AppKit (NSPanel, NSVisualEffectView), Core Image (CIFilter), Core Animation

---

### Task 1: Create ScreenTintOverlay

**Files:**
- Create: `Sources/FlowState/Views/ScreenTintOverlay.swift`

**Step 1: Create the overlay class**

```swift
// Sources/FlowState/Views/ScreenTintOverlay.swift
import Cocoa
import QuartzCore

final class ScreenTintOverlay: NSPanel {
    private let overlayView: NSView
    private let colorFilter: CIFilter

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init() {
        // Create desaturation filter
        colorFilter = CIFilter(name: "CIColorControls")!
        colorFilter.setValue(1.0, forKey: kCIInputSaturationKey) // Start with full color

        // Create overlay view
        overlayView = NSView()
        overlayView.wantsLayer = true
        overlayView.layer?.backgroundColor = NSColor.black.cgColor
        overlayView.layer?.opacity = 0

        // Get main screen size
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)

        super.init(
            contentRect: screenFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        // Configure panel
        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.hasShadow = false

        // Add overlay view
        self.contentView = overlayView
        overlayView.frame = screenFrame
    }

    func setSaturation(_ saturation: CGFloat) {
        // saturation: 1.0 = full color, 0.0 = grayscale
        // We invert to opacity: 0.0 = invisible, 0.7 = visible gray overlay
        let opacity = Float((1.0 - saturation) * 0.7)
        overlayView.layer?.opacity = opacity
    }

    func animateDesaturation(duration: TimeInterval) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.0
        animation.toValue = 0.7
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        overlayView.layer?.add(animation, forKey: "desaturation")
        overlayView.layer?.opacity = 0.7
    }

    func clearTint() {
        overlayView.layer?.removeAllAnimations()
        overlayView.layer?.opacity = 0
    }
}
```

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add .
git commit -m "feat: add ScreenTintOverlay with desaturation effect"
```

---

### Task 2: Create ScreenTintController

**Files:**
- Create: `Sources/FlowState/Services/ScreenTintController.swift`

**Step 1: Create the controller**

```swift
// Sources/FlowState/Services/ScreenTintController.swift
import Cocoa

@MainActor
@Observable
final class ScreenTintController {
    private var overlay: ScreenTintOverlay?
    private(set) var isTinting: Bool = false

    private let animationDuration: TimeInterval = 30.0

    func show() {
        guard !isTinting else { return }

        isTinting = true

        // Create and show overlay
        let newOverlay = ScreenTintOverlay()
        newOverlay.orderFrontRegardless()
        newOverlay.animateDesaturation(duration: animationDuration)

        overlay = newOverlay
    }

    func hide() {
        guard isTinting else { return }

        overlay?.clearTint()
        overlay?.orderOut(nil)
        overlay = nil

        isTinting = false
    }
}
```

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add .
git commit -m "feat: add ScreenTintController to manage overlay lifecycle"
```

---

### Task 3: Update AppState with Tint Control

**Files:**
- Modify: `Sources/FlowState/AppState.swift`

**Step 1: Add tintController and methods to AppState**

Add these to AppState class:

```swift
let tintController = ScreenTintController()

var isTinting: Bool { tintController.isTinting }

func startTint() {
    tintController.show()
}

func clearTint() {
    tintController.hide()
}
```

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add .
git commit -m "feat: add tint control methods to AppState"
```

---

### Task 4: Update MenuBarDropdown with Tint Buttons

**Files:**
- Modify: `Sources/FlowState/Views/MenuBarDropdown.swift`

**Step 1: Add new properties and buttons**

Add these properties to MenuBarDropdown:

```swift
let isTinting: Bool
let onTestTint: () -> Void
let onClearTint: () -> Void
```

Add this view between the activity indicators and the Divider before Quit:

```swift
private var tintControlsView: some View {
    HStack(spacing: 12) {
        Button("Test Tint") {
            onTestTint()
        }
        .disabled(isTinting)

        Button("Clear Tint") {
            onClearTint()
        }
        .disabled(!isTinting)
    }
    .buttonStyle(.bordered)
}
```

Update the body to include tintControlsView in the scoreView section.

Update the previews to include the new parameters.

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add .
git commit -m "feat: add tint control buttons to MenuBarDropdown"
```

---

### Task 5: Wire Tint Controls in FlowStateApp

**Files:**
- Modify: `Sources/FlowState/FlowStateApp.swift`

**Step 1: Update MenuBarDropdown instantiation**

Update the MenuBarDropdown in FlowStateApp to include:

```swift
MenuBarDropdown(
    focusScore: appState.focusEngine.currentScore,
    hasPermission: appState.permissionChecker.hasPermission,
    keystrokesActive: appState.keystrokesActive,
    mouseActive: appState.mouseActive,
    isTinting: appState.isTinting,
    onOpenSettings: {
        appState.permissionChecker.openSystemSettings()
    },
    onTestTint: {
        appState.startTint()
    },
    onClearTint: {
        appState.clearTint()
    },
    onQuit: {
        NSApplication.shared.terminate(nil)
    }
)
```

**Step 2: Build and run to test**

Run: `swift build && swift run`
Expected:
- App launches
- Click menu bar icon, see "Test Tint" and "Clear Tint" buttons
- Click "Test Tint" → screen gradually desaturates over 30 seconds
- Click "Clear Tint" → effect clears instantly

**Step 3: Commit and push**

```bash
git add .
git commit -m "feat: wire tint controls to complete screen tinting feature"
git push origin main
```

---

## Testing Checklist

After all tasks complete, manually verify:

- [ ] "Test Tint" button starts desaturation animation
- [ ] Screen gradually goes gray over ~30 seconds
- [ ] Mouse clicks still work through the overlay
- [ ] Keyboard input still works through the overlay
- [ ] "Clear Tint" instantly removes the effect
- [ ] Buttons correctly enable/disable based on tinting state
- [ ] Overlay covers the full main screen
