// Sources/FlowState/Views/HistoryView.swift
import SwiftUI
import Charts
import UniformTypeIdentifiers

struct HistoryView: View {
    let dataStore: ActivityDataStore

    @State private var dailyData: [(date: Date, focusMinutes: Double)] = []
    @State private var recentSessions: [SessionRecord] = []
    @State private var stats: (sessions: Int, totalMinutes: Double, avgScore: Double) = (0, 0, 0)
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else if stats.sessions == 0 {
                emptyStateView
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        statsSection
                        chartSection
                        sessionsSection
                        exportSection
                    }
                    .padding()
                }
            }
        }
        .task {
            await loadData()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Loading sessions…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading FlowState sessions")
    }

    private var emptyStateView: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(.green.opacity(0.12))
                    .frame(width: 86, height: 86)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 6) {
                Text("No Sessions Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("Your sessions will appear here automatically as FlowState observes local activity.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "All Time", subtitle: "A compact view of your recorded focus sessions.")

            HStack(spacing: 12) {
                StatBox(title: "Sessions", value: "\(stats.sessions)", systemImage: "rectangle.stack.fill", color: .green)
                StatBox(title: "Focus Time", value: formatDuration(stats.totalMinutes), systemImage: "clock.fill", color: .blue)
                StatBox(title: "Avg Focus", value: String(format: "%.0f", stats.avgScore), systemImage: "gauge.with.dots.needle.67percent", color: .orange)
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Last 7 Days", subtitle: "Daily focus time based on completed sessions.")

            Chart(dailyData, id: \.date) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Minutes", item.focusMinutes)
                )
                .foregroundStyle(item.focusMinutes > 0 ? Color.green.gradient : Color.gray.opacity(0.25).gradient)
                .annotation(position: .top) {
                    if item.focusMinutes > 0 {
                        Text("\(Int(item.focusMinutes))m")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let minutes = value.as(Double.self) {
                            Text("\(Int(minutes))m")
                        }
                    }
                }
            }
            .frame(height: 160)
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityLabel("Focus time chart for the last seven days")
            .accessibilityValue(chartAccessibilitySummary)
        }
    }

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Recent Sessions", subtitle: "Latest completed work windows and their focus level.")

            VStack(spacing: 6) {
                ForEach(recentSessions.prefix(10), id: \.id) { session in
                    SessionRow(session: session)
                }
            }
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Export", subtitle: "Download your session history as a spreadsheet or structured data file.")

            HStack(spacing: 10) {
                Button {
                    exportCSV()
                } label: {
                    Label("Export CSV", systemImage: "tablecells")
                }
                .buttonStyle(.bordered)
                .help("Open a save dialog to export sessions as CSV.")
                .accessibilityHint("Opens a save dialog to export your FlowState session history as a CSV file.")

                Button {
                    exportJSON()
                } label: {
                    Label("Export JSON", systemImage: "curlybraces")
                }
                .buttonStyle(.bordered)
                .help("Open a save dialog to export sessions as JSON.")
                .accessibilityHint("Opens a save dialog to export your FlowState session history as a JSON file.")
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var chartAccessibilitySummary: String {
        let nonZeroDays = dailyData.filter { $0.focusMinutes > 0 }.count
        let total = dailyData.reduce(0) { $0 + $1.focusMinutes }
        return "\(nonZeroDays) active days, \(Int(total)) total focus minutes."
    }

    private func loadData() async {
        dailyData = await dataStore.getDailyFocusTime(days: 7)
        recentSessions = await dataStore.getAllSessions().sorted { $0.startTime > $1.startTime }
        stats = await dataStore.getTotalStats()
        isLoading = false
    }

    private func formatDuration(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }

    private func exportCSV() {
        Task {
            let sessions = await dataStore.getAllSessions()
            var csv = "id,start_time,end_time,duration_minutes,avg_focus_score,peak_focus_score,activity_trend,hour_of_day,day_of_week,break_suggested,suggestion_followed\n"

            let formatter = ISO8601DateFormatter()

            for session in sessions {
                let line = [
                    session.id.uuidString,
                    formatter.string(from: session.startTime),
                    formatter.string(from: session.endTime),
                    String(format: "%.1f", session.duration / 60),
                    String(format: "%.1f", session.averageFocusScore),
                    "\(session.peakFocusScore)",
                    String(format: "%.2f", session.activityTrend),
                    "\(session.hourOfDay)",
                    "\(session.dayOfWeek)",
                    "\(session.breakWasSuggested)",
                    session.suggestionWasFollowed.map { "\($0)" } ?? ""
                ].joined(separator: ",")
                csv += line + "\n"
            }

            saveFile(content: csv, filename: "flowstate_sessions.csv", type: .commaSeparatedText)
        }
    }

    private func exportJSON() {
        Task {
            let sessions = await dataStore.getAllSessions()
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            if let data = try? encoder.encode(sessions),
               let json = String(data: data, encoding: .utf8) {
                saveFile(content: json, filename: "flowstate_sessions.json", type: .json)
            }
        }
    }

    private func saveFile(content: String, filename: String, type: UTType) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [type]
        panel.nameFieldStringValue = filename

        if panel.runModal() == .OK, let url = panel.url {
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

private struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(color.opacity(0.16), lineWidth: 1)
        }
    }
}

struct SessionRow: View {
    let session: SessionRecord

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(scoreColor(session.averageFocusScore).opacity(0.18))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.startTime, style: .time)
                    .font(.callout)
                    .fontWeight(.medium)
                Text(formatDuration(session.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                if session.breakWasSuggested {
                    Image(systemName: session.suggestionWasFollowed == true ? "checkmark.circle.fill" : "minus.circle")
                        .foregroundColor(session.suggestionWasFollowed == true ? .green : .orange)
                        .font(.caption)
                        .help(session.suggestionWasFollowed == true ? "Break suggestion followed." : "Break suggestion skipped or unresolved.")
                }

                Text("\(Int(session.averageFocusScore))")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundColor(scoreColor(session.averageFocusScore))
                    .accessibilityLabel("Average focus")
                    .accessibilityValue("\(Int(session.averageFocusScore)) out of 100")
            }
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        return "\(minutes) min"
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0..<30: return .red
        case 30..<60: return .orange
        default: return .green
        }
    }
}

#Preview {
    HistoryView(dataStore: ActivityDataStore())
        .frame(width: 460, height: 560)
}
