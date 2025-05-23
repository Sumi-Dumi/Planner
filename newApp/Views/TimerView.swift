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
    @State private var totalTime: Int = 0
    @State private var timerRunning = false
    @State private var timer: AnyCancellable?
    @State private var onPause: Bool = false

    @State private var sessionStartTime: Date?

    @State private var showFocusPopup = false
    @State private var lastSessionID: UUID?
    @State private var focusRating: Int = 0

    @State private var showErrorPopup = false

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

            VStack(spacing: 20) {
                Button(action: {
                    isDropdownExpanded.toggle()
                }) {
                    HStack {
                        Text(selectedTask?.name ?? "Select Task")
                            .foregroundColor(Color(hex: "#333333"))
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
                            .stroke(Color(hex: "#333333").opacity(0.5), lineWidth: 2)
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
                .disabled(timerRunning || timeRemaining > 0)

                Text(timeString(from: timeRemaining))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))

                HStack(spacing: 20) {
                    if !timerRunning {
                        Button {
                            startTimer()
                            onPause = false
                        } label: {
                            Text(onPause ? "CONTINUE" : "START")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .frame(width: 120, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(hex: onPause ? "#d8a39d" : "#7b5e57"))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(hex: "#7b5e57"), lineWidth: 2)
                                )
                        }
                        .alert(isPresented: $showErrorPopup) {
                            Alert(
                                title: Text("No Task Selected"),
                                message: Text("Please select a task before starting the timer."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                    } else {
                        Button("PAUSE") {
                            pauseTimer()
                            onPause = true
                        }
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(width: 120, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: "#a8b3a1"))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: "#7b5e57"), lineWidth: 2)
                        )

                        Button("STOP") {
                            stopTimer()
                            onPause = false
                        }
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(width: 120, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: "#b47c7c"))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: "#7b5e57"), lineWidth: 2)
                        )
                    }
                }

                Spacer()
            }
            .padding()
            .padding(.top, 30)
            .onAppear(perform: loadTasks)

            if isDropdownExpanded {
                VStack(spacing: 8) {
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
                .frame(width: dropdownFrame.width)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 4)
                .position(x: dropdownFrame.midX, y: dropdownFrame.maxY + 62)
            }

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
        guard let selectedTask = selectedTask else {
            showErrorPopup = true
            return
        }
        if timeRemaining == 0 {
            totalTime = (hours * 60 + minutes) * 60
            timeRemaining = totalTime
        }
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
        totalTime = 0
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
