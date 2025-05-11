import Charts
import Foundation
import SwiftUI


struct GraphView: View {
    @State var currentDate: Date
    @State private var mode: GraphMode = .achievement
    @State private var focusEntries: [FocusEntry] = []
    @State private var achievementRates: [(task: TaskItem, achievedTime: TimeInterval, plannedTime: TimeInterval,rate: Double)] = []
    
    enum GraphMode { case focus, achievement }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {  // VStack의 alignment를 .leading으로 변경
            Picker("", selection: $mode) {
                Text("Achievement").tag(GraphMode.achievement)
                Text("Focus").tag(GraphMode.focus)

            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            HStack {
                Button(action: { changeDate(by: -1) }) {
                    Image(systemName: "chevron.left").font(.title2)
                }
                Spacer()
                DatePicker(
                    "",
                    selection: $currentDate,
                    displayedComponents: [.date]
                )
                .labelsHidden()
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
                        AxisMarks(
                            values: Array(stride(from: 0, through: 23, by: 3))
                        )
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [0, 5, 10])
                    }
                    .frame(height: 240)
                    .padding(.horizontal)
                    
                    focusSummary
                    Spacer()
                } else {
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Daily Overview")
                                .font(.title)
                            Spacer()
                            
                        }.padding(.horizontal)
                        HStack {
                            Text("Total Achieved Time")
                            Spacer()
                            Text("\(formatTimeInterval(GraphDataHelper.calculateTotalAchievedTime(dateKey:currentDateKey)))")
                                .foregroundColor(.blue)
                            
                        }.padding(.horizontal)
                        HStack {
                            Text("Total Planned Time")
                            Spacer()
                            Text("\(formatTimeInterval(GraphDataHelper.calculateTotalPlannedTime(dateKey:currentDateKey)))")
                                .foregroundColor(.blue)
                            
                        }.padding(.horizontal)
                        
                        HStack {
                            Text("Total Achievement Rate")
                                .font(.headline)
                            Spacer()
                            Text(
                                String(
                                    format: "%.1f%%",
                                    totalAchievementRate * 100
                                )
                            )
                            .font(.headline)
                            .foregroundColor(.blue)
                            
                        }.padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        
                        if !achievementRates.isEmpty {
                            HStack {
                                Text("Breakdown")
                                    .font(.title)
                                    .padding(.top)
                                
                            }.padding(.horizontal)
                        }
                        
                        // VStack의 alignment를 .leading으로 변경
                        ScrollView {
                            ForEach(achievementRates, id: \.task.id) { item in
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(item.task.name)
                                            .font(.title2)
                                            .padding(.top)
                                        
                                    }.padding(.horizontal)
                                    HStack {
                                        Text("Achieved Time")
                                        Spacer()
                                        Text("\(formatTimeInterval(item.achievedTime))")
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal)
                                    HStack {
                                        Text("Planned Time")
                                        Spacer()
                                        Text("\(formatTimeInterval(item.plannedTime))")
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal)
                                    HStack {
                                        Text("Achievement Rate")
                                            .font(.headline)
                                        Spacer()
                                        Text(String(format: "%.1f%%", item.rate * 100))
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal)
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
            .padding(.top)  // 다이나믹 아일랜드 밑으로 간격을 주기 위해 padding 추가
        }
        
        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: currentDate)
        }
        
        func formatTimeInterval(_ timeInterval: TimeInterval) -> String {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .abbreviated
            formatter.zeroFormattingBehavior = .pad
            
            if timeInterval < 60 {
                formatter.allowedUnits = [.second]
            } else if timeInterval < 3600 {
                formatter.allowedUnits = [.minute, .second]
            } else {
                formatter.allowedUnits = [.hour, .minute, .second]
            }
            
            return formatter.string(from: timeInterval)!
        }
        
        
        var totalAchievementRate: Double {
            let plannedTime = GraphDataHelper.calculateTotalPlannedTime(dateKey:currentDateKey)
            let achievedTime = GraphDataHelper.calculateTotalAchievedTime(dateKey:currentDateKey)
            if plannedTime == .zero {
                return 0
            } else {
                return achievedTime / plannedTime
            }
            
        }
        
        func changeDate(by days: Int) {
            if let newDate = Calendar.current.date(
                byAdding: .day,
                value: days,
                to: currentDate
            ) {
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
                focusEntries = GraphDataHelper.loadFocusEntries(dateKey:currentDateKey)
            } else {
                achievementRates = GraphDataHelper.calculateAchievementRatesByTask(dateKey:currentDateKey)
            }
        }
        
        
        
        
        
        
        var focusSummary: some View {
            let stats = focusStats()
            return VStack(alignment: .leading, spacing: 6) {  // VStack의 alignment를 .leading으로 변경
                Text("Average Focus: \(String(format: "%.1f", stats.avg))")
                Text(
                    "Best Hour: \(stats.best.map { "\($0):00 ~ \($0 + 1):00" } ?? "-")"
                )
                Text(
                    "Worst Hour: \(stats.worst.map { "\($0):00 ~ \($0 + 1):00" } ?? "-")"
                )
            }
            .font(.subheadline)
            .padding(.top, 8)
            .padding(.horizontal)  // focusSummary에도 horizontal padding 추가
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



struct TaskAchievement: Identifiable {
    let id: UUID
    let task: TaskItem
    var achievedTime: TimeInterval
    var plannedTime: TimeInterval
    var rate: Double {
        plannedTime > 0 ? achievedTime / plannedTime : 0
    }
}

#Preview {
    GraphView(currentDate: Date())
}
