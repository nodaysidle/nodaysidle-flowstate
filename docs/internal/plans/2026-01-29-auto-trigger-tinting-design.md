# Auto-Trigger Tinting Design

**Goal:** Automatically trigger screen tinting when user becomes idle/unfocused, and clear it when focus returns.

## Trigger Logic

- **Tint STARTS** when focus score stays below 30 for 10 consecutive seconds
- **Tint CLEARS** when focus score stays above 30 for 5 consecutive seconds

## State Machine

```
[Focused] --score<30 for 10s--> [Tinting]
[Tinting] --score>30 for 5s--> [Focused]
```

## Implementation Approach

### New Component: IdleDetector

A service that:
- Receives focus score updates
- Tracks duration below/above threshold
- Fires callbacks when state transitions occur

### Integration

- AppState owns IdleDetector
- On each focus score update, AppState notifies IdleDetector
- IdleDetector triggers tint show/hide via AppState methods

### Manual Override

- Keep "Test Tint" and "Clear Tint" buttons for debugging
- Manual clear could set a cooldown to prevent immediate re-trigger

## Configuration (hardcoded for now)

| Setting | Value |
|---------|-------|
| Low threshold | 30 |
| Idle trigger duration | 10 seconds |
| Recovery duration | 5 seconds |
