# FlowState Minimal Skeleton Design

**Date:** 2026-01-29
**Status:** Approved

## Overview

A macOS menu bar app that monitors keyboard/mouse activity and displays a real-time focus score (0-100). This skeleton proves the core innovation of FlowState before layering on timer, screen tinting, and other features.

## Scope

### What we're building:
1. **Menu bar shell** - SwiftUI app with `MenuBarExtra`, no dock icon
2. **ActivityMonitorService** - IOKit HID event listener for keyboard/mouse
3. **FocusScoreEngine** - Converts activity data to 0-100 score using hybrid decay
4. **Simple dropdown UI** - Shows current focus score and activity status

### What we're NOT building yet:
- Timer functionality
- Screen tinting/vignetting
- Menu bar glow animation
- Session history
- Settings UI
- Global shortcuts

### Success criteria:
- App runs in menu bar only
- Requests Accessibility permission with clear explanation
- Focus score rises during sustained typing
- Focus score decays slowly during brief pauses
- Score drops more during mouse-heavy activity

## Architecture

### Project structure:

```
FlowState/
├── FlowStateApp.swift          # App entry, MenuBarExtra setup
├── Services/
│   ├── ActivityMonitorService.swift   # IOKit HID event monitoring
│   └── FocusScoreEngine.swift         # Score calculation
├── Views/
│   └── MenuBarDropdown.swift          # Dropdown UI showing score
└── Models/
    └── ActivitySample.swift           # Data structure for activity events
```

### Data flow:

```
IOKit HID Events
      ↓
ActivityMonitorService (samples every 1 second)
      ↓
ActivitySample { keystrokes: Int, mouseMovements: Int, timestamp: Date }
      ↓
FocusScoreEngine (maintains rolling window, calculates score)
      ↓
Published focusScore: Int (0-100)
      ↓
MenuBarDropdown (displays score via SwiftUI binding)
```

### Concurrency model:
- `ActivityMonitorService` is an `actor` to safely handle HID callbacks
- `FocusScoreEngine` is `@Observable` for SwiftUI reactivity
- All async work uses Swift 6 structured concurrency (no Combine)

### Permission handling:
- Check Accessibility permission on launch
- If denied, show guidance in dropdown with "Open System Settings" button
- If granted, start monitoring immediately

## Focus Score Algorithm

### Inputs (sampled every 1 second):
- `keystrokes`: Number of key events in the last second
- `mouseDistance`: Pixels of mouse movement in the last second

### Scoring logic:

```
Keyboard contribution (0-70 points):
- 0 keystrokes = 0 points
- 1-3 keystrokes = 30 points (light typing)
- 4-8 keystrokes = 50 points (moderate typing)
- 9+ keystrokes = 70 points (sustained typing)

Mouse penalty (0 to -20 points):
- < 100 pixels = 0 penalty (minimal movement)
- 100-500 pixels = -10 penalty (moderate movement)
- > 500 pixels = -20 penalty (heavy mouse use)

Idle bonus (0-10 points):
- If keystrokes > 0 and mouse < 100px = +10 (pure typing focus)
```

### Hybrid decay (fast up, slow down):
- Score increases: Immediate (new sample directly affects score)
- Score decreases: Exponential decay with 30-second half-life
- Formula: `displayedScore = max(instantScore, previousScore * 0.977)`
- The 0.977 factor means score halves roughly every 30 seconds of inactivity

### Thresholds (for future use):
- 0-30: Low focus (browsing, distracted)
- 31-60: Moderate focus (mixed activity)
- 61-80: High focus (productive work)
- 81-100: Deep focus (flow state)

## UI Design

### Permission request state:

```
┌─────────────────────────────┐
│  FlowState needs            │
│  Accessibility access       │
│                             │
│  This allows monitoring     │
│  keyboard and mouse to      │
│  detect focus intensity.    │
│                             │
│  [Open System Settings]     │
└─────────────────────────────┘
```

### Normal operation:

```
┌─────────────────────────────┐
│  Focus Score                │
│                             │
│      ████████░░  78         │
│                             │
│  ● Keyboard: Active         │
│  ○ Mouse: Idle              │
│                             │
│  ─────────────────────────  │
│  Quit FlowState             │
└─────────────────────────────┘
```

## Implementation Plan

### Build order:

1. **Project setup** - Create Swift Package with macOS 14+ target, configure `LSUIElement`
2. **Menu bar shell** - `FlowStateApp.swift` with `MenuBarExtra`, placeholder dropdown
3. **ActivitySample model** - Simple struct with keystrokes, mouseDistance, timestamp
4. **ActivityMonitorService** - IOKit HID tap setup, Accessibility permission check
5. **FocusScoreEngine** - Score calculation with hybrid decay, `@Observable`
6. **Wire it together** - Connect service → engine → UI

### Estimated scope:
- ~6-8 files
- ~400-500 lines of code

### Key risks:
- IOKit HID monitoring requires precise setup
- Accessibility permission detection needs polling fallback

## Future Enhancements (Post-Skeleton)

- Timer with auto-extension based on focus score
- Menu bar icon glow intensity
- Screen tinting/vignetting for break reminders
- Focus profiles (keyboard-heavy vs mouse-heavy work)
- Session history and analytics
- Global keyboard shortcuts
