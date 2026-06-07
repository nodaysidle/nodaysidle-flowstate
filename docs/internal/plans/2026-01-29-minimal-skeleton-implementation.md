# FlowState Minimal Skeleton Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a macOS menu bar app that monitors keyboard/mouse activity and displays a real-time focus score (0-100).

**Architecture:** SwiftUI 6 app with MenuBarExtra, IOKit HID event monitoring via actor-isolated service, @Observable focus score engine with hybrid decay algorithm.

**Tech Stack:** Swift 6, SwiftUI, IOKit, macOS 14+

---

### Task 1: Create Swift Package Structure

**Files:**
- Create: `Package.swift`
- Create: `Sources/FlowState/FlowStateApp.swift`
- Create: `Sources/FlowState/Info.plist`

**Step 1: Create Package.swift**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FlowState",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "FlowState",
            resources: [
                .process("Info.plist")
            ]
        )
    ]
)
```

**Step 2: Create minimal app entry point**

```swift
// Sources/FlowState/FlowStateApp.swift
import SwiftUI

@main
struct FlowStateApp: App {
    var body: some Scene {
        MenuBarExtra("FlowState", systemImage: "brain.head.profile") {
            Text("FlowState")
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
```

**Step 3: Create Info.plist for LSUIElement (no dock icon)**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleName</key>
    <string>FlowState</string>
    <key>CFBundleIdentifier</key>
    <string>com.flowstate.app</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
</dict>
</plist>
```

**Step 4: Build and run to verify menu bar presence**

Run: `swift build && swift run`
Expected: App icon appears in menu bar, no dock icon, dropdown shows "FlowState" and Quit button

**Step 5: Commit**

```bash
git add .
git commit -m "feat: create SwiftUI menu bar app shell"
```

---

### Task 2: Create ActivitySample Model

**Files:**
- Create: `Sources/FlowState/Models/ActivitySample.swift`

**Step 1: Create the model**

```swift
// Sources/FlowState/Models/ActivitySample.swift
import Foundation

struct ActivitySample: Sendable {
    let keystrokes: Int
    let mouseDistance: Double
    let timestamp: Date

    init(keystrokes: Int = 0, mouseDistance: Double = 0, timestamp: Date = .now) {
        self.keystrokes = keystrokes
        self.mouseDistance = mouseDistance
        self.timestamp = timestamp
    }
}
```

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds with no errors

**Step 3: Commit**

```bash
git add .
git commit -m "feat: add ActivitySample model"
```

---

### Task 3: Create FocusScoreEngine

**Files:**
- Create: `Sources/FlowState/Services/FocusScoreEngine.swift`
- Create: `Tests/FlowStateTests/FocusScoreEngineTests.swift`
- Modify: `Package.swift` (add test target)

**Step 1: Update Package.swift to include tests**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FlowState",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "FlowState",
            resources: [
                .process("Info.plist")
            ]
        ),
        .testTarget(
            name: "FlowStateTests",
            dependencies: ["FlowState"]
        )
    ]
)
```

**Step 2: Write failing tests for score calculation**

```swift
// Tests/FlowStateTests/FocusScoreEngineTests.swift
import Testing
@testable import FlowState

@Suite("FocusScoreEngine Tests")
struct FocusScoreEngineTests {

    @Test("No activity produces zero score")
    func noActivityZeroScore() async {
        let engine = FocusScoreEngine()
        let sample = ActivitySample(keystrokes: 0, mouseDistance: 0)
        await engine.processSample(sample)
        let score = await engine.currentScore
        #expect(score == 0)
    }

    @Test("Heavy typing produces high score")
    func heavyTypingHighScore() async {
        let engine = FocusScoreEngine()
        let sample = ActivitySample(keystrokes: 10, mouseDistance: 50)
        await engine.processSample(sample)
        let score = await engine.currentScore
        #expect(score >= 70)
    }

