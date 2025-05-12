import SwiftUI

struct TaskView: View {
    @State private var newTaskName: String = ""
    @State private var selectedColor: Color = .gray
    @State private var showHeaderColorPicker: Bool = false
    @State private var tasks: [TaskItem] = []
    @State private var editingTaskID: UUID? = nil
    @State private var editingName: String = ""
    @State private var colorPickerTaskID: UUID? = nil
    @State private var colorPickerPosition: CGPoint = .zero
    @State private var colorPickerWidth: CGFloat = 160

    let colorOptions: [Color] = [
        Color(hex: "#f28b82"), Color(hex: "#fbbc04"), Color(hex: "#fff475"),
        Color(hex: "#ccff90"), Color(hex: "#a7ffeb"), Color(hex: "#aecbfa"),
        Color(hex: "#d7aefb"), Color(hex: "#fdcfe8"), Color(hex: "#e6e6e6"), Color(hex: "#e0cba8")
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Task")
                        .font(.title2)
                        .foregroundColor(.blue)

                    TextField("Enter task name", text: $newTaskName)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                        )

                    Button {
                        showHeaderColorPicker.toggle()
                        colorPickerTaskID = nil
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

                ForEach(tasks) { task in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if editingTaskID == task.id {
                                TextField("Edit task", text: $editingName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onSubmit {
                                        saveEditedTask(task.id)
                                    }
                            } else {
                                Text(task.name)
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }

                            Spacer()

                            Button {
                                editingTaskID = task.id
                                editingName = task.name
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                            }

                            Button {
                                if colorPickerTaskID == task.id {
                                    colorPickerTaskID = nil
                                } else {
                                    colorPickerTaskID = task.id
                                    showHeaderColorPicker = false
                                }
                            } label: {
                                Circle()
                                    .fill(task.color)
                                    .frame(width: 32, height: 32)
                                    .overlay(Circle().stroke(Color.black, lineWidth: 1))
                            }
                        }

                        if editingTaskID == task.id {
                            HStack {
                                Button("Save") {
                                    saveEditedTask(task.id)
                                }
                                Button("Delete") {
                                    deleteTask(task.id)
                                }
                                Button("Cancel") {
                                    editingTaskID = nil
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()

            if showHeaderColorPicker || colorPickerTaskID != nil {
                VStack(spacing: 12) {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(32), spacing: 12), count: 5), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(Color.black.opacity(0.5), lineWidth: 1))
                                .onTapGesture {
                                    if let id = colorPickerTaskID,
                                       let index = tasks.firstIndex(where: { $0.id == id }) {
                                        tasks[index].colorHex = color.toHex()
                                        saveTasks()
                                        colorPickerTaskID = nil
                                    } else {
                                        selectedColor = color
                                        showHeaderColorPicker = false
                                    }
                                }
                        }
                    }
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 4)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 150)
            }
        }
        .onTapGesture {
            if showHeaderColorPicker { showHeaderColorPicker = false }
            if colorPickerTaskID != nil { colorPickerTaskID = nil }
        }
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

    private func saveEditedTask(_ id: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].name = editingName
            editingTaskID = nil
            saveTasks()
        }
    }

    private func deleteTask(_ id: UUID) {
        tasks.removeAll { $0.id == id }
        editingTaskID = nil
        colorPickerTaskID = nil
        saveTasks()
    }
}

#Preview {
    TaskView()
}
