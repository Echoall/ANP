import Foundation

struct Task: Identifiable, Codable {
    var id: UUID
    var title: String
    var description: String?
    var dueDate: Date?
    var isCompleted: Bool
    var priority: TaskPriority
    var categoryId: UUID
    var subtasks: [SubTask]
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), 
         title: String, 
         description: String? = nil, 
         dueDate: Date? = nil, 
         isCompleted: Bool = false, 
         priority: TaskPriority = .medium,
         categoryId: UUID,
         subtasks: [SubTask] = [],
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.priority = priority
        self.categoryId = categoryId
        self.subtasks = subtasks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct SubTask: Identifiable, Codable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(),
         title: String,
         isCompleted: Bool = false,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum TaskPriority: String, Codable {
    case low
    case medium
    case high
} 