import Charts
import Foundation
import SwiftUI

struct GraphView: View {
    @State var currentDate: Date
    @State private var mode: GraphMode = .achievement
    @State private var focusEntries: [FocusEntry] = []
    @State private var achievementRates: [(task: TaskItem, achievedTime: TimeInterval, plannedTime: TimeInterval, rate: Double)] = []

    enum GraphMode { case focus, achievement }

    var body: some View {
        ZStack {
            Color(hex: "#b99a88")
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .cornerRadius(20)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .padding(.horizontal, 10)

            VStack(alignment: .leading, spacing: 8) {
                Spacer().frame(height: 16)

                Picker("", selection: $mode) {
                    Text("Achievement").tag(GraphMode.achievement)
                    Text("Focus").tag(GraphMode.focus)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                HStack(spacing: 16) {
                    Spacer()
                    Button(action: { changeDate(by: -1) }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#d5bca6"))
                                .frame(width: 32, height: 32)
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                        }
                    }
                    Text(formattedDate)
                        .font(.title3)
                        .foregroundColor(Color(hex: "#333333"))
                    Button(action: { changeDate(by: 1) }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#d5bca6"))
                                .frame(width: 32, height: 32)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)

                if mode == .focus {
                    Chart {
                        ForEach(focusEntries) { entry in
                            PointMark(
                                x: .value("Hour", entry.hour),
                                y: .value("Focus", entry.focus)
                            )
                            .foregroundStyle(Color(hex: "#a47148"))
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
                    .padding(.horizontal, 24)

                    focusSummary
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("DAILY OVERVIEW")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#a47148"))
                            Spacer()
                        }
                        .padding(.horizontal, 28)

                        HStack {
                            Text("Total Achieved Time")
                            Spacer()
                            Text(formatTimeInterval(GraphDataHelper.calculateTotalAchievedTime(dateKey: currentDateKey)))
                                .padding(4)
                                .background(Color(hex: "#d5bca6").opacity(0.3))
                                .cornerRadius(6)
                        }
                        .padding(.horizontal, 28)

                        HStack {
                            Text("Total Planned Time")
                            Spacer()
                            Text(formatTimeInterval(GraphDataHelper.calculateTotalPlannedTime(dateKey: currentDateKey)))
                                .padding(4)
                                .background(Color(hex: "#d5bca6").opacity(0.3))
                                .cornerRadius(6)
                        }
                        .padding(.horizontal, 28)

                        HStack {
                            Text("Total Achievement Rate")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.1f%%", totalAchievementRate * 100))
                                .font(.headline)
                                .padding(4)
                                .background(Color(hex: "#d5bca6").opacity(0.3))
                                .cornerRadius(6)
                        }
                        .padding(.horizontal, 28)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        if !achievementRates.isEmpty {
                            HStack {
                                Text("BREAKDOWN")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: "#a47148"))
                            }
                            .padding(.horizontal, 28)
                        }

                        ScrollView {
                            ForEach(achievementRates, id: \.task.id) { item in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(item.task.color)
                                            .frame(width: 18, height: 18)
                                            .overlay(Circle().stroke(Color.black, lineWidth: 1))
                                        Text(item.task.name)
                                            .font(.title2)
                                        Spacer()
                                    }
                                    .frame(height: 24)
                                    .padding(.horizontal, 28)

                                    HStack {
                                        Text("Achieved Time")
                                        Spacer()
                                        Text(formatTimeInterval(item.achievedTime))
                                            .padding(4)
                                            .background(Color(hex: "#d5bca6").opacity(0.3))
                                            .cornerRadius(6)
                                    }
                                    .padding(.horizontal, 28)

                                    HStack {
                                        Text("Planned Time")
                                        Spacer()
                                        Text(formatTimeInterval(item.plannedTime))
                                            .padding(4)
                                            .background(Color(hex: "#d5bca6").opacity(0.3))
                                            .cornerRadius(6)
                                    }
                                    .padding(.horizontal, 28)

                                    HStack {
                                        Text("Achievement Rate")
                                            .font(.headline)
                                        Spacer()
                                        Text(String(format: "%.1f%%", item.rate * 100))
                                            .font(.headline)
                                            .padding(4)
                                            .background(Color(hex: "#d5bca6").opacity(0.3))
                                            .cornerRadius(6)
                                    }
                                    .padding(.horizontal, 28)
                                }
                            }
                        }
                    }
                    Spacer()
                }
            }
            .onAppear { updateGraph() }
            .onChange(of: currentDate) { updateGraph() }
            .onChange(of: mode) { updateGraph() }
            .padding(.top)
        }
    }

    var currentDateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: currentDate)
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

    var totalAchievementRate: Double {
        let planned = GraphDataHelper.calculateTotalPlannedTime(dateKey: currentDateKey)
        let achieved = GraphDataHelper.calculateTotalAchievedTime(dateKey: currentDateKey)
        return planned == 0 ? 0 : achieved / planned
    }

    func updateGraph() {
        if mode == .focus {
            focusEntries = GraphDataHelper.loadFocusEntries(dateKey: currentDateKey)
        } else {
            achievementRates = GraphDataHelper.calculateAchievementRatesByTask(dateKey: currentDateKey)
        }
    }

    func formatTimeInterval(_ timeInterval: TimeInterval) -> String {
        let totalMinutes = Int(timeInterval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var focusSummary: some View {
        let stats = focusStats()
        return VStack(alignment: .leading, spacing: 6) {
            Text("Average Focus: \(String(format: "%.1f", stats.avg))")
            Text("Best Hour: \(stats.best.map { "\($0):00 ~ \($0+1):00" } ?? "-")")
            Text("Worst Hour: \(stats.worst.map { "\($0):00 ~ \($0+1):00" } ?? "-")")
        }
        .font(.subheadline)
        .padding(.top, 8)
        .padding(.horizontal, 24)
    }

    func focusStats() -> (avg: Double, best: Int?, worst: Int?) {
        guard !focusEntries.isEmpty else { return (0, nil, nil) }
        let avg = focusEntries.map { $0.focus }.reduce(0, +) / Double(focusEntries.count)
        let best = focusEntries.max(by: { $0.focus < $1.focus })?.hour
        let worst = focusEntries.min(by: { $0.focus < $1.focus })?.hour
        return (avg, best, worst)
    }
}

#Preview {
    GraphView(currentDate: Date())
}
