# Menu Bar Icon Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Display dynamic menu bar icon that reflects current focus level.

**Architecture:** Computed property in AppState maps score to SF Symbol name, FlowStateApp binds to it reactively.

**Tech Stack:** SwiftUI MenuBarExtra, SF Symbols, @Observable

---

### Task 1: Add Icon Name Property to AppState

**Files:**
- Modify: `Sources/FlowState/AppState.swift`

**Step 1: Add computed property**

Add this computed property to AppState:

```swift
var menuBarIcon: String {
    let score = focusEngine.currentScore
    switch score {
    case 0...33:
        return "circle"
    case 34...66:
        return "circle.bottomhalf.filled"
    default:
        return "circle.fill"
    }
}
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add .
git commit -m "feat: add menuBarIcon computed property to AppState"
```

---

### Task 2: Update FlowStateApp to Use Dynamic Icon

**Files:**
- Modify: `Sources/FlowState/FlowStateApp.swift`

**Step 1: Update MenuBarExtra to use dynamic icon**

Change the MenuBarExtra initialization from:

```swift
MenuBarExtra("FlowState", systemImage: "brain.head.profile") {
```

To:

```swift
MenuBarExtra("FlowState", systemImage: appState.menuBarIcon) {
```

**Step 2: Build and run to test**

Run: `swift build && swift run`
Expected:
- App launches with circle icon
- As you type, icon fills up
- When idle, icon empties

**Step 3: Commit and push**

```bash
git add .
git commit -m "feat: dynamic menu bar icon based on focus level"
git push origin main
```

---

## Testing Checklist

- [ ] Icon shows empty circle when focus score is low (0-33)
- [ ] Icon shows half-filled circle at medium focus (34-66)
- [ ] Icon shows filled circle at high focus (67-100)
- [ ] Icon updates reactively as score changes
