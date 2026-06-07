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
    private let sampleSaveInterval = 10

    init(baseDirectory: URL? = nil) {
        let flowStateDir: URL
        if let baseDirectory {
            flowStateDir = baseDirectory
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            flowStateDir = appSupport.appendingPathComponent("FlowState", isDirectory: true)
        }

        try? FileManager.default.createDirectory(at: flowStateDir, withIntermediateDirectories: true)

        samplesFileURL = flowStateDir.appendingPathComponent("activity_samples.json")
        sessionsFileURL = flowStateDir.appendingPathComponent("sessions.json")

        // Load data synchronously using nonisolated helper
        let (samples, loadedSessions) = Self.loadDataSync(
            samplesURL: samplesFileURL,
            sessionsURL: sessionsFileURL
        )
        recentSamples = samples
        sessions = loadedSessions
    }

    private nonisolated static func loadDataSync(
        samplesURL: URL,
        sessionsURL: URL
    ) -> ([StoredActivitySample], [SessionRecord]) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        var samples: [StoredActivitySample] = []
        var sessions: [SessionRecord] = []

        if let data = try? Data(contentsOf: samplesURL),
           let loaded = try? decoder.decode([StoredActivitySample].self, from: data) {
            let cutoff = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            samples = loaded.filter { $0.timestamp >= cutoff }
        }

        if let data = try? Data(contentsOf: sessionsURL),
           let loaded = try? decoder.decode([SessionRecord].self, from: data) {
            sessions = loaded
        }

        return (samples, sessions)
    }

    func addSample(_ sample: ActivitySample, focusScore: Int) {
        let stored = StoredActivitySample(
            timestamp: sample.timestamp,
            keystrokes: sample.keystrokes,
            mouseDistance: sample.mouseDistance,
            focusScore: focusScore
        )
        recentSamples.append(stored)

        // Prune and persist periodically so long sessions survive crashes/restarts.
        if recentSamples.count % 100 == 0 {
            pruneOldSamples()
        }
        if recentSamples.count % sampleSaveInterval == 0 {
            saveData()
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

    func getSessions(from startDate: Date, to endDate: Date) -> [SessionRecord] {
        sessions.filter { $0.startTime >= startDate && $0.startTime <= endDate }
    }

    func getSessionsToday() -> [SessionRecord] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return sessions.filter { $0.startTime >= startOfDay }
    }

    func getSessionsThisWeek() -> [SessionRecord] {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return []
        }
        return sessions.filter { $0.startTime >= weekStart }
    }

    func getDailyFocusTime(days: Int) -> [(date: Date, focusMinutes: Double)] {
        let calendar = Calendar.current
        var result: [(date: Date, focusMinutes: Double)] = []

        for dayOffset in (0..<days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }

            let daySessions = sessions.filter { $0.startTime >= startOfDay && $0.startTime < endOfDay }
            let totalMinutes = daySessions.reduce(0.0) { $0 + $1.duration / 60.0 }

            result.append((date: startOfDay, focusMinutes: totalMinutes))
        }

        return result
    }

    func getTotalStats() -> (sessions: Int, totalMinutes: Double, avgScore: Double) {
        let totalSessions = sessions.count
        let totalMinutes = sessions.reduce(0.0) { $0 + $1.duration / 60.0 }
        let avgScore = sessions.isEmpty ? 0 : sessions.reduce(0.0) { $0 + $1.averageFocusScore } / Double(sessions.count)
        return (sessions: totalSessions, totalMinutes: totalMinutes, avgScore: avgScore)
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

    private func pruneOldSamples() {
        let cutoff = Date().addingTimeInterval(-maxSampleAge)
        recentSamples = recentSamples.filter { $0.timestamp >= cutoff }
    }
}
