import SwiftUI
import Combine

struct TimerView: View {
    @State private var tasks: [TaskItem] = []
    @State private var selectedTask: TaskItem? = nil
    @State private var isDropdownExpanded: Bool = false
    @State private var dropdownFrame: CGRect = .zero

    @State private var hours: Int = 0
    @State private var minutes: Int = 30

    @State private var timeRemaining: Int = 0
    @State private var timerRunning = false
    @State private var timer: AnyCancellable?

    @State private var sessionStartTime: Date?


    @State private var showFocusPopup = false
    @State private var lastSessionID: UUID?
    @State private var focusRating: Int = 0

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                // 드롭다운
                Button(action: {
                    isDropdownExpanded.toggle()
                }) {
                    HStack {
                        Text(selectedTask?.name ?? "Select Task")
                            .foregroundColor(.blue)
                        Spacer()
                        if let task = selectedTask {
                            Circle()
                                .fill(task.color)
                                .frame(width: 24, height: 24)
                                .overlay(Circle().stroke(Color.black, lineWidth: 1))
                        }
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

                // 시간 선택 피커
                HStack {
                    Picker("", selection: $hours) {
                        ForEach(0..<6) { Text("\($0) h") }
                    }
                    .frame(width: 80)
                    .clipped()

                    Picker("", selection: $minutes) {
                        ForEach([0, 10, 20, 30, 40, 50], id: \.self) { Text("\($0) m") }
                    }
                    .frame(width: 80)
                    .clipped()
                }
                .pickerStyle(WheelPickerStyle())

                Text(timeString(from: timeRemaining))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))

                // 버튼
                HStack(spacing: 20) {
                    if !timerRunning {
                        Button("Start") {
                            startTimer()
                        }
                        .font(.title2)
                    } else {
                        Button("Pause") {
                            pauseTimer()
                        }
                        .font(.title2)

                        Button("Stop") {
                            stopTimer()
                        }
                        .font(.title2)
                    }
                }

                Spacer()
            }
            .padding()
            .onAppear(perform: loadTasks)

            // 드롭다운 리스트
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
                                    .overlay(Circle().stroke(Color.black, lineWidth: 1))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                        }
                    }
                }
                .frame(width: dropdownFrame.width)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 4)
                .position(x: dropdownFrame.midX, y: dropdownFrame.maxY + 62)
            }

            // ⭐️ 포커스 레이팅 팝업
            if showFocusPopup {
                Color.black.opacity(0.3).ignoresSafeArea()
                FocusPopupView(rating: $focusRating, onRate: {
                    saveFocusRating()
                    showFocusPopup = false
                })
                .frame(width: 320)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 6)
            }
        }
    }

    func startTimer() {
        guard let task = selectedTask else { return }
        let totalSeconds = (hours * 60 + minutes) * 60
        timeRemaining = totalSeconds
        sessionStartTime = Date()
        timerRunning = true

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    stopTimer()
                }
            }
    }

    func pauseTimer() {
        if let task = selectedTask, let start = sessionStartTime {
            let sessionID = saveSession(task: task, start: start, end: Date())
            lastSessionID = sessionID
            showFocusPopup = true
        }
        timer?.cancel()
        timer = nil
        timerRunning = false
        sessionStartTime = nil
    }

    func stopTimer() {
        if let task = selectedTask, let start = sessionStartTime {
            let sessionID = saveSession(task: task, start: start, end: Date())
            lastSessionID = sessionID
            showFocusPopup = true
        }
        timer?.cancel()
        timer = nil
        timerRunning = false
        sessionStartTime = nil
        timeRemaining = 0
    }

    func saveSession(task: TaskItem, start: Date, end: Date) -> UUID {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: start)

        let sessionID = UUID()
        let newSession = TimerSession(
            id: sessionID,
            task: task,
            date: dateStr,
            startTime: start,
            endTime: end,
            focusRating: nil
        )

        var saved: [TimerSession] = []
        if let data = UserDefaults.standard.data(forKey: "SavedTimerSessions"),
           let decoded = try? JSONDecoder().decode([TimerSession].self, from: data) {
            saved = decoded
        }
        saved.append(newSession)

        if let encoded = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(encoded, forKey: "SavedTimerSessions")
        }

        print("Saved: \(task.name) from \(start) to \(end)")
        return sessionID
    }

    func saveFocusRating() {
        guard let id = lastSessionID else { return }
        guard focusRating > 0 else { return }

        var saved: [TimerSession] = []
        if let data = UserDefaults.standard.data(forKey: "SavedTimerSessions"),
           let decoded = try? JSONDecoder().decode([TimerSession].self, from: data) {
            saved = decoded
        }

        if let index = saved.firstIndex(where: { $0.id == id }) {
            saved[index].focusRating = focusRating
        }

        if let encoded = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(encoded, forKey: "SavedTimerSessions")
        }

        print("Focus rating \(focusRating)/10 saved for session \(id)")
    }

    func loadTasks() {
        if let saved = UserDefaults.standard.data(forKey: "SavedTasks"),
           let decoded = try? JSONDecoder().decode([TaskItem].self, from: saved) {
            tasks = decoded
        }
    }

    func timeString(from seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

#Preview {
    TimerView()
}
