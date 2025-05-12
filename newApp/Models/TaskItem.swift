import SwiftUI

struct TaskItem: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    var name: String
    var colorHex: String

    var color: Color {
        Color(hex: colorHex)
    }

    init(id: UUID = UUID(), name: String, colorHex: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }

    enum CodingKeys: String, CodingKey {
        case id, name, colorHex
    }

    static func == (lhs: TaskItem, rhs: TaskItem) -> Bool {
        return lhs.id == rhs.id
    }
}
