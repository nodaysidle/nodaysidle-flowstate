# ML Break Prediction Design

**Goal:** Learn user's work rhythm and suggest optimal breaks using on-device Core ML.

## Data Collection

**Activity Samples:**
- Timestamp
- Keystroke count
- Mouse distance
- Focus score

**Session Records (training data):**
- Session start time
- Session duration
- Average focus score
- Activity trend (rising/falling)
- Time of day
- Outcome: natural break vs forced break vs ignored suggestion

## Core ML Model

**Type:** Tabular classifier (binary: suggest break or not)

**Input Features:**
- Current session duration (minutes)
- Average focus score this session
- Recent activity trend (last 5 min vs session avg)
- Time of day (hour)
- Day of week

**Output:**
- Probability of needing break (0.0 - 1.0)
- Suggest break when probability > 0.7

**On-Device Learning:**
- Start with baseline model (suggest break after 45-60 min)
- Update model when user takes/ignores suggestion
- Use `MLUpdateTask` for incremental learning

## Components

### ActivityDataStore
- Stores activity samples to JSON file
- Keeps rolling window (last 7 days)
- Provides query methods for training data

### SessionTracker
- Detects session start (score rises above 50)
- Detects session end (idle triggered)
- Records session with all features
- Feeds completed sessions to model training

### BreakPredictor
- Loads Core ML model
- Runs inference every minute during active session
- Triggers break suggestion via callback
- Handles model updates based on outcomes

### Menu Bar Integration
- Normal: liquid fill circle
- Break suggested: circle with pause icon overlay
- Clears on idle (break taken) or manual dismiss

## Learning Loop

```
User starts working
    ↓
SessionTracker detects session start
    ↓
BreakPredictor runs inference every minute
    ↓
Model says "suggest break" (probability > 0.7)
    ↓
Menu bar icon changes to break indicator
    ↓
User either:
  - Takes break (idle) → positive feedback
  - Ignores and keeps working → negative feedback
  - Dismisses suggestion → neutral
    ↓
Model updates with outcome
    ↓
Cycle repeats, model improves
```

## Initial Baseline

Before enough data collected:
- Suggest break after 50 minutes of sustained focus
- Adjust based on user's first few sessions
