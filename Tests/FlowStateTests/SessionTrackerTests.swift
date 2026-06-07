// Tests/FlowStateTests/SessionTrackerTests.swift
import Foundation
import Testing
@testable import FlowState

@Suite("SessionTracker Tests")
@MainActor
struct SessionTrackerTests {
    @Test("Session tracks falling activity trend")
    func sessionTracksFallingActivityTrend() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        var currentTime = Date(timeIntervalSince1970: 1_700_000_000)
        let store = ActivityDataStore(baseDirectory: directory)
        let tracker = SessionTracker(
            dataStore: store,
            startDuration: 0,
            nowProvider: { currentTime }
        )

        tracker.update(score: 80, sample: ActivitySample(keystrokes: 8, mouseDistance: 0, timestamp: currentTime))
        for score in [80, 70, 60, 45, 30] {
            currentTime = currentTime.addingTimeInterval(10)
            tracker.update(score: score, sample: ActivitySample(keystrokes: max(score / 10, 0), mouseDistance: 0, timestamp: currentTime))
        }

        #expect(tracker.isInSession)
        #expect(tracker.currentTrend < 0)
    }

    @Test("Ended sessions persist with nil suggestion outcome when no explicit follow action exists")
    func endedSessionPersistsNilSuggestionOutcome() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        var currentTime = Date(timeIntervalSince1970: 1_700_000_000)
        let store = ActivityDataStore(baseDirectory: directory)
        let tracker = SessionTracker(
            dataStore: store,
            startDuration: 0,
            nowProvider: { currentTime }
        )

        tracker.update(score: 80, sample: ActivitySample(keystrokes: 8, mouseDistance: 0, timestamp: currentTime))
        currentTime = currentTime.addingTimeInterval(60)
        tracker.update(score: 75, sample: ActivitySample(keystrokes: 7, mouseDistance: 0, timestamp: currentTime))
        tracker.markBreakSuggested()
        currentTime = currentTime.addingTimeInterval(60)
        tracker.endSession(suggestionFollowed: nil)
        try await Task.sleep(for: .milliseconds(100))

        let sessions = await store.getAllSessions()
        #expect(sessions.count == 1)
        guard let session = sessions.first else { return }
        #expect(session.breakWasSuggested)
        #expect(session.suggestionWasFollowed == nil)
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("flowstate-tests-")
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }
}
