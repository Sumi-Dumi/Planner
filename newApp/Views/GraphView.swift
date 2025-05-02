import SwiftUI
import Charts

struct GraphView: View {
    @State private var currentDate: Date = Date()
    @State private var mode: GraphMode = .focus
    @State private var focusEntries: [FocusEntry] = []
    @State private var achievementRates: [(task: TaskItem, rate: Double)] = []

    enum GraphMode { case focus, achievement }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { // VStack의 alignment를 .leading으로 변경
            Picker("", selection: $mode) {
                Text("Focus").tag(GraphMode.focus)
                Text("Achievement").tag(GraphMode.achievement)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            HStack {
                Button(action: { changeDate(by: -1) }) {
                    Image(systemName: "chevron.left").font(.title2)
                }
                Spacer()
                Text(formattedDate)
                    .font(.title3)
                    .foregroundColor(.blue)
                Spacer()
                Button(action: { changeDate(by: 1) }) {
                    Image(systemName: "chevron.right").font(.title2)
                }
            }
            .padding(.horizontal)

            if mode == .focus {
                Chart {
                    ForEach(focusEntries) { entry in
                        PointMark(
                            x: .value("Hour", entry.hour),
                            y: .value("Focus", entry.focus)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .chartXScale(domain: 0...23)
                .chartXAxis {
                    AxisMarks(values: Array(stride(from: 0, through: 23, by: 3)))
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 5, 10])
                }
                .frame(height: 240)
                .padding(.horizontal)

                focusSummary
            } else {
                VStack(alignment: .leading, spacing: 10) { // VStack의 alignment를 .leading으로 변경
                    ForEach(achievementRates, id: \.task.id) { item in
                        HStack {
                            Text(item.task.name)
                            Spacer()
                            Text(String(format: "%.1f%%", item.rate * 100))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            Spacer() // 하단에 Spacer를 추가하여 모든 UI를 위로 밀착시킵니다.
        }
        .onAppear { updateGraph() }
        .onChange(of: currentDate) { updateGraph() }
        .onChange(of: mode) { updateGraph() }
        .padding(.top) // 다이나믹 아일랜드 밑으로 간격을 주기 위해 padding 추가
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: currentDate)
    }

    func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: currentDate) {
            currentDate = newDate
        }
    }

    var currentDateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: currentDate)
    }

    func updateGraph() {
        if mode == .focus {
            focusEntries = loadFocusEntries()
        } else {
            achievementRates = calculateAchievementRates()
        }
    }

    func loadFocusEntries() -> [FocusEntry] {
        guard let data = UserDefaults.standard.data(forKey: "SavedTimerSessions"),
              let sessions = try? JSONDecoder().decode([TimerSession].self, from: data) else {
            return []
        }

        let calendar = Calendar.current
        var hourly: [Int: [Int]] = [:]

        for session in sessions where session.date == currentDateKey {
            guard let rating = session.focusRating else { continue }

            var start = session.startTime
            let end = session.endTime

            while start < end {
                let hour = calendar.component(.hour, from: start)
                hourly[hour, default: []].append(rating)

                if let next = calendar.date(byAdding: .minute, value: 10, to: start) {
                    start = next
                } else {
                    break
                }
            }
        }

        return hourly.map { hour, ratings in
            let avg = Double(ratings.reduce(0, +)) / Double(ratings.count)
            return FocusEntry(id: UUID(), hour: hour, focus: avg)
        }.sorted { $0.hour < $1.hour }
    }

    func calculateAchievementRates() -> [(task: TaskItem, rate: Double)] {
        guard let plannedData = UserDefaults.standard.data(forKey: "SavedGridData"),
              let planned = try? JSONDecoder().decode([String: [CellCoord: TaskItem]].self, from: plannedData),
              let achievedData = UserDefaults.standard.data(forKey: "SavedTimerSessions"),
              let sessions = try? JSONDecoder().decode([TimerSession].self, from: achievedData) else {
            return []
        }

        var plannedCounts: [UUID: Int] = [:]
        if let dayPlan = planned[currentDateKey] {
            for task in dayPlan.values {
                plannedCounts[task.id, default: 0] += 1
            }
        }

        var actualCounts: [UUID: Int] = [:]
        for session in sessions where session.date == currentDateKey {
            let duration = Int(session.endTime.timeIntervalSince(session.startTime)) / 600
            actualCounts[session.task.id, default: 0] += duration
        }

        var result: [(task: TaskItem, rate: Double)] = []
        let allTasks = Dictionary(grouping: planned[currentDateKey]?.values.map { $0 } ?? [], by: { $0.id }).compactMapValues { $0.first }

        for (id, plannedCount) in plannedCounts {
            if let task = allTasks[id] {
                let actual = actualCounts[id, default: 0]
                let rate = plannedCount > 0 ? Double(actual) / Double(plannedCount) : 0
                result.append((task, rate))
            }
        }

        return result
    }

    var focusSummary: some View {
        let stats = focusStats()
        return VStack(alignment: .leading, spacing: 6) { // VStack의 alignment를 .leading으로 변경
            Text("Average Focus: \(String(format: "%.1f", stats.avg))")
            Text("Best Hour: \(stats.best.map { "\($0):00 ~ \($0 + 1):00" } ?? "-")")
            Text("Worst Hour: \(stats.worst.map { "\($0):00 ~ \($0 + 1):00" } ?? "-")")
        }
        .font(.subheadline)
        .padding(.top, 8)
        .padding(.horizontal) // focusSummary에도 horizontal padding 추가
    }

    func focusStats() -> (avg: Double, best: Int?, worst: Int?) {
        let entries = focusEntries
        guard !entries.isEmpty else { return (0, nil, nil) }

        let avg = entries.map { $0.focus }.reduce(0, +) / Double(entries.count)
        let best = entries.max(by: { $0.focus < $1.focus })?.hour
        let worst = entries.min(by: { $0.focus < $1.focus })?.hour
        return (avg, best, worst)
    }
}

struct FocusEntry: Identifiable {
    let id: UUID
    let hour: Int
    let focus: Double
}

#Preview {
    GraphView()
}
