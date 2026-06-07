# Auto-Trigger Tinting Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Automatically trigger screen tinting based on focus score duration thresholds.

**Architecture:** IdleDetector service tracks score duration, fires callbacks on state transitions, integrated into AppState's sample handling loop.

**Tech Stack:** Swift 6, @Observable, @MainActor

---

### Task 1: Create IdleDetector Service

**Files:**
- Create: `Sources/FlowState/Services/IdleDetector.swift`

**Step 1: Create the IdleDetector class**

```swift
// Sources/FlowState/Services/IdleDetector.swift
import Foundation

@MainActor
@Observable
final class IdleDetector {
    private let lowThreshold: Int = 30
    private let idleTriggerDuration: TimeInterval = 10.0
    private let recoveryDuration: TimeInterval = 5.0

    private var belowThresholdSince: Date?
    private var aboveThresholdSince: Date?

    private(set) var isIdle: Bool = false

    var onIdleStart: (() -> Void)?
    var onIdleEnd: (() -> Void)?

    func update(score: Int) {
        let now = Date()

        if score < lowThreshold {
            // Below threshold
            aboveThresholdSince = nil

            if belowThresholdSince == nil {
                belowThresholdSince = now
            }

            // Check if we should trigger idle
            if !isIdle,
               let since = belowThresholdSince,
               now.timeIntervalSince(since) >= idleTriggerDuration {
                isIdle = true
                onIdleStart?()
            }
        } else {
            // Above threshold
            belowThresholdSince = nil

            if aboveThresholdSince == nil {
                aboveThresholdSince = now
            }

            // Check if we should clear idle
            if isIdle,
               let since = aboveThresholdSince,
               now.timeIntervalSince(since) >= recoveryDuration {
                isIdle = false
                onIdleEnd?()
            }
        }
    }

    func reset() {
        belowThresholdSince = nil
        aboveThresholdSince = nil
        isIdle = false
    }
}
```

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add .
git commit -m "feat: add IdleDetector service for auto-trigger logic"
```

---

### Task 2: Integrate IdleDetector into AppState

**Files:**
- Modify: `Sources/FlowState/AppState.swift`

**Step 1: Add IdleDetector and wire callbacks**

Add to AppState:

```swift
let idleDetector = IdleDetector()
```

Update the `start()` method to wire callbacks:

```swift
func start() {
    guard !hasStarted else { return }
    hasStarted = true

    // Wire idle detector callbacks
    idleDetector.onIdleStart = { [weak self] in
        self?.tintController.show()
    }
    idleDetector.onIdleEnd = { [weak self] in
        self?.tintController.hide()
    }

    permissionChecker.startPolling()

    if permissionChecker.hasPermission {
        startMonitoring()
    }
}
```

Update `handleSample` to notify IdleDetector:

```swift
private func handleSample(_ sample: ActivitySample) {
    lastKeystrokeCount = sample.keystrokes
    lastMouseDistance = sample.mouseDistance
    focusEngine.processSample(sample)

    // Notify idle detector of score change
    idleDetector.update(score: focusEngine.currentScore)
}
```

**Step 2: Update manual tint controls**

Update `clearTint()` to also reset idle detector:

```swift
func clearTint() {
    tintController.hide()
    idleDetector.reset()  // Prevent immediate re-trigger
}
```

**Step 3: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 4: Commit**

```bash
git add .
git commit -m "feat: integrate IdleDetector into AppState for auto-tinting"
```

---

### Task 3: Test and Verify

**Step 1: Build and run**

Run: `swift build && swift run`

**Step 2: Manual testing**

1. Leave computer idle for 10+ seconds → Screen should start tinting
2. Start typing/moving mouse → After 5 seconds of activity, tint should clear
3. Click "Clear Tint" manually → Should clear and not immediately re-trigger

**Step 3: Commit and push**

```bash
git add .
git commit -m "feat: complete auto-trigger tinting feature"
git push origin main
```

---

## Testing Checklist

- [ ] Tint starts after 10 seconds of low focus score
- [ ] Tint clears after 5 seconds of activity/high score
- [ ] Manual "Clear Tint" resets the detector
- [ ] Manual "Test Tint" still works
- [ ] No flickering during brief pauses
