import Foundation
import SwiftUI

enum TaskPriority: String, CaseIterable, Codable, Identifiable {
    case high = "高"
    case medium = "中"
    case low = "低"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .green
        }
    }
    
    var icon: String {
        switch self {
        case .high:
            return "exclamationmark.3"
        case .medium:
            return "exclamationmark.2"
        case .low:
            return "exclamationmark"
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
}

// 子任务结构体
struct SubTask: Identifiable, Codable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

// 添加@unchecked Sendable标记以区分此Task与Swift并发中的Task
struct Task: Identifiable, Codable, @unchecked Sendable {
    var id: UUID
    var categoryId: UUID
    var title: String
    var description: String
    var dueDate: Date
    var priority: TaskPriority
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var reminderDate: Date?
    var subtasks: [SubTask]
    
    // 计算属性，用于检查任务是否有子任务
    var hasSubTasks: Bool {
        return !subtasks.isEmpty
    }
    
    // 计算属性，检查任务是否过期
    var isOverdue: Bool {
        return dueDate < Date() && !isCompleted
    }
    
    init(
        id: UUID = UUID(),
        categoryId: UUID,
        title: String,
        description: String = "",
        dueDate: Date,
        priority: TaskPriority = .medium,
        isCompleted: Bool = false,
        reminderDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        subtasks: [SubTask] = []
    ) {
        self.id = id
        self.categoryId = categoryId
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.reminderDate = reminderDate
        self.subtasks = subtasks
    }
} 