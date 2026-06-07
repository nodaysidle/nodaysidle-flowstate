// Sources/FlowState/AppState.swift
import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    let focusEngine = FocusScoreEngine()
    let permissionChecker = AccessibilityPermissionChecker()
    let activityMonitor = ActivityMonitorService()
    let tintController = ScreenTintController()
    let idleDetector = IdleDetector()
    let dataStore = ActivityDataStore()
    private(set) var sessionTracker: SessionTracker!
    private(set) var breakPredictor: BreakPredictor!

    private(set) var lastKeystrokeCount: Int = 0
    private(set) var lastMouseDistance: Double = 0
    private var hasStarted = false

    var keystrokesActive: Bool { lastKeystrokeCount > 0 }
    var mouseActive: Bool { lastMouseDistance > 50 }
    var isTinting: Bool { tintController.isTinting }
    var shouldSuggestBreak: Bool { breakPredictor?.shouldSuggestBreak ?? false }

    var menuBarImage: NSImage {
        if shouldSuggestBreak {
            return MenuBarIconRenderer.renderBreakSuggestion()
        }
        return MenuBarIconRenderer.render(score: focusEngine.currentScore)
    }

    init() {
        sessionTracker = SessionTracker(dataStore: dataStore)
        breakPredictor = BreakPredictor(dataStore: dataStore)
    }

    func startTint() {
        tintController.show()
    }

    func clearTint() {
        tintController.hide()
        idleDetector.reset()  // Prevent immediate re-trigger
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        // Wire idle detector callbacks
        idleDetector.onIdleStart = { [weak self] in
            self?.tintController.show()
            // Going idle is not explicit proof that the user followed the break suggestion.
            self?.sessionTracker.endSession(suggestionFollowed: nil)
        }
        idleDetector.onIdleEnd = { [weak self] in
            self?.tintController.hide()
        }

        // Wire break predictor callback
        breakPredictor.onBreakSuggested = { [weak self] in
            self?.sessionTracker.markBreakSuggested()
        }

        permissionChecker.promptForPermission()
        permissionChecker.startPolling()

        if permissionChecker.hasPermission {
            permissionChecker.stopPolling()
            startMonitoring()
        }
    }

    func startMonitoring() {
        Task {
            await activityMonitor.start { [weak self] sample in
                Task { @MainActor in
                    self?.handleSample(sample)
                }
            }
        }
    }

    func stopMonitoring() {
        Task {
            await activityMonitor.stop()
        }
    }

    private func handleSample(_ sample: ActivitySample) {
        lastKeystrokeCount = sample.keystrokes
        lastMouseDistance = sample.mouseDistance
        focusEngine.processSample(sample)

        let score = focusEngine.currentScore

        // Notify idle detector of score change
        idleDetector.update(score: score)

        // Update session tracker
        sessionTracker.update(score: score, sample: sample)

        // Update break predictor if in session
        if sessionTracker.isInSession {
            breakPredictor.update(
                sessionDuration: sessionTracker.currentSessionDuration,
                averageScore: sessionTracker.currentSessionAverageScore,
                trend: sessionTracker.currentTrend
            )
        }
    }

    func dismissBreakSuggestion() {
        breakPredictor.dismissSuggestion()
        breakPredictor.recordOutcome(followed: false)
    }
}
