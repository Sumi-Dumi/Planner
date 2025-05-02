import Foundation

struct BarSpan: Identifiable {
    let id = UUID()
    let row: Int
    let startCol: Int
    let span: Int
    let task: TaskItem
}
