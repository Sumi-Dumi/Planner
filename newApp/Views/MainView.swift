import SwiftUI

struct MainView: View {
    @State private var currentDate: Date = Date()
    @State private var selectedTask: TaskItem? = nil
    @State private var tasks: [TaskItem] = []
    @State private var isDropdownExpanded: Bool = false
    @State private var dropdownFrame: CGRect = .zero

    @State private var showPlan: Bool = true
    @State private var showAchieve: Bool = true
    
    @State private var showErrorPopup = false
    
    @State private var navigationPath: [String] = []
    

    let hours = (4..<24).map { "\($0)" } + (0..<4).map { "\($0)" }
    let hourLabelWidth: CGFloat = 40
    let cellWidth: CGFloat = 56
    let cellHeight: CGFloat = 28

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 12) {
                    HStack {
                        Button(action: { changeDate(by: -1) }) {
                            Image(systemName: "chevron.left").font(.title2)
                        }
                        Spacer()
                        DatePicker(
                            "Date",
                            selection: $currentDate,
                            displayedComponents: [.date]
                        ).labelsHidden()
                        Spacer()
                        Button(action: { changeDate(by: 1) }) {
                            Image(systemName: "chevron.right").font(.title2)
                        }
                    }
                    .padding(.horizontal)

                    Button(action: {
                        isDropdownExpanded.toggle()
                    }) {
                        HStack {
                            Text(selectedTask?.name ?? "All Tasks")
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: isDropdownExpanded ? "chevron.up" : "chevron.down")
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                        )
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    dropdownFrame = geo.frame(in: .global)
                                }
                                .onChange(of: isDropdownExpanded) {
                                    dropdownFrame = geo.frame(in: .global)
                                }
                        }
                    )
                    .padding(.horizontal)

                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(hours.indices, id: \.self) { row in
                                HStack(spacing: 0) {
                                    Text("\(hours[row])")
                                        .frame(width: hourLabelWidth, height: cellHeight)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)

                                    ZStack(alignment: .topLeading) {
                                        HStack(spacing: 0) {
                                            ForEach(0..<6, id: \.self) { _ in
                                                Rectangle()
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                    .frame(width: cellWidth, height: cellHeight)
                                            }
                                        }

                                        if showPlan {
                                            ForEach(barSpans(for: plannedData[currentDateKey] ?? [:], row: row)) { span in
                                                if selectedTask == nil || selectedTask == span.task {
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(span.task.color.opacity(0.3))
                                                        .frame(width: CGFloat(span.span) * cellWidth - 4, height: 16)
                                                        .offset(x: CGFloat(span.startCol) * cellWidth + 2, y: (cellHeight - 16)/2)
                                                }
                                            }
                                        }

                                        if showAchieve {
                                            ForEach(barSpans(for: achievedCells(for: currentDateKey), row: row)) { span in
                                                if selectedTask == nil || selectedTask == span.task {
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(span.task.color)
                                                        .frame(width: CGFloat(span.span) * cellWidth - 4, height: 16)
                                                        .offset(x: CGFloat(span.startCol) * cellWidth + 2, y: (cellHeight - 16)/2)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                        }
                    }

                    HStack(spacing: 40) {
                        ToggleCircle(label: "Planned", isOn: $showPlan)
                        ToggleCircle(label: "Achieved", isOn: $showAchieve)
                    }
                    .padding(.top)
                    
                    
                        Button {
                            if tasks.isEmpty {
                                showErrorPopup = true
                            } else {
                                navigationPath.append("timeGridView")
                            }
                            
                        } label: {
                            Text("Plan")
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .font(.title2)
                        .padding()
                        .alert(isPresented: $showErrorPopup) {
                            Alert(
                                title: Text("No Task Available"),
                                message: Text("Please create a task first."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                            
//                    NavigationLink(destination: TimeGridView(currentDate: $currentDate)) {
//                        Text("Plan")
//                            .font(.title2)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.blue.opacity(0.1))
//                            .cornerRadius(10)
//                    }
//                    .padding()
                }

                if isDropdownExpanded {
                    VStack(spacing: 8) {
                        Button(action: {
                            selectedTask = nil
                            isDropdownExpanded = false
                        }) {
                            HStack {
                                Text("All Tasks").foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "circle.grid.cross")
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                        }

                        ForEach(tasks, id: \.id) { task in
                            Button(action: {
                                selectedTask = task
                                isDropdownExpanded = false
                            }) {
                                HStack {
                                    Text(task.name).foregroundColor(.blue)
                                    Spacer()
                                    Circle()
                                        .fill(task.color)
                                        .frame(width: 24, height: 24)
                                        .overlay(Circle().stroke(Color.black, lineWidth: 1))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    .padding()
                    .frame(width: dropdownFrame.width)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 4)
                    .position(x: dropdownFrame.midX, y: dropdownFrame.maxY + 62)
                }
            }
            .onAppear {
                loadTasks()
            }
            .navigationDestination(for: String.self) { valueInPath in
                if valueInPath == "timeGridView" {
                    TimeGridView(currentDate: $currentDate)
                }
            }
        }

    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: currentDate)
    }

    var currentDateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: currentDate)
    }

    func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: currentDate) {
            currentDate = newDate
        }
    }

    func loadTasks() {
        if let saved = UserDefaults.standard.data(forKey: "SavedTasks"),
           let decoded = try? JSONDecoder().decode([TaskItem].self, from: saved) {
            tasks = decoded
        }
    }

    var plannedData: [String: [CellCoord: TaskItem]] {
        guard let data = UserDefaults.standard.data(forKey: "SavedGridData"),
              let decoded = try? JSONDecoder().decode([String: [CellCoord: TaskItem]].self, from: data) else {
            return [:]
        }
        return decoded
    }

    func achievedCells(for dateKey: String) -> [CellCoord: TaskItem] {
        guard let data = UserDefaults.standard.data(forKey: "SavedTimerSessions"),
              let sessions = try? JSONDecoder().decode([TimerSession].self, from: data) else {
            return [:]
        }

        var result: [CellCoord: TaskItem] = [:]
        let calendar = Calendar.current

        for session in sessions where session.date == dateKey {
            let task = session.task
            var start = session.startTime
            let end = session.endTime

            while start < end {
                let components = calendar.dateComponents([.hour, .minute], from: start)
                let totalMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
                let hourIndex = (totalMinutes / 60 + 20) % 24
                let col = (totalMinutes % 60) / 10

                let coord = CellCoord(row: hourIndex, col: col)
                result[coord] = task

                if let next = calendar.date(byAdding: .minute, value: 10, to: start) {
                    start = next
                } else {
                    break
                }
            }
        }

        return result
    }

    func barSpans(for cells: [CellCoord: TaskItem], row: Int) -> [BarSpan] {
        var spans: [BarSpan] = []
        var col = 0
        while col < 6 {
            let key = CellCoord(row: row, col: col)
            guard let task = cells[key] else {
                col += 1
                continue
            }

            var span = 1
            while col + span < 6, cells[CellCoord(row: row, col: col + span)] == task {
                span += 1
            }

            spans.append(BarSpan(row: row, startCol: col, span: span, task: task))
            col += span
        }
        return spans
    }
}

#Preview {
    MainView()
}
