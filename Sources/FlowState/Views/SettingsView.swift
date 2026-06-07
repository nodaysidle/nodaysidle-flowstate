// Sources/FlowState/Views/SettingsView.swift
import SwiftUI
import ServiceManagement

struct SettingsView: View {
    let dataStore: ActivityDataStore

    var body: some View {
        TabView {
            FocusSettingsTab()
                .tabItem {
                    Label("Focus", systemImage: "target")
                }

            TintSettingsTab()
                .tabItem {
                    Label("Tint", systemImage: "circle.lefthalf.filled")
                }

            BreakSettingsTab()
                .tabItem {
                    Label("Breaks", systemImage: "cup.and.saucer.fill")
                }

            HistoryView(dataStore: dataStore)
                .tabItem {
                    Label("History", systemImage: "chart.xyaxis.line")
                }

            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gearshape.fill")
                }
        }
        .tint(.green)
        .frame(minWidth: 520, idealWidth: 600, minHeight: 440, idealHeight: 520)
    }
}

// MARK: - Focus Settings Tab

struct FocusSettingsTab: View {
    @AppStorage("idleThreshold") private var idleThreshold: Int = 30
    @AppStorage("idleTriggerDuration") private var idleTriggerDuration: Double = 10.0
    @AppStorage("recoveryDuration") private var recoveryDuration: Double = 5.0

    var body: some View {
        Form {
            Section {
                SettingsRow(
                    title: "Focus Sensitivity",
                    subtitle: "How quickly FlowState reacts to dips in activity."
                ) {
                    Picker("Focus Sensitivity", selection: $idleThreshold) {
                        Text("Sensitive").tag(20)
                        Text("Balanced").tag(30)
                        Text("Relaxed").tag(40)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                    .help("Sensitive reacts sooner. Relaxed waits for a clearer activity drop.")
                }

                SettingsRow(
                    title: "Inactivity Delay",
                    subtitle: "How long activity can pause before tinting begins."
                ) {
                    Picker("Inactivity Delay", selection: $idleTriggerDuration) {
                        Text("5 seconds").tag(5.0)
                        Text("10 seconds").tag(10.0)
                        Text("15 seconds").tag(15.0)
                        Text("30 seconds").tag(30.0)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                    .help("Choose how long FlowState waits before treating inactivity as a focus drop.")
                }

                SettingsRow(
                    title: "Recovery Window",
                    subtitle: "How long steady activity should clear a dimming nudge."
                ) {
                    Picker("Recovery Window", selection: $recoveryDuration) {
                        Text("3 seconds").tag(3.0)
                        Text("5 seconds").tag(5.0)
                        Text("10 seconds").tag(10.0)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                    .help("Shorter recovery clears the tint faster after activity returns.")
                }
            } header: {
                Text("Focus Detection")
            } footer: {
                Text("FlowState estimates focus locally from keyboard and mouse activity. Nothing is uploaded.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Tint Settings Tab

struct TintSettingsTab: View {
    @AppStorage("tintIntensity") private var tintIntensity: Double = 0.6
    @AppStorage("tintAnimationDuration") private var tintAnimationDuration: Double = 30.0

    var body: some View {
        Form {
            Section {
                SettingsRow(
                    title: "Tint Strength",
                    subtitle: "How visible the screen dimming should be."
                ) {
                    HStack(spacing: 10) {
                        Slider(value: $tintIntensity, in: 0.3...0.8, step: 0.1)
                            .frame(width: 150)
                            .help("Control how strongly FlowState dims the screen.")
                        Text("\(Int(tintIntensity * 100))%")
                            .frame(width: 42, alignment: .trailing)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                SettingsRow(
                    title: "Fade Speed",
                    subtitle: "How gradually the screen tint appears."
                ) {
                    Picker("Fade Speed", selection: $tintAnimationDuration) {
                        Text("10 seconds").tag(10.0)
                        Text("30 seconds").tag(30.0)
                        Text("60 seconds").tag(60.0)
                        Text("2 minutes").tag(120.0)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                    .help("A slower fade feels calmer; a faster fade is easier to notice.")
                }
            } header: {
                Text("Screen Tint")
            } footer: {
                Text("A warm, low-friction visual nudge that helps you notice when focus has drifted.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Break Settings Tab

struct BreakSettingsTab: View {
    @AppStorage("breakPredictionEnabled") private var breakPredictionEnabled: Bool = true
    @AppStorage("defaultSessionLength") private var defaultSessionLength: Double = 50.0

    var body: some View {
        Form {
            Section {
                Toggle("Smart Break Suggestions", isOn: $breakPredictionEnabled)
                    .help("Let FlowState suggest breaks based on your work rhythm.")

                if breakPredictionEnabled {
                    SettingsRow(
                        title: "Preferred Session Length",
                        subtitle: "The work interval FlowState uses as a baseline."
                    ) {
                        Picker("Preferred Session Length", selection: $defaultSessionLength) {
                            Text("25 minutes").tag(25.0)
                            Text("45 minutes").tag(45.0)
                            Text("50 minutes").tag(50.0)
                            Text("60 minutes").tag(60.0)
                            Text("90 minutes").tag(90.0)
                        }
                        .labelsHidden()
                        .frame(width: 150)
                        .help("Choose the session length that best matches your work rhythm.")
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            } header: {
                Text("Break Rhythm")
            } footer: {
                Text("FlowState tracks your work rhythm and suggests well-timed breaks.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .animation(.easeInOut(duration: 0.18), value: breakPredictionEnabled)
    }
}

// MARK: - General Settings Tab

struct GeneralSettingsTab: View {
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @State private var loginItemError: String?

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .help("Start FlowState automatically when you sign in.")
                    .onChange(of: launchAtLogin) { _, newValue in
                        updateLoginItem(enabled: newValue)
                    }

                if let loginItemError {
                    Label(loginItemError, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Startup")
            }

            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }

                Link("View Source on GitHub", destination: URL(string: "https://github.com/nodaysidle/nodaysidle-flowstate")!)
                    .help("Open the FlowState source repository.")
            } header: {
                Text("About")
            } footer: {
                Text("FlowState is local-first. Activity data is stored on this Mac.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.1"
    }

    private func updateLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginItemError = nil
        } catch {
            loginItemError = "Could not update Launch at Login. Try again from System Settings."
            launchAtLogin.toggle()
        }
    }
}

private struct SettingsRow<Control: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let control: Control

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 16)
            control
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SettingsView(dataStore: ActivityDataStore())
}