    @Test("Heavy mouse use reduces score")
    func heavyMouseReducesScore() async {
        let engine = FocusScoreEngine()
        let sample = ActivitySample(keystrokes: 5, mouseDistance: 600)
        await engine.processSample(sample)
        let score = await engine.currentScore
        #expect(score < 50)
    }

    @Test("Score decays over time without activity")
    func scoreDecaysWithoutActivity() async {
        let engine = FocusScoreEngine()
        // First, build up a score
        let activeSample = ActivitySample(keystrokes: 10, mouseDistance: 0)
        await engine.processSample(activeSample)
        let initialScore = await engine.currentScore

        // Then send idle samples
        let idleSample = ActivitySample(keystrokes: 0, mouseDistance: 0)
        for _ in 0..<10 {
            await engine.processSample(idleSample)
        }
        let decayedScore = await engine.currentScore

        #expect(decayedScore < initialScore)
    }
}
```

**Step 3: Run tests to verify they fail**

Run: `swift test`
Expected: FAIL - FocusScoreEngine not found

**Step 4: Implement FocusScoreEngine**

```swift
// Sources/FlowState/Services/FocusScoreEngine.swift
import Foundation
import Observation

@Observable
@MainActor
final class FocusScoreEngine {
    private(set) var currentScore: Int = 0
    private var previousScore: Double = 0

    private let decayFactor: Double = 0.977 // ~30 second half-life at 1 sample/sec

    func processSample(_ sample: ActivitySample) {
        let instantScore = calculateInstantScore(sample)

        // Hybrid decay: fast up, slow down
        let decayedPrevious = previousScore * decayFactor
        let newScore = max(Double(instantScore), decayedPrevious)

        previousScore = newScore
        currentScore = Int(newScore.rounded())
    }

    private func calculateInstantScore(_ sample: ActivitySample) -> Int {
        // Keyboard contribution (0-70 points)
        let keyboardScore: Int
        switch sample.keystrokes {
        case 0:
            keyboardScore = 0
        case 1...3:
            keyboardScore = 30
        case 4...8:
            keyboardScore = 50
        default:
            keyboardScore = 70
        }

        // Mouse penalty (0 to -20 points)
        let mousePenalty: Int
        switch sample.mouseDistance {
        case ..<100:
            mousePenalty = 0
        case 100..<500:
            mousePenalty = -10
        default:
            mousePenalty = -20
        }

        // Idle bonus (0-10 points) for pure typing focus
        let idleBonus = (sample.keystrokes > 0 && sample.mouseDistance < 100) ? 10 : 0

        let total = keyboardScore + mousePenalty + idleBonus
        return max(0, min(100, total))
    }

    func reset() {
        currentScore = 0
        previousScore = 0
    }
}
```

**Step 5: Run tests to verify they pass**

Run: `swift test`
Expected: All 4 tests PASS

**Step 6: Commit**

```bash
git add .
git commit -m "feat: add FocusScoreEngine with hybrid decay algorithm"
```

---

### Task 4: Create AccessibilityPermissionChecker

**Files:**
- Create: `Sources/FlowState/Services/AccessibilityPermissionChecker.swift`

**Step 1: Create permission checker**

```swift
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
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
```

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add .
git commit -m "feat: add AccessibilityPermissionChecker"
```

---

### Task 5: Create ActivityMonitorService

**Files:**
- Create: `Sources/FlowState/Services/ActivityMonitorService.swift`

**Step 1: Create the activity monitor using IOKit**

