# Technical Requirements Document

## 🧭 System Context
FlowState is a macOS menu bar application built with SwiftUI 6 and Swift 6 that provides adaptive Pomodoro-style focus sessions. It monitors user activity via DeviceActivity framework to intelligently extend work sessions, displays focus intensity through menu bar Live Activity brightness, and provides subtle break notifications via screen edge desaturation/vignetting using Accessibility APIs. The app runs without a dock icon, supports global keyboard shortcuts, and can launch at login.

## 🔌 API Contracts
### TimerService
- **Method:** INTERNAL
- **Description:** _Not specified_

### ActivityMonitorService
- **Method:** INTERNAL
- **Description:** _Not specified_

### FocusScoreEngine
- **Method:** INTERNAL
- **Description:** _Not specified_

### ScreenTintController
- **Method:** INTERNAL
- **Description:** _Not specified_

### GlobalShortcutHandler
- **Method:** INTERNAL
- **Description:** _Not specified_

### LoginItemManager
- **Method:** INTERNAL
- **Description:** _Not specified_

### SessionHistoryStore
- **Method:** INTERNAL
- **Description:** _Not specified_

## 🧱 Modules
### FlowStateApp
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

### AppState
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

### TimerService
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

### ActivityMonitorService
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

### FocusScoreEngine
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

### ScreenTintController
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

### MenuBarView
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

### SettingsView
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

### GlobalShortcutHandler
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

### LoginItemManager
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

### UserPreferences
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

### SessionHistoryStore
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

## 🗃 Data Model Notes
### Unknown Entity
_None_

### Unknown Entity
_None_

### Unknown Entity
_None_

### Unknown Entity
_None_

### Unknown Entity
_None_

### Unknown Entity
_None_

### Unknown Entity
_None_

### Unknown Entity
_None_

## 🔐 Validation & Security
- **Rule:** _Not specified_
- **Rule:** _Not specified_
- **Rule:** _Not specified_
- **Rule:** _Not specified_
- **Rule:** _Not specified_
- **Rule:** _Not specified_
- **Rule:** _Not specified_
- **Rule:** _Not specified_

## 🧯 Error Handling Strategy
Swift 6 typed throws where possible. All service methods return Result types or throw specific error enums. UI surfaces errors via transient menu bar status or alert in Settings. Permission denials show inline guidance with 'Open System Settings' button. Activity monitoring failures silently fall back to timer-only mode with user notification. Screen tinting failures fall back to menu bar glow only. Errors logged to os_log subsystem 'com.flowstate.app' for Console debugging.

## 🔭 Observability
- **Logging:** Unified Logging (os_log) with categories: timer, activity, focus, tint, shortcuts, lifecycle. Debug level for metric samples, Info for state transitions, Error for failures. Logs viewable in Console.app filtered by subsystem.
- **Tracing:** Not applicable for local-only app. State transitions logged with timestamps for debugging session replays.
- **Metrics:**
- Session completion rate (completed / started)
- Average focus score per session
- Extension frequency (extensions / session)
- Permission grant rate on first launch
- Feature usage: vignette enabled %, shortcuts configured %

## ⚡ Performance Notes
- **Metric:** _Not specified_
- **Metric:** _Not specified_
- **Metric:** _Not specified_
- **Metric:** _Not specified_
- **Metric:** _Not specified_
- **Metric:** _Not specified_
- **Metric:** _Not specified_
- **Metric:** _Not specified_

## 🧪 Testing Strategy
### Unit
- FocusScoreEngine: Test score calculation with known inputs, verify thresholds trigger correct recommendations
- TimerService: Test state machine transitions, pause/resume, extension logic, persistence/recovery
- UserPreferences: Test default values, migration from older schema versions
- SessionHistoryStore: Test save/load/query with mock file system
### Integration
- AppState + TimerService + FocusScoreEngine: Verify auto-extension triggers correctly
- ScreenTintController + real display: Verify overlay appears and animates (manual verification)
- GlobalShortcutHandler: Test registration/callback with simulated key events where possible
- LoginItemManager: Test enable/disable reflects in SMAppService status
### E2E
- Full session flow: Start timer -> simulate high focus metrics -> verify extension -> complete -> verify history saved
- Permission flow: Fresh launch -> deny permissions -> verify graceful degradation -> grant -> verify features activate
- Settings flow: Change all preferences -> restart app -> verify persistence
- Menu bar interaction: Click to open -> start/pause/stop via menu -> verify state reflected

## 🚀 Rollout Plan
### Phase
_Not specified_

### Phase
_Not specified_

### Phase
_Not specified_

### Phase
_Not specified_

### Phase
_Not specified_

### Phase
_Not specified_

### Phase
_Not specified_

## ❓ Open Questions
- DeviceActivity framework availability: Is it accessible for non-Screen Time use cases or is FamilyControls entitlement required? May need fallback to IOKit HID event monitoring.
- Screen overlay approach: Should we use NSPanel with .nonactivatingPanel collection behavior or create CGDisplayStream-based overlay? Need to test on external displays and different macOS versions.
- App Store sandbox: Will Accessibility APIs for screen tinting pass App Store review? May need to ship notarized-only for full feature set.
- Focus score algorithm: Should we incorporate focused app lists (user-defined productive apps) into scoring? Adds complexity but improves accuracy.
- Break reminder escalation: If user ignores desaturation, should we escalate to more prominent notification? Risk of becoming annoying like competitors.