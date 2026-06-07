<p align="center">
  <img src="docs/assets/banner.svg" alt="FlowState Banner" width="800">
</p>

<h1 align="center">FlowState</h1>

<p align="center">
  <strong>A smarter Pomodoro for developers who don't like timers</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#how-it-works">How It Works</a> •
  <a href="#installation">Installation</a> •
  <a href="#settings">Settings</a> •
  <a href="#tech-stack">Tech Stack</a>
</p>

---

## The Problem with Traditional Pomodoros

Traditional Pomodoro timers interrupt you at fixed intervals regardless of your actual focus state. You're in the zone, deep in solving a complex problem—and then *ding*, time for a break you don't need.

**FlowState is different.** It watches your actual keyboard and mouse activity, learns your work patterns, and only nudges you when you're genuinely losing focus. No arbitrary timers. No interruptions during flow.

## Features

- **Activity-Based Focus Detection** — Monitors keyboard and mouse activity to calculate a real-time focus score
- **Smart Screen Dimming** — Gently dims your screen when focus drops, creating a subtle visual cue to take a break
- **Adaptive Break Suggestions** — Uses recent session patterns and focus trends to suggest breaks when they’re actually useful
- **Liquid-Fill Menu Bar Icon** — Visualizes your current focus level with a smooth, filling indicator
- **Configurable Settings** — Fine-tune detection sensitivity, tint intensity, and break preferences
- **Privacy-First** — All processing happens on-device. No data leaves your Mac.

## How It Works

1. **Focus Score Engine** — Analyzes keyboard keystroke frequency and mouse movement patterns to generate a 0-100 focus score
2. **Idle Detection** — When your focus drops below a threshold for a sustained period, the screen gradually dims
3. **Session Tracking** — Tracks your work sessions and adapts to your recent behavior
4. **Break Suggestions** — Uses historical patterns and live focus trends to suggest breaks, not fixed timers

> Note: FlowState v1 uses adaptive heuristics, not a trained ML model, for break suggestions.

## Installation

### Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1/M2/M3/M4) or Intel Mac

### Download

Grab the latest `.dmg` from [GitHub Releases](https://github.com/nodaysidle/nodaysidle-flowstate/releases).

### Build from Source

```bash
git clone https://github.com/nodaysidle/nodaysidle-flowstate.git
cd nodaysidle-flowstate
swift build -c release
```

The built app will be in `.build/release/FlowState`.

### Grant Accessibility Permission

FlowState needs Accessibility access to monitor keyboard and mouse activity:

1. Open **System Settings → Privacy & Security → Accessibility**
2. Add FlowState to the list of allowed apps
3. Restart the app if needed

## Settings

Access settings via the menu bar dropdown → **Settings** button.

| Tab | Options |
|-----|---------|
| **Focus** | Idle threshold (20/30/40), Idle trigger duration (5/10/15/30s), Recovery time (3/5/10s) |
| **Tint** | Dimming intensity (30–80%), Fade duration (10/30/60/120s) |
| **Breaks** | Smart break suggestions on/off, Default session length (25/45/50/60/90 min) |
| **History** | Session history and stats |
| **General** | Launch at login, Version info |

## Menu Bar

The menu bar icon shows your current focus state:

- **Empty circle** — Low activity / idle
- **Filling circle** — Actively working, fill level = focus score
- **Pause icon** — Break suggestion triggered

Click the icon to see:
- Current focus score with color-coded progress bar
- Keyboard and mouse activity indicators
- Break suggestion (when active)
- Quick access to Settings and Quit

## Tech Stack

- **Swift 6** with strict concurrency
- **SwiftUI** for the settings interface
- **AppKit** for menu bar and screen overlay
- **Core Animation** for smooth tint transitions
- **Observation framework** for reactive state
- **Adaptive heuristics** for break suggestions (no external APIs)

## Architecture

```
Sources/FlowState/
├── FlowStateApp.swift              # @main app entry, MenuBarExtra, Settings scene
├── AppState.swift                  # Central @Observable state coordinator
├── Models/
│   ├── ActivitySample.swift        # Activity snapshot model
│   └── UserPreferences.swift       # Persisted app preferences
├── Services/
│   ├── ActivityMonitorService.swift      # Keyboard/mouse activity sampling
│   ├── AccessibilityPermissionChecker.swift # Accessibility permission polling
│   ├── FocusScoreEngine.swift            # Focus score calculation
│   ├── IdleDetector.swift                # Idle state detection
│   ├── SessionTracker.swift              # Session lifecycle + stats
│   ├── BreakPredictor.swift              # Adaptive break suggestion heuristic
│   ├── ScreenTintController.swift        # Tint overlay orchestration
│   └── ActivityDataStore.swift           # Session persistence
├── Views/
│   ├── MenuBarDropdown.swift       # Menu bar popover UI
│   ├── MenuBarIconRenderer.swift   # Custom menu bar icon drawing
│   ├── ScreenTintOverlay.swift     # Dimming overlay window
│   ├── SettingsView.swift          # Settings tabs
│   └── HistoryView.swift           # Session history view
```

## Privacy

FlowState operates entirely on your device:

- Activity data is stored locally in `~/Library/Application Support/FlowState/`
- No network requests, no telemetry, no analytics
- Session history is used only for improving break predictions

## License

MIT License. See [LICENSE](LICENSE) for details.

---

<p align="center">
  <sub>Built for developers who value deep work.</sub>
</p>
