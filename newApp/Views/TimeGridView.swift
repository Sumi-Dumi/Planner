import SwiftUI

struct TimeGridView: View {
    @Binding var currentDate: Date
    //    @State private var editingDate: Date

    @Environment(\.dismiss) var dismiss

    @State private var tasks: [TaskItem] = []
    @State private var selectedTask: TaskItem? = nil
    @State private var isDropdownExpanded: Bool = false

    @State private var filledCells: [CellCoord: TaskItem] = [:]
    @State private var savedData: [String: [CellCoord: TaskItem]] = [:]

    @State private var dropdownOrigin: CGPoint = .zero
    @State private var dropdownWidth: CGFloat = 0

    let hours = (4..<24).map { "\($0)" } + (0..<4).map { "\($0)" }
    let cellWidth: CGFloat = 56
    let cellHeight: CGFloat = 26
    let hourLabelWidth: CGFloat = 30

    init(currentDate: Binding<Date>) {
        self._currentDate = currentDate
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 12) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.red)
                            .font(.title2)
                    }

                    Spacer()

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

                    Spacer()
                }
                .padding(.horizontal)

                HStack {
                    Button(action: {
                        withAnimation {
                            isDropdownExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Text(selectedTask?.name ?? "Select Task")
                                .foregroundColor(.blue)
                            Spacer()
                            if let task = selectedTask {
                                Circle()
                                    .fill(task.color)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle().stroke(
                                            Color.black,
                                            lineWidth: 1
                                        )
                                    )
                            }
                            Image(
                                systemName: isDropdownExpanded
                                    ? "chevron.up" : "chevron.down"
                            )
                            .foregroundColor(.black)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        DispatchQueue.main.async {
                                            dropdownOrigin =
                                                geo.frame(in: .global).origin
                                            dropdownWidth = geo.size.width
                                        }
                                    }
                                    .onChange(of: isDropdownExpanded) {
                                        DispatchQueue.main.async {
                                            dropdownOrigin =
                                                geo.frame(in: .global).origin
                                            dropdownWidth = geo.size.width
                                        }
                                    }

                            }
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                        )
                    }
                }
                .padding(.horizontal)
                GeometryReader { _ in
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(hours.indices, id: \.self) { rowIndex in
                                HStack(spacing: 0) {
                                    Text("\(hours[rowIndex])")
                                        .frame(
                                            width: hourLabelWidth,
                                            height: cellHeight
                                        )
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                        .border(
                                            Color.gray.opacity(0.3),
                                            width: 1
                                        )

                                    ZStack(alignment: .topLeading) {
                                        HStack(spacing: 0) {
                                            ForEach(0..<6, id: \.self) { _ in
                                                Rectangle()
                                                    .strokeBorder(
                                                        Color.gray.opacity(0.3),
                                                        lineWidth: 1
                                                    )
                                                    .frame(
                                                        width: cellWidth,
                                                        height: cellHeight
                                                    )
                                            }
                                        }

                                        ForEach(barSpansForRow(rowIndex)) {
                                            span in
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(
                                                    span.task.color.opacity(0.5)
                                                )
                                                .frame(
                                                    width: CGFloat(span.span)
                                                        * cellWidth - 4,
                                                    height: 16
                                                )
                                                .offset(
                                                    x: CGFloat(span.startCol)
                                                        * cellWidth + 2,
                                                    y: (cellHeight - 16) / 2
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        .background(
                            DragDetector(
                                cellWidth: cellWidth,
                                cellHeight: cellHeight,
                                labelWidth: hourLabelWidth,
                                rowCount: hours.count,
                                colCount: 6,
                                selectedTask: $selectedTask,
                                filledCells: $filledCells
                            )
                        )
                    }
                }
                .frame(maxHeight: .infinity)

            }
            .padding(.horizontal)

            if isDropdownExpanded {

                VStack(spacing: 8) {
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
                                    .overlay(
                                        Circle().stroke(
                                            Color.black,
                                            lineWidth: 1
                                        )
                                    )
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                        }
                    }
                }
                .frame(width: dropdownWidth)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 4)
                .position(
                    x: dropdownOrigin.x + dropdownWidth / 2,
                    y: dropdownOrigin.y + 70
                )
            }
        }
        .onAppear {
            loadTasks()
            if tasks.count != 0 {
                selectedTask = tasks[0]
            }
            loadSavedData(for: currentDate)
        }
        .onChange(of: filledCells) {
            saveCurrentGrid()
        }
        .onChange(of: currentDate) {

            loadSavedData(for: currentDate)
        }
        .navigationBarBackButtonHidden(true)
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
        if let newDate = Calendar.current.date(
            byAdding: .day,
            value: days,
            to: currentDate
        ) {
            currentDate = newDate
        }
    }

    func saveCurrentGrid() {
        savedData[currentDateKey] = filledCells
        saveToUserDefaults()
    }

    func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(savedData) {
            UserDefaults.standard.set(encoded, forKey: "SavedGridData")
        }
    }

    func loadSavedData(for date: Date) {
        if let data = UserDefaults.standard.data(forKey: "SavedGridData"),
            let decoded = try? JSONDecoder().decode(
                [String: [CellCoord: TaskItem]].self,
                from: data
            )
        {
            savedData = decoded
            let key = {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                return f.string(from: date)
            }()
            filledCells = savedData[key] ?? [:]
        }
    }

    func loadTasks() {
        if let saved = UserDefaults.standard.data(forKey: "SavedTasks"),
            let decoded = try? JSONDecoder().decode(
                [TaskItem].self,
                from: saved
            )
        {
            tasks = decoded
        }
    }

    func barSpansForRow(_ row: Int) -> [BarSpan] {
        var spans: [BarSpan] = []
        var col = 0
        while col < 6 {
            let key = CellCoord(row: row, col: col)
            guard let task = filledCells[key] else {
                col += 1
                continue
            }

            var span = 1
            while col + span < 6,
                filledCells[CellCoord(row: row, col: col + span)] == task
            {
                span += 1
            }

            spans.append(
                BarSpan(row: row, startCol: col, span: span, task: task)
            )
            col += span
        }
        return spans
    }
}

#Preview {
    TimeGridView(currentDate: .constant(Date()))
}
