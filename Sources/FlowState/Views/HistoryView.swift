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
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if stats.sessions == 0 {
                emptyStateView
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
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
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await loadData() }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Sessions Yet")
                .font(.headline)
            Text("Start working and your focus sessions will appear here.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("All Time")
                .font(.headline)

            HStack(spacing: 24) {
                StatBox(title: "Sessions", value: "\(stats.sessions)")
                StatBox(title: "Focus Time", value: formatDuration(stats.totalMinutes))
                StatBox(title: "Avg Score", value: String(format: "%.0f", stats.avgScore))
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 7 Days")
                .font(.headline)

            Chart(dailyData, id: \.date) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Minutes", item.focusMinutes)
                )
                .foregroundStyle(item.focusMinutes > 0 ? Color.green : Color.gray.opacity(0.3))
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
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
            .frame(height: 150)
        }
    }

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Sessions")
                .font(.headline)

            if recentSessions.isEmpty {
                Text("No sessions recorded yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 4) {
                    ForEach(recentSessions.prefix(10), id: \.id) { session in
                        SessionRow(session: session)
                    }
                }
            }
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Export Data")
                .font(.headline)

            HStack(spacing: 12) {
                Button("Export CSV") {
                    exportCSV()
                }
                .buttonStyle(.bordered)

                Button("Export JSON") {
                    exportJSON()
                }
                .buttonStyle(.bordered)
            }
        }
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

struct StatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SessionRow: View {
    let session: SessionRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.startTime, style: .time)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(formatDuration(session.duration))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                if session.breakWasSuggested {
                    Image(systemName: session.suggestionWasFollowed == true ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundColor(session.suggestionWasFollowed == true ? .green : .orange)
                        .font(.caption)
                }

                Text("\(Int(session.averageFocusScore))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(scoreColor(session.averageFocusScore))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(4)
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
        .frame(width: 400, height: 500)
}
