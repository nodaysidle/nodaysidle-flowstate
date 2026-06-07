// Sources/FlowState/FlowStateApp.swift
import SwiftUI

@main
struct FlowStateApp: App {
    @State private var appState = AppState()
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra {
            MenuBarDropdown(
                focusScore: appState.focusEngine.currentScore,
                hasPermission: appState.permissionChecker.hasPermission,
                keystrokesActive: appState.keystrokesActive,
                mouseActive: appState.mouseActive,
                isTinting: appState.isTinting,
                shouldSuggestBreak: appState.shouldSuggestBreak,
                onPromptPermission: {
                    appState.permissionChecker.promptForPermission()
                },
                onOpenSystemSettings: {
                    appState.permissionChecker.openSystemSettings()
                },
                onOpenAppSettings: {
                    openSettings()
                },
                onTestTint: {
                    appState.startTint()
                },
                onClearTint: {
                    appState.clearTint()
                },
                onDismissBreakSuggestion: {
                    appState.dismissBreakSuggestion()
                },
                onQuit: {
                    NSApplication.shared.terminate(nil)
                }
            )
            .onChange(of: appState.permissionChecker.hasPermission) { _, hasPermission in
                if hasPermission {
                    appState.permissionChecker.stopPolling()
                    appState.startMonitoring()
                }
            }
            .task {
                appState.start()
            }
        } label: {
            Image(nsImage: appState.menuBarImage)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(dataStore: appState.dataStore)
        }
    }
}
