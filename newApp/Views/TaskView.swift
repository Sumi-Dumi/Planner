import SwiftUI

struct TaskView: View {
    @State private var newTaskName: String = ""
    @State private var selectedColor: Color = .gray
    @State private var showColorPicker: Bool = false
    @State private var tasks: [TaskItem] = []

    let colorOptions: [Color] = [
        Color(hex: "#f28b82"), Color(hex: "#fbbc04"), Color(hex: "#fff475"),
        Color(hex: "#ccff90"), Color(hex: "#a7ffeb"), Color(hex: "#aecbfa"),
        Color(hex: "#d7aefb"), Color(hex: "#fdcfe8"), Color(hex: "#e6e6e6"), Color(hex: "#e0cba8")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Task")
                    .font(.title2)
                    .foregroundColor(.blue)

                TextField("type your task", text: $newTaskName)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                    )

                Button {
                    showColorPicker.toggle()
                } label: {
                    Circle()
                        .fill(selectedColor)
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1))
                }

                Button {
                    if !newTaskName.trimmingCharacters(in: .whitespaces).isEmpty {
                        let task = TaskItem(name: newTaskName, colorHex: selectedColor.toHex())
                        tasks.append(task)
                        newTaskName = ""
                        saveTasks()
                    }
                } label: {
                    Circle()
                        .stroke(Color.black, lineWidth: 1)
                        .frame(width: 32, height: 32)
                        .overlay(Image(systemName: "plus").foregroundColor(.blue))
                }
            }

            if showColorPicker {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(32), spacing: 12), count: 5), spacing: 12) {
                    ForEach(colorOptions, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 32, height: 32)
                            .overlay(Circle().stroke(Color.black.opacity(selectedColor == color ? 1 : 0), lineWidth: 2))
                            .onTapGesture {
                                selectedColor = color
                                showColorPicker = false
                            }
                    }
                }
            }

            ForEach(tasks) { task in
                HStack {
                    Text(task.name)
                        .font(.title3)
                        .foregroundColor(.blue)
                    Spacer()
                    Circle()
                        .fill(task.color)
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1))
                }
            }

            Spacer()
        }
        .padding()
        .onAppear(perform: loadTasks)
    }

    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "SavedTasks")
        }
    }

    private func loadTasks() {
        if let savedData = UserDefaults.standard.data(forKey: "SavedTasks"),
           let decoded = try? JSONDecoder().decode([TaskItem].self, from: savedData) {
            self.tasks = decoded
        }
    }
}
#Preview {
    TaskView()
}
