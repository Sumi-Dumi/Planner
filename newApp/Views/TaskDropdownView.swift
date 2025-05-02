import SwiftUI

struct TaskDropdownOverlay: View {
    let tasks: [TaskItem]
    @Binding var selectedTask: TaskItem?
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 6) {

            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(selectedTask?.name ?? "Select Task")
                        .foregroundColor(.blue)
                    Spacer()
                    Circle()
                        .fill(selectedTask?.color ?? .gray)
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1))
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                )
            }


        }
    }
}
