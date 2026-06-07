# Menu Bar Icon Design

**Goal:** Show focus level at a glance via menu bar icon without opening dropdown.

## Visual States

| Score Range | Icon | State |
|-------------|------|-------|
| 0-33 | `circle` | Low focus |
| 34-66 | `circle.bottomhalf.filled` | Medium focus |
| 67-100 | `circle.fill` | High focus |

## Implementation

- Computed property in AppState returns icon name based on `focusEngine.currentScore`
- FlowStateApp binds MenuBarExtra's systemImage to this property
- Updates reactively via @Observable

## Design Rationale

- **Minimal** - Simple circle is unobtrusive for developers
- **Glanceable** - Instant read without interpretation
- **Native** - Uses SF Symbols, looks like system indicator
- **Subtle** - Matches app philosophy of gentle cues
