// Sources/FlowState/Views/MenuBarDropdown.swift
import SwiftUI

struct MenuBarDropdown: View {
    let focusScore: Int
    let hasPermission: Bool
    let keystrokesActive: Bool
    let mouseActive: Bool
    let isTinting: Bool
    let shouldSuggestBreak: Bool
    let onPromptPermission: () -> Void
    let onOpenSystemSettings: () -> Void
    let onOpenAppSettings: () -> Void
    let onTestTint: () -> Void
    let onClearTint: () -> Void
    let onDismissBreakSuggestion: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if hasPermission {
                scoreView
            } else {
                permissionRequestView
            }

            Divider()

            HStack {
                Button {
                    onOpenAppSettings()
                } label: {
                    Label("Settings", systemImage: "gear")
                }

                Spacer()

                Button("Quit") {
                    onQuit()
                }
            }
        }
        .padding()
        .frame(width: 240)
    }

    private var scoreView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if shouldSuggestBreak {
                breakSuggestionView
                Divider()
            }

            Text("Focus Score")
                .font(.headline)

            HStack {
                ProgressView(value: Double(focusScore), total: 100)
                    .progressViewStyle(.linear)
                    .tint(focusScoreColor)

                Text("\(focusScore)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .frame(width: 40, alignment: .trailing)
            }

            HStack(spacing: 16) {
                Label(
                    keystrokesActive ? "Keyboard: Active" : "Keyboard: Idle",
                    systemImage: keystrokesActive ? "keyboard.fill" : "keyboard"
                )
                .foregroundColor(keystrokesActive ? .green : .secondary)

                Label(
                    mouseActive ? "Mouse: Active" : "Mouse: Idle",
                    systemImage: mouseActive ? "computermouse.fill" : "computermouse"
                )
                .foregroundColor(mouseActive ? .orange : .secondary)
            }
            .font(.caption)

            Divider()

            tintControlsView

            Divider()
        }
    }

    private var breakSuggestionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Time for a Break", systemImage: "pause.circle.fill")
                .font(.headline)
                .foregroundColor(.orange)

            Text("You've been focused for a while. Consider taking a short break.")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Dismiss") {
                onDismissBreakSuggestion()
            }
            .buttonStyle(.bordered)
        }
    }

    private var focusScoreColor: Color {
        switch focusScore {
        case 0..<30: return .red
        case 30..<60: return .orange
        default: return .green
        }
    }

    private var tintControlsView: some View {
        HStack(spacing: 12) {
            Button("Test Tint") {
                onTestTint()
            }
            .disabled(isTinting)

            Button("Clear Tint") {
                onClearTint()
            }
            .disabled(!isTinting)
        }
        .buttonStyle(.bordered)
    }

    private var permissionRequestView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Accessibility Access Required", systemImage: "lock.shield")
                .font(.headline)

            Text("FlowState needs Accessibility access to monitor keyboard and mouse activity for focus detection.")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Button("Grant Permission") {
                    onPromptPermission()
                }
                .buttonStyle(.borderedProminent)

                Button("Open System Settings") {
                    onOpenSystemSettings()
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview("With Permission") {
    MenuBarDropdown(
        focusScore: 78,
        hasPermission: true,
        keystrokesActive: true,
        mouseActive: false,
        isTinting: false,
        shouldSuggestBreak: false,
        onPromptPermission: {},
        onOpenSystemSettings: {},
        onOpenAppSettings: {},
        onTestTint: {},
        onClearTint: {},
        onDismissBreakSuggestion: {},
        onQuit: {}
    )
}

#Preview("Break Suggested") {
    MenuBarDropdown(
        focusScore: 45,
        hasPermission: true,
        keystrokesActive: false,
        mouseActive: true,
        isTinting: false,
        shouldSuggestBreak: true,
        onPromptPermission: {},
        onOpenSystemSettings: {},
        onOpenAppSettings: {},
        onTestTint: {},
        onClearTint: {},
        onDismissBreakSuggestion: {},
        onQuit: {}
    )
}

#Preview("Without Permission") {
    MenuBarDropdown(
        focusScore: 0,
        hasPermission: false,
        keystrokesActive: false,
        mouseActive: false,
        isTinting: false,
        shouldSuggestBreak: false,
        onPromptPermission: {},
        onOpenSystemSettings: {},
        onOpenAppSettings: {},
        onTestTint: {},
        onClearTint: {},
        onDismissBreakSuggestion: {},
        onQuit: {}
    )
}