```swift
// Sources/FlowState/Services/ActivityMonitorService.swift
import Foundation
import Cocoa
import IOKit.hid

actor ActivityMonitorService {
    private var hidManager: IOHIDManager?
    private var keystrokeCount: Int = 0
    private var mouseDistance: Double = 0
    private var lastMouseLocation: CGPoint?

    private var sampleCallback: (@Sendable (ActivitySample) -> Void)?
    private var sampleTimer: Timer?

    var isRunning: Bool {
        hidManager != nil
    }

    func start(onSample: @escaping @Sendable (ActivitySample) -> Void) {
        guard hidManager == nil else { return }

        sampleCallback = onSample

        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))

        guard let manager = hidManager else { return }

        // Match keyboard and mouse devices
        let keyboardCriteria: [String: Any] = [
            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Keyboard
        ]

        let mouseCriteria: [String: Any] = [
            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Mouse
        ]

        IOHIDManagerSetDeviceMatchingMultiple(manager, [keyboardCriteria, mouseCriteria] as CFArray)

        // Set up input callback
        let callback: IOHIDValueCallback = { context, result, sender, value in
            guard let context = context else { return }
            let service = Unmanaged<ActivityMonitorService>.fromOpaque(context).takeUnretainedValue()

            let element = IOHIDValueGetElement(value)
            let usagePage = IOHIDElementGetUsagePage(element)

            Task {
                if usagePage == kHIDPage_KeyboardOrKeypad {
                    await service.recordKeystroke()
                }
            }
        }

        let unmanagedSelf = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterInputValueCallback(manager, callback, unmanagedSelf)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))

        // Start mouse tracking and sampling timer on main thread
        Task { @MainActor in
            self.startTimers()
        }
    }

    @MainActor
    private func startTimers() {
        // Mouse tracking via CGEvent
        NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return }
            Task {
                await self.recordMouseMove(to: event.locationInWindow)
            }
        }

        // Sample timer - collect and emit samples every second
        sampleTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.emitSample()
            }
        }
    }

    private func recordKeystroke() {
        keystrokeCount += 1
    }

    private func recordMouseMove(to point: CGPoint) {
        if let last = lastMouseLocation {
            let dx = point.x - last.x
            let dy = point.y - last.y
            mouseDistance += sqrt(dx * dx + dy * dy)
        }
        lastMouseLocation = point
    }

    private func emitSample() {
        let sample = ActivitySample(
            keystrokes: keystrokeCount,
            mouseDistance: mouseDistance
        )

        // Reset counters
        keystrokeCount = 0
        mouseDistance = 0

        // Emit sample
        sampleCallback?(sample)
    }

    func stop() {
        if let manager = hidManager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            hidManager = nil
        }
        sampleTimer?.invalidate()
        sampleTimer = nil
        sampleCallback = nil
    }
}
```

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds (may have warnings about Sendable, acceptable for now)

**Step 3: Commit**

```bash
git add .
git commit -m "feat: add ActivityMonitorService with IOKit HID monitoring"
```

---

### Task 6: Create MenuBarDropdown View

**Files:**
- Create: `Sources/FlowState/Views/MenuBarDropdown.swift`

**Step 1: Create the dropdown view**

