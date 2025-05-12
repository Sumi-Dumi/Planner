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
    let cellWidth: CGFloat = 50
    let cellHeight: CGFloat = 25
    var brown: Color {
        Color(hex: "#d5bca6")
    }

    var darkBrown: Color {
        Color(hex: "#a07e60")
    }

    var lightBrown: Color {
        brown.opacity(0.08)
    }
    let dustyPink = Color(hex: "#e3b7b7")



    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color(hex: "#b99a88").edgesIgnoringSafeArea(.all)

                VStack {
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .cornerRadius(20)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .padding(.horizontal, 10)

                VStack(spacing: 12) {
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

                        DatePicker(
                            "Date",
                            selection: $currentDate,
                            displayedComponents: [.date]
                        ).labelsHidden()

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
                    .padding(.top, 30)
                    .padding(.horizontal, 8)

                    HStack {
                        Button(action: {
                            isDropdownExpanded.toggle()
                        }) {
                            HStack {
                                Text(selectedTask?.name ?? "All Tasks")
                                    .foregroundColor(Color(hex: "#333333"))
                                Spacer()
                                Image(systemName: isDropdownExpanded ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
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
                            .frame(width: 296)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "#333333").opacity(0.5), lineWidth: 2)
                            )
                        }
                    }
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

                    HStack(spacing: 17) {
                        Button(action: { showPlan.toggle() }) {
                            Text("PLANNED")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 28)
                                .foregroundColor(showPlan ? .white : darkBrown)
                                .background(showPlan ? dustyPink : lightBrown)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(darkBrown, lineWidth: 2)
                                )
                                .cornerRadius(15)
                        }

                        Button(action: { showAchieve.toggle() }) {
                            Text("ACHIEVED")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 28)
                                .foregroundColor(showAchieve ? .white : darkBrown)
                                .background(showAchieve ? dustyPink : lightBrown)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(darkBrown, lineWidth: 2)
                                )
                                .cornerRadius(15)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)






                    Button {
                        if tasks.isEmpty {
                            showErrorPopup = true
                        } else {
                            navigationPath.append("timeGridView")
                        }
                    } label: {
                        Text("PLAN")
                            .fontWeight(.bold)
                            .frame(maxWidth: 150)
                            .padding(7)
                            .background(Color(hex: "#5c4033"))
                            .cornerRadius(15)
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 23)
                    .alert(isPresented: $showErrorPopup) {
                        Alert(
                            title: Text("No Task Available"),
                            message: Text("Please create a task first."),
                            dismissButton: .default(Text("OK"))
                        )
                    }

                }

                if isDropdownExpanded {
                    VStack(spacing: 8) {
                        Button(action: {
                            selectedTask = nil
                            isDropdownExpanded = false
                        }) {
                            HStack {
                                Text("All Tasks").foregroundColor(Color(hex: "#333333"))
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
                                    Text(task.name).foregroundColor(Color(hex: "#333333"))
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

    func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: currentDate) {
            currentDate = newDate
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

struct ToggleTag: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(isOn ? Color(hex: "#d5bca6") : Color.gray.opacity(0.2))
            .cornerRadius(20)
            .foregroundColor(Color(hex: "#333333"))
            .onTapGesture {
                isOn.toggle()
            }
    }
}


#Preview {
    MainView()
}
