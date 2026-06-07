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
        VStack(alignment: .leading, spacing: 14) {
            if hasPermission {
                scoreView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                permissionRequestView
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }

            HStack(spacing: 10) {
                Button {
                    onOpenAppSettings()
                } label: {
                    Label("Settings", systemImage: "slider.horizontal.3")
                }
                .help("Open FlowState preferences.")

                Spacer()

                Button("Quit") {
                    onQuit()
                }
                .keyboardShortcut("q")
                .help("Quit FlowState.")
            }
            .font(.callout)
            .padding(.top, 2)
        }
        .padding(16)
        .frame(width: 282)
        .animation(.easeInOut(duration: 0.22), value: hasPermission)
        .animation(.easeInOut(duration: 0.18), value: shouldSuggestBreak)
    }

    private var scoreView: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerView

            if shouldSuggestBreak {
                breakSuggestionView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            activityPills
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Focus Level")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(focusStateLabel)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                Text("\(focusScore)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(focusScoreColor)
                    .accessibilityLabel("Focus level")
                    .accessibilityValue("\(focusScore) out of 100")
            }

            ProgressView(value: Double(focusScore), total: 100)
                .progressViewStyle(.linear)
                .tint(focusScoreColor)
                .scaleEffect(x: 1, y: 1.6, anchor: .center)
                .help("FlowState estimates focus from local keyboard and mouse activity.")
                .accessibilityLabel("Focus level")
                .accessibilityValue("\(focusScore) out of 100")
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(focusScoreColor.opacity(0.22), lineWidth: 1)
        }
    }

    private var activityPills: some View {
        HStack(spacing: 8) {
            StatusPill(
                title: keystrokesActive ? "Typing" : "Idle",
                systemImage: keystrokesActive ? "keyboard.fill" : "keyboard",
                color: keystrokesActive ? .green : .secondary,
                help: keystrokesActive ? "Keyboard activity is currently detected." : "No recent keyboard activity detected."
            )
            .accessibilityLabel(keystrokesActive ? "Keyboard activity: typing" : "Keyboard activity: idle")

            StatusPill(
                title: mouseActive ? "Moving" : "Still",
                systemImage: mouseActive ? "computermouse.fill" : "computermouse",
                color: mouseActive ? .orange : .secondary,
                help: mouseActive ? "Mouse movement is currently detected." : "No recent mouse movement detected."
            )
            .accessibilityLabel(mouseActive ? "Mouse activity: moving" : "Mouse activity: still")
        }
    }

    private var breakSuggestionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Break Window", systemImage: "pause.circle.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            Text("You've been working for a while. A short break may help you refocus.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button("Not Now") {
                    onDismissBreakSuggestion()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .help("Dismiss this break suggestion for the current session.")

                #if DEBUG
                Button(isTinting ? "Hide Tint" : "Preview Tint") {
                    isTinting ? onClearTint() : onTestTint()
                }
                .buttonStyle(.bordered)
                .help(isTinting ? "Hide the screen tint preview." : "Preview the screen tint in debug builds.")
                #endif
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.24), lineWidth: 1)
        }
    }

    private var focusScoreColor: Color {
        switch focusScore {
        case 0..<30: return .red
        case 30..<60: return .orange
        default: return .green
        }
    }

    private var focusStateLabel: String {
        switch focusScore {
        case 0..<30: return "Low activity"
        case 30..<60: return "Settling"
        case 60..<85: return "In flow"
        default: return "Deep focus"
        }
    }

    private var permissionRequestView: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.blue)

                Text("Enable Focus Detection")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("FlowState uses local keyboard and mouse activity to understand when you're focused and when a gentle break nudge would help. Your activity never leaves this device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Button("Open Accessibility Settings") {
                    onOpenSystemSettings()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .help("Open macOS Accessibility settings so FlowState can monitor local activity.")

                Button("Request Permission Again") {
                    onPromptPermission()
                }
                .buttonStyle(.bordered)
                .help("Ask macOS to show the Accessibility permission prompt again.")
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.blue.opacity(0.22), lineWidth: 1)
        }
    }
}

private struct StatusPill: View {
    let title: String
    let systemImage: String
    let color: Color
    let help: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .padding(.horizontal, 8)
            .background(color.opacity(0.10), in: Capsule())
            .help(help)
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