```swift
// Sources/FlowState/Views/MenuBarDropdown.swift
import SwiftUI

struct MenuBarDropdown: View {
    let focusScore: Int
    let hasPermission: Bool
    let keystrokesActive: Bool
    let mouseActive: Bool
    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if hasPermission {
                scoreView
            } else {
                permissionRequestView
            }

            Divider()

            Button("Quit FlowState") {
                onQuit()
            }
        }
        .padding()
        .frame(width: 220)
    }

    private var scoreView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Focus Score")
                .font(.headline)

            HStack {
                ProgressView(value: Double(focusScore), total: 100)
                    .progressViewStyle(.linear)

                Text("\(focusScore)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .frame(width: 40, alignment: .trailing)
            }

            HStack(spacing: 16) {
                Label(
                    keystrokesActive ? "Keyboard: Active" : "Keyboard: Idle",
                    systemImage: keystrokesActive ? "keyboard.fill" : "keyboard"
                )
                .foregroundColor(keystrokesActive ? .green : .secondary)

                Label(
                    mouseActive ? "Mouse: Active" : "Mouse: Idle",
                    systemImage: mouseActive ? "computermouse.fill" : "computermouse"
                )
                .foregroundColor(mouseActive ? .orange : .secondary)
            }
            .font(.caption)
        }
    }

    private var permissionRequestView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Accessibility Access Required", systemImage: "lock.shield")
                .font(.headline)

            Text("FlowState needs Accessibility access to monitor keyboard and mouse activity for focus detection.")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Open System Settings") {
                onOpenSettings()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview("With Permission") {
    MenuBarDropdown(
        focusScore: 78,
        hasPermission: true,
        keystrokesActive: true,
        mouseActive: false,
        onOpenSettings: {},
        onQuit: {}
    )
}

#Preview("Without Permission") {
    MenuBarDropdown(
        focusScore: 0,
        hasPermission: false,
        keystrokesActive: false,
        mouseActive: false,
        onOpenSettings: {},
        onQuit: {}
    )
}
```

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add .
git commit -m "feat: add MenuBarDropdown view"
```

---

### Task 7: Wire Everything Together in FlowStateApp

**Files:**
- Modify: `Sources/FlowState/FlowStateApp.swift`
- Create: `Sources/FlowState/AppState.swift`

**Step 1: Create AppState to coordinate services**

```swift
// Sources/FlowState/AppState.swift
import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    let focusEngine = FocusScoreEngine()
    let permissionChecker = AccessibilityPermissionChecker()
    let activityMonitor = ActivityMonitorService()

    private(set) var lastKeystrokeCount: Int = 0
    private(set) var lastMouseDistance: Double = 0

    var keystrokesActive: Bool { lastKeystrokeCount > 0 }
    var mouseActive: Bool { lastMouseDistance > 50 }

    func start() {
        permissionChecker.startPolling()

        if permissionChecker.hasPermission {
            startMonitoring()
        }
    }

    func startMonitoring() {
        Task {
            await activityMonitor.start { [weak self] sample in
                Task { @MainActor in
                    self?.handleSample(sample)
                }
            }
        }
    }

    func stopMonitoring() {
        Task {
            await activityMonitor.stop()
        }
    }

    private func handleSample(_ sample: ActivitySample) {
        lastKeystrokeCount = sample.keystrokes
        lastMouseDistance = sample.mouseDistance
        focusEngine.processSample(sample)
    }
}
```

**Step 2: Update FlowStateApp to use AppState**

```swift
// Sources/FlowState/FlowStateApp.swift
import SwiftUI

@main
struct FlowStateApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("FlowState", systemImage: "brain.head.profile") {
            MenuBarDropdown(
                focusScore: appState.focusEngine.currentScore,
                hasPermission: appState.permissionChecker.hasPermission,
                keystrokesActive: appState.keystrokesActive,
                mouseActive: appState.mouseActive,
                onOpenSettings: {
                    appState.permissionChecker.openSystemSettings()
                },
                onQuit: {
                    NSApplication.shared.terminate(nil)
                }
            )
            .onChange(of: appState.permissionChecker.hasPermission) { _, hasPermission in
                if hasPermission {
                    appState.startMonitoring()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }

    init() {
        Task { @MainActor in
            appState.start()
        }
    }
}
```

**Step 3: Build and run full integration test**

Run: `swift build && swift run`
Expected:
- App appears in menu bar with brain icon
- No dock icon
- Clicking shows dropdown
- If no Accessibility permission: shows permission request with button
- If permission granted: shows focus score updating as you type

**Step 4: Commit**

```bash
git add .
git commit -m "feat: wire up AppState and complete minimal skeleton

Integrates ActivityMonitorService, FocusScoreEngine, and
MenuBarDropdown into working menu bar app."
```

**Step 5: Push to GitHub**

```bash
git push origin main
```

---

## Testing Checklist

After all tasks complete, manually verify:

- [ ] App appears in menu bar only (no dock icon)
- [ ] Permission request shows if Accessibility not granted
- [ ] "Open System Settings" button works
- [ ] After granting permission, score display appears
- [ ] Score increases during sustained typing
- [ ] Score decreases slowly when idle
- [ ] Keyboard/Mouse activity indicators update
- [ ] Quit button terminates app cleanly

---

## Next Steps (Post-Skeleton)

After skeleton is validated:
1. Add timer functionality with auto-extension
2. Implement menu bar icon glow based on score
3. Add screen tinting for break notifications
4. Settings UI for customization
