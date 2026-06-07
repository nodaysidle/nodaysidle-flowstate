# Screen Tinting Design

**Date:** 2026-01-29
**Status:** Approved

## Overview

A transparent overlay that applies gradual desaturation to the screen as a "peripheral nudge" for break reminders. This implementation focuses on the visual mechanism with manual triggers; timer integration comes later.

## Scope

### What we're building:
1. **ScreenTintOverlay** - NSPanel-based transparent window with CIFilter desaturation
2. **ScreenTintController** - Manages overlay lifecycle and animation
3. **Updated MenuBarDropdown** - Test Tint / Clear Tint buttons

### What we're NOT building yet:
- Timer integration (trigger)
- Vignette effect
- Multi-display support
- Settings for duration/intensity

### Success criteria:
- "Test Tint" starts 30-second gradual desaturation
- Screen transitions smoothly from full color to grayscale
- All mouse/keyboard input passes through overlay
- "Clear Tint" instantly removes effect
- Covers main display only

## Architecture

### New files:
```
Sources/FlowState/Services/ScreenTintController.swift
Sources/FlowState/Views/ScreenTintOverlay.swift
```

### Modified files:
```
Sources/FlowState/AppState.swift
Sources/FlowState/Views/MenuBarDropdown.swift
```

### Data flow:
```
MenuBarDropdown "Test Tint" → AppState.startTint() → ScreenTintController.show()
                                                            ↓
                                               ScreenTintOverlay appears
                                                            ↓
                                               30s animation: color → grayscale
                                                            ↓
MenuBarDropdown "Clear Tint" → AppState.clearTint() → ScreenTintController.hide()
                                                            ↓
                                               Overlay removed instantly
```

## ScreenTintOverlay Implementation

### NSPanel configuration:
- `styleMask: .borderless` - no window chrome
- `level: .screenSaver` - above all windows
- `collectionBehavior: .canJoinAllSpaces` - visible on all spaces
- `ignoresMouseEvents: true` - click-through
- `backgroundColor: .clear` - transparent

### Desaturation:
- Use `CIColorControls` filter with `inputSaturation` parameter
- `inputSaturation = 1.0` → full color (hidden state)
- `inputSaturation = 0.0` → full grayscale (visible state)

### Animation:
- CABasicAnimation on saturation value
- Duration: 30 seconds
- Timing: ease-in
- Direction: 1.0 → 0.0

### Dismiss:
- Instant removal, no fade-out

## UI Changes

### MenuBarDropdown (when permission granted):
```
┌─────────────────────────────┐
│  Focus Score                │
│      ████████░░  78         │
│                             │
│  ● Keyboard: Active         │
│  ○ Mouse: Idle              │
│                             │
│  ─────────────────────────  │
│                             │
│  [Test Tint]  [Clear Tint]  │
│                             │
│  ─────────────────────────  │
│  Quit FlowState             │
└─────────────────────────────┘
```

### New MenuBarDropdown properties:
```swift
let isTinting: Bool
let onTestTint: () -> Void
let onClearTint: () -> Void
```

## Future Enhancements

- Wire to timer (tint when work session ends)
- Add vignette effect option
- Multi-display support
- Configurable animation duration
- Configurable intensity
