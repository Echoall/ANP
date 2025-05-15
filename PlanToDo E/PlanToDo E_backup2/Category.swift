import Foundation

struct Category: Identifiable, Codable {
    var id: UUID
    var name: String
    var color: String
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(),
         name: String,
         color: String = "#007AFF",
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum SpecialCategory: String, Codable {
    case all
    case today
    case upcoming
    case completed
} 