# ML Break Prediction Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Learn user's work rhythm and suggest optimal breaks using on-device Core ML.

**Architecture:** ActivityDataStore persists samples, SessionTracker monitors sessions, BreakPredictor runs ML inference, menu bar shows break suggestions.

**Tech Stack:** Core ML, Swift 6, @Observable, JSON persistence

---

### Task 1: Create ActivityDataStore

**Files:**
- Create: `Sources/FlowState/Services/ActivityDataStore.swift`

**Step 1: Create the data store**

```swift
// Sources/FlowState/Services/ActivityDataStore.swift
import Foundation

struct StoredActivitySample: Codable, Sendable {
    let timestamp: Date
    let keystrokes: Int
    let mouseDistance: Double
    let focusScore: Int
}

struct SessionRecord: Codable, Sendable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let averageFocusScore: Double
    let peakFocusScore: Int
    let activityTrend: Double  // positive = rising, negative = falling
    let hourOfDay: Int
    let dayOfWeek: Int
    let breakWasSuggested: Bool
    let suggestionWasFollowed: Bool?
}

actor ActivityDataStore {
    private let samplesFileURL: URL
    private let sessionsFileURL: URL
    private var recentSamples: [StoredActivitySample] = []
    private var sessions: [SessionRecord] = []

    private let maxSampleAge: TimeInterval = 7 * 24 * 60 * 60  // 7 days

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let flowStateDir = appSupport.appendingPathComponent("FlowState", isDirectory: true)

        try? FileManager.default.createDirectory(at: flowStateDir, withIntermediateDirectories: true)

        samplesFileURL = flowStateDir.appendingPathComponent("activity_samples.json")
        sessionsFileURL = flowStateDir.appendingPathComponent("sessions.json")

        loadData()
    }

    func addSample(_ sample: ActivitySample, focusScore: Int) {
        let stored = StoredActivitySample(
            timestamp: sample.timestamp,
            keystrokes: sample.keystrokes,
            mouseDistance: sample.mouseDistance,
            focusScore: focusScore
        )
        recentSamples.append(stored)

        // Prune old samples periodically
        if recentSamples.count % 100 == 0 {
            pruneOldSamples()
        }
    }

    func addSession(_ session: SessionRecord) {
        sessions.append(session)
        saveData()
    }

    func getRecentSamples(since: Date) -> [StoredActivitySample] {
        recentSamples.filter { $0.timestamp >= since }
    }

    func getAllSessions() -> [SessionRecord] {
        sessions
    }

    func saveData() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let samplesData = try? encoder.encode(recentSamples) {
            try? samplesData.write(to: samplesFileURL)
        }
        if let sessionsData = try? encoder.encode(sessions) {
            try? sessionsData.write(to: sessionsFileURL)
        }
    }

    private func loadData() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let data = try? Data(contentsOf: samplesFileURL),
           let samples = try? decoder.decode([StoredActivitySample].self, from: data) {
            recentSamples = samples
            pruneOldSamples()
        }

        if let data = try? Data(contentsOf: sessionsFileURL),
           let loaded = try? decoder.decode([SessionRecord].self, from: data) {
            sessions = loaded
        }
    }

    private func pruneOldSamples() {
        let cutoff = Date().addingTimeInterval(-maxSampleAge)
        recentSamples = recentSamples.filter { $0.timestamp >= cutoff }
    }
}
```

**Step 2: Build to verify**

Run: `swift build`

**Step 3: Commit**

```bash
git add .
git commit -m "feat: add ActivityDataStore for persisting activity history"
```

---

### Task 2: Create SessionTracker

**Files:**
- Create: `Sources/FlowState/Services/SessionTracker.swift`

**Step 1: Create the session tracker**

```swift
// Sources/FlowState/Services/SessionTracker.swift
import Foundation

@MainActor
@Observable
final class SessionTracker {
    private let dataStore: ActivityDataStore

    private var sessionStartTime: Date?
    private var sessionSamples: [(score: Int, timestamp: Date)] = []
    private var breakWasSuggested = false

    private let focusThreshold = 50
    private let startDuration: TimeInterval = 30  // 30 seconds above threshold to start

    private var aboveThresholdSince: Date?

    private(set) var isInSession = false
    private(set) var currentSessionDuration: TimeInterval = 0
    private(set) var currentSessionAverageScore: Double = 0

    init(dataStore: ActivityDataStore) {
        self.dataStore = dataStore
    }

    func update(score: Int, sample: ActivitySample) {
        // Store sample
        Task {
            await dataStore.addSample(sample, focusScore: score)
        }

        let now = Date()

        if isInSession {
            // Track session data
            sessionSamples.append((score: score, timestamp: now))
            currentSessionDuration = now.timeIntervalSince(sessionStartTime ?? now)
            currentSessionAverageScore = sessionSamples.isEmpty ? 0 :
                Double(sessionSamples.map(\.score).reduce(0, +)) / Double(sessionSamples.count)
        } else {
            // Check if session should start
            if score >= focusThreshold {
                if aboveThresholdSince == nil {
                    aboveThresholdSince = now
                }

                if let since = aboveThresholdSince,
                   now.timeIntervalSince(since) >= startDuration {
                    startSession(at: since)
                }
            } else {
                aboveThresholdSince = nil
            }
        }
    }

    func markBreakSuggested() {
        breakWasSuggested = true
    }

    func endSession(suggestionFollowed: Bool?) {
        guard isInSession, let startTime = sessionStartTime else { return }

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        let avgScore = currentSessionAverageScore
        let peakScore = sessionSamples.map(\.score).max() ?? 0

        // Calculate activity trend (compare last quarter to first quarter)
        let trend = calculateActivityTrend()

        let calendar = Calendar.current
        let record = SessionRecord(
            id: UUID(),
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            averageFocusScore: avgScore,
            peakFocusScore: peakScore,
            activityTrend: trend,
            hourOfDay: calendar.component(.hour, from: startTime),
            dayOfWeek: calendar.component(.weekday, from: startTime),
            breakWasSuggested: breakWasSuggested,
            suggestionWasFollowed: suggestionFollowed
        )

        Task {
            await dataStore.addSession(record)
        }

        resetSession()
    }

    private func startSession(at time: Date) {
        isInSession = true
        sessionStartTime = time
        sessionSamples = []
        breakWasSuggested = false
        currentSessionDuration = 0
        currentSessionAverageScore = 0
    }

    private func resetSession() {
        isInSession = false
        sessionStartTime = nil
        sessionSamples = []
        breakWasSuggested = false
        currentSessionDuration = 0
        currentSessionAverageScore = 0
        aboveThresholdSince = nil
    }

    private func calculateActivityTrend() -> Double {
        guard sessionSamples.count >= 4 else { return 0 }

        let quarterSize = sessionSamples.count / 4
        let firstQuarter = sessionSamples.prefix(quarterSize)
        let lastQuarter = sessionSamples.suffix(quarterSize)

        let firstAvg = Double(firstQuarter.map(\.score).reduce(0, +)) / Double(firstQuarter.count)
        let lastAvg = Double(lastQuarter.map(\.score).reduce(0, +)) / Double(lastQuarter.count)

        return lastAvg - firstAvg
    }
}
```

**Step 2: Build to verify**

Run: `swift build`

**Step 3: Commit**

```bash
git add .
git commit -m "feat: add SessionTracker for monitoring focus sessions"
```

---

### Task 3: Create BreakPredictor with Baseline Model

**Files:**
- Create: `Sources/FlowState/Services/BreakPredictor.swift`

**Step 1: Create the break predictor**

For now, we'll use a heuristic baseline that learns from session history. Core ML model can be added when we have enough training data.

```swift
// Sources/FlowState/Services/BreakPredictor.swift
import Foundation

@MainActor
@Observable
final class BreakPredictor {
    private let dataStore: ActivityDataStore

    private(set) var shouldSuggestBreak = false
    private(set) var predictedOptimalDuration: TimeInterval = 50 * 60  // Default 50 min

    private var lastPredictionTime: Date?
    private let predictionInterval: TimeInterval = 60  // Check every minute

    var onBreakSuggested: (() -> Void)?

    init(dataStore: ActivityDataStore) {
        self.dataStore = dataStore
        Task {
            await updateOptimalDuration()
        }
    }

    func update(sessionDuration: TimeInterval, averageScore: Double, trend: Double) {
        let now = Date()

        // Only predict every minute
        if let last = lastPredictionTime, now.timeIntervalSince(last) < predictionInterval {
            return
        }
        lastPredictionTime = now

        // Predict if break should be suggested
        let probability = calculateBreakProbability(
            duration: sessionDuration,
            avgScore: averageScore,
            trend: trend
        )

        let previousState = shouldSuggestBreak
        shouldSuggestBreak = probability > 0.7

        if shouldSuggestBreak && !previousState {
            onBreakSuggested?()
        }
    }

    func dismissSuggestion() {
        shouldSuggestBreak = false
    }

    func recordOutcome(followed: Bool) {
        // This will be used to update the model in the future
        // For now, just adjust the optimal duration heuristically
        Task {
            await updateOptimalDuration()
        }
    }

    private func calculateBreakProbability(duration: TimeInterval, avgScore: Double, trend: Double) -> Double {
        // Baseline heuristic model
        var probability = 0.0

        // Factor 1: Duration relative to optimal
        let durationRatio = duration / predictedOptimalDuration
        if durationRatio > 1.0 {
            probability += min(0.5, (durationRatio - 1.0) * 0.5)
        } else if durationRatio > 0.8 {
            probability += (durationRatio - 0.8) * 0.25
        }

        // Factor 2: Declining focus (negative trend)
        if trend < -10 {
            probability += 0.3
        } else if trend < -5 {
            probability += 0.15
        }

        // Factor 3: Low average score
        if avgScore < 40 {
            probability += 0.2
        }

        return min(1.0, probability)
    }

    private func updateOptimalDuration() async {
        let sessions = await dataStore.getAllSessions()

        // Filter to natural breaks (not forced) with reasonable duration
        let naturalSessions = sessions.filter { session in
            session.duration > 10 * 60 &&  // At least 10 min
            session.duration < 180 * 60 && // Less than 3 hours
            (session.suggestionWasFollowed == nil || session.suggestionWasFollowed == true)
        }

        guard naturalSessions.count >= 3 else { return }

        // Calculate weighted average (recent sessions weighted more)
        let sortedSessions = naturalSessions.sorted { $0.startTime > $1.startTime }
        var weightedSum = 0.0
        var weightSum = 0.0

        for (index, session) in sortedSessions.prefix(10).enumerated() {
            let weight = 1.0 / Double(index + 1)
            weightedSum += session.duration * weight
            weightSum += weight
        }

        if weightSum > 0 {
            predictedOptimalDuration = weightedSum / weightSum
        }
    }
}
```

**Step 2: Build to verify**

Run: `swift build`

**Step 3: Commit**

```bash
git add .
git commit -m "feat: add BreakPredictor with adaptive heuristic model"
```

---

### Task 4: Update MenuBarIconRenderer for Break Suggestion

**Files:**
- Modify: `Sources/FlowState/Views/MenuBarIconRenderer.swift`

**Step 1: Add break suggestion rendering**

Add a new render method that shows break indicator:

```swift
static func renderBreakSuggestion() -> NSImage {
    let size = NSSize(width: 18, height: 18)
    let image = NSImage(size: size, flipped: false) { rect in
        let inset: CGFloat = 1.5
        let circleRect = rect.insetBy(dx: inset, dy: inset)

        // Draw filled circle
        let circlePath = NSBezierPath(ovalIn: circleRect)
        NSColor.white.withAlphaComponent(0.3).setFill()
        circlePath.fill()

        // Draw outline
        circlePath.lineWidth = 1.5
        NSColor.white.withAlphaComponent(0.8).setStroke()
        circlePath.stroke()

        // Draw pause icon in center
        let pauseWidth: CGFloat = 2.0
        let pauseHeight: CGFloat = 8.0
        let pauseGap: CGFloat = 3.0
        let centerX = rect.midX
        let centerY = rect.midY

        let leftBar = NSRect(
            x: centerX - pauseGap/2 - pauseWidth,
            y: centerY - pauseHeight/2,
            width: pauseWidth,
            height: pauseHeight
        )
        let rightBar = NSRect(
            x: centerX + pauseGap/2,
            y: centerY - pauseHeight/2,
            width: pauseWidth,
            height: pauseHeight
        )

        NSColor.white.setFill()
        NSBezierPath(roundedRect: leftBar, xRadius: 0.5, yRadius: 0.5).fill()
        NSBezierPath(roundedRect: rightBar, xRadius: 0.5, yRadius: 0.5).fill()

        return true
    }

    image.isTemplate = false
    return image
}
```

**Step 2: Build to verify**

Run: `swift build`

**Step 3: Commit**

```bash
git add .
git commit -m "feat: add break suggestion icon to MenuBarIconRenderer"
```

---

### Task 5: Integrate Everything into AppState

**Files:**
- Modify: `Sources/FlowState/AppState.swift`

**Step 1: Add new services and wire them up**

Add to AppState:
- ActivityDataStore
- SessionTracker
- BreakPredictor
- Update menuBarImage to show break suggestion
- Wire IdleDetector to end sessions

**Step 2: Build and test**

Run: `swift build && swift run`

**Step 3: Commit and push**

```bash
git add .
git commit -m "feat: integrate ML break prediction into AppState"
git push origin main
```

---

## Testing Checklist

- [ ] Activity samples are persisted to JSON
- [ ] Sessions are recorded when user goes idle
- [ ] Break predictor suggests break after ~50 min (baseline)
- [ ] Menu bar icon changes to pause symbol when break suggested
- [ ] Icon returns to normal after user takes break
- [ ] Optimal duration adapts based on user's session history
