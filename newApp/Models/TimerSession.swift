import Foundation

struct TimerSession: Codable, Identifiable {
    let id: UUID
    let task: TaskItem
    let date: String
    let startTime: Date
    let endTime: Date
    var focusRating: Int? 
}
