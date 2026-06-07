# FlowState - Code Map

## Responsibility
**FlowState** is a macOS menu bar app that monitors user activity to estimate focus, surface break suggestions, and control a subtle screen tint when activity drops.

It is intentionally lightweight in v1:
- activity sampling
- heuristic focus scoring
- idle detection
- break suggestion hints
- local session persistence

## Tech Stack
- **Platform**: macOS 14+ (Sonoma)
- **Build**: Swift Package Manager (SPM)
- **UI**: SwiftUI with `MenuBarExtra`
- **Concurrency**: Swift 6 strict concurrency (`@Observable`, actors)
- **Storage**: `ActivityDataStore` + local persisted preferences

## Design Patterns

### Architecture: Centralized State + Service Actors
- `AppState` is the central `@Observable` coordinator.
- Services are owned by `AppState` and communicate through callbacks / state updates.
- Views are thin and render the current state.

### Service Layer
- `ActivityMonitorService` (actor): keyboard/mouse activity sampling
- `AccessibilityPermissionChecker`: polls Accessibility permission state
- `FocusScoreEngine`: calculates a 0–100 focus score
- `IdleDetector`: detects idle / recovery states
- `SessionTracker`: tracks session lifecycle and statistics
- `BreakPredictor`: heuristic break suggestion logic
- `ScreenTintController`: controls the tint overlay
- `ActivityDataStore`: persists session history

### Communication Patterns
- `ActivityMonitorService` emits `ActivitySample` values every second.
- `AppState.handleSample(_:)` updates the focus engine, idle detector, session tracker, and break predictor.
- `BreakPredictor` notifies `AppState` when a break should be suggested.
- `AccessibilityPermissionChecker` gates whether monitoring starts.

## Key Modules

| Module | Path | Responsibility |
|--------|------|----------------|
| FlowStateApp | `Sources/FlowState/FlowStateApp.swift` | App entry, `MenuBarExtra`, Settings scene |
| AppState | `Sources/FlowState/AppState.swift` | Central state coordinator |
| FocusScoreEngine | `Sources/FlowState/Services/FocusScoreEngine.swift` | Focus scoring |
| ActivityMonitorService | `Sources/FlowState/Services/ActivityMonitorService.swift` | Activity sampling |
| AccessibilityPermissionChecker | `Sources/FlowState/Services/AccessibilityPermissionChecker.swift` | Permission polling |
| IdleDetector | `Sources/FlowState/Services/IdleDetector.swift` | Idle detection |
| SessionTracker | `Sources/FlowState/Services/SessionTracker.swift` | Session lifecycle |
| BreakPredictor | `Sources/FlowState/Services/BreakPredictor.swift` | Break suggestions |
| ScreenTintController | `Sources/FlowState/Services/ScreenTintController.swift` | Tint overlay orchestration |
| ActivityDataStore | `Sources/FlowState/Services/ActivityDataStore.swift` | Session persistence |
| MenuBarDropdown | `Sources/FlowState/Views/MenuBarDropdown.swift` | Menu bar popover UI |
| MenuBarIconRenderer | `Sources/FlowState/Views/MenuBarIconRenderer.swift` | Menu bar icon drawing |
| SettingsView | `Sources/FlowState/Views/SettingsView.swift` | Settings window |
| HistoryView | `Sources/FlowState/Views/HistoryView.swift` | Session history UI |
| ScreenTintOverlay | `Sources/FlowState/Views/ScreenTintOverlay.swift` | Overlay window |

## Entry Points

```
@main struct FlowStateApp: App
    └── MenuBarExtra (LSUIElement=true, no dock icon)
    └── Settings scene → SettingsView
```

### Data Flow
```
ActivityMonitorService (actor)
    ↓ ActivitySample (1/sec)
AppState.handleSample()
    ↓
FocusScoreEngine.processSample()
    ↓ focus score
IdleDetector.update(score)
SessionTracker.update(score, sample)
BreakPredictor.update(session info)
    ↓ break suggestion
MenuBarIconRenderer → menu bar icon
```

## Source Structure
```
Sources/FlowState/
├── FlowStateApp.swift
├── AppState.swift
├── Models/
│   ├── ActivitySample.swift
│   └── UserPreferences.swift
├── Services/
│   ├── ActivityMonitorService.swift
│   ├── AccessibilityPermissionChecker.swift
│   ├── FocusScoreEngine.swift
│   ├── IdleDetector.swift
│   ├── SessionTracker.swift
│   ├── BreakPredictor.swift
│   ├── ScreenTintController.swift
│   └── ActivityDataStore.swift
├── Views/
│   ├── MenuBarDropdown.swift
│   ├── MenuBarIconRenderer.swift
│   ├── ScreenTintOverlay.swift
│   ├── SettingsView.swift
│   └── HistoryView.swift
└── tests/ (XCTest target)
```
