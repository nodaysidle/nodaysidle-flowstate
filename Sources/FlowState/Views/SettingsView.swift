// Sources/FlowState/Views/SettingsView.swift
import SwiftUI
import ServiceManagement

struct SettingsView: View {
    let dataStore: ActivityDataStore

    var body: some View {
        TabView {
            FocusSettingsTab()
                .tabItem {
                    Label("Focus", systemImage: "brain.head.profile")
                }

            TintSettingsTab()
                .tabItem {
                    Label("Tint", systemImage: "circle.lefthalf.filled")
                }

            BreakSettingsTab()
                .tabItem {
                    Label("Breaks", systemImage: "pause.circle")
                }

            HistoryView(dataStore: dataStore)
                .tabItem {
                    Label("History", systemImage: "chart.bar.xaxis")
                }

            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
        }
        .frame(minWidth: 480, idealWidth: 540, minHeight: 400, idealHeight: 460)
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
                HStack {
                    Text("Idle Threshold")
                    Spacer()
                    Picker("", selection: $idleThreshold) {
                        Text("20 (Sensitive)").tag(20)
                        Text("30 (Balanced)").tag(30)
                        Text("40 (Relaxed)").tag(40)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }

                HStack {
                    Text("Idle Trigger")
                    Spacer()
                    Picker("", selection: $idleTriggerDuration) {
                        Text("5 seconds").tag(5.0)
                        Text("10 seconds").tag(10.0)
                        Text("15 seconds").tag(15.0)
                        Text("30 seconds").tag(30.0)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }

                HStack {
                    Text("Recovery Time")
                    Spacer()
                    Picker("", selection: $recoveryDuration) {
                        Text("3 seconds").tag(3.0)
                        Text("5 seconds").tag(5.0)
                        Text("10 seconds").tag(10.0)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }
            } header: {
                Text("Focus Detection")
            } footer: {
                Text("Controls when the screen tint activates based on your activity level.")
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
                HStack {
                    Text("Tint Intensity")
                    Spacer()
                    Slider(value: $tintIntensity, in: 0.3...0.8, step: 0.1)
                        .frame(width: 150)
                    Text("\(Int(tintIntensity * 100))%")
                        .frame(width: 40, alignment: .trailing)
                        .monospacedDigit()
                }

                HStack {
                    Text("Fade Duration")
                    Spacer()
                    Picker("", selection: $tintAnimationDuration) {
                        Text("10 seconds").tag(10.0)
                        Text("30 seconds").tag(30.0)
                        Text("60 seconds").tag(60.0)
                        Text("2 minutes").tag(120.0)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }
            } header: {
                Text("Screen Tint")
            } footer: {
                Text("The dimming overlay that gently reminds you to take a break.")
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

                if breakPredictionEnabled {
                    HStack {
                        Text("Default Session Length")
                        Spacer()
                        Picker("", selection: $defaultSessionLength) {
                            Text("25 minutes").tag(25.0)
                            Text("45 minutes").tag(45.0)
                            Text("50 minutes").tag(50.0)
                            Text("60 minutes").tag(60.0)
                            Text("90 minutes").tag(90.0)
                        }
                        .labelsHidden()
                        .frame(width: 150)
                    }
                }
            } header: {
                Text("Break Predictions")
            } footer: {
                Text("FlowState learns your work rhythm and suggests breaks at optimal times.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - General Settings Tab

struct GeneralSettingsTab: View {
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        updateLoginItem(enabled: newValue)
                    }
            } header: {
                Text("System")
            }

            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }

                Link("View on GitHub", destination: URL(string: "https://github.com/nodaysidle/nodaysidle-flowstate")!)
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func updateLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update login item: \(error)")
        }
    }
}

#Preview {
    SettingsView(dataStore: ActivityDataStore())
}
