// Tests/FlowStateTests/ActivityDataStoreTests.swift
import Foundation
import Testing
@testable import FlowState

@Suite("ActivityDataStore Tests")
struct ActivityDataStoreTests {
    @Test("Samples persist periodically")
    func samplesPersistPeriodically() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = ActivityDataStore(baseDirectory: directory)
        for index in 0..<10 {
            await store.addSample(
                ActivitySample(keystrokes: index, mouseDistance: Double(index), timestamp: Date()),
                focusScore: 70
            )
        }

        let reloadedStore = ActivityDataStore(baseDirectory: directory)
        let samples = await reloadedStore.getRecentSamples(since: .distantPast)
        #expect(samples.count == 10)
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("flowstate-tests-")
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }
}
