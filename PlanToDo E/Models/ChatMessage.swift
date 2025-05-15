import Foundation
import SwiftUI

// 定义消息角色枚举
enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

// 简单版本的消息模型（不使用CoreData）
struct ChatMessage: Identifiable, Hashable {
    let id: UUID
    let content: String
    let timestamp: Date
    let role: MessageRole
    let requiresConfirmation: Bool
    let operationType: OperationType?
    let operationDetails: OperationDetails?
    
    init(id: UUID = UUID(), content: String, timestamp: Date = Date(), role: MessageRole, requiresConfirmation: Bool = false, operationType: OperationType? = nil, operationDetails: OperationDetails? = nil) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.role = role
        self.requiresConfirmation = requiresConfirmation
        self.operationType = operationType
        self.operationDetails = operationDetails
    }
    
    // 创建用户消息
    static func userMessage(_ content: String) -> ChatMessage {
        return ChatMessage(content: content, role: .user)
    }
    
    // 创建AI消息
    static func aiMessage(_ content: String, requiresConfirmation: Bool = false, operationType: OperationType? = nil, operationDetails: OperationDetails? = nil) -> ChatMessage {
        return ChatMessage(content: content, role: .assistant, requiresConfirmation: requiresConfirmation, operationType: operationType, operationDetails: operationDetails)
    }
    
    // 计算属性
    var isFromUser: Bool {
        return role == .user
    }
}

// 操作类型
enum OperationType: String, Codable, Hashable {
    case createTask = "CREATE_TASK"       // 创建任务
    case completeTask = "COMPLETE_TASK"   // 完成任务
    case updateTask = "UPDATE_TASK"       // 更新任务
    case deleteTask = "DELETE_TASK"       // 删除任务
    case createCategory = "CREATE_CATEGORY" // 创建分类
    case generatePlan = "GENERATE_PLAN"   // 生成计划
    case analytics = "ANALYTICS"          // 分析数据
    case other = "OTHER"                  // 其他操作
    
    var description: String {
        switch self {
        case .createTask:
            return "创建任务"
        case .completeTask:
            return "完成任务"
        case .updateTask:
            return "更新任务信息"
        case .deleteTask:
            return "删除任务"
        case .createCategory:
            return "创建新分类"
        case .generatePlan:
            return "生成行动计划"
        case .analytics:
            return "分析任务数据"
        case .other:
            return "其他操作"
        }
    }
    
    var confirmationRequired: Bool {
        switch self {
        case .deleteTask:
            return true
        case .completeTask:
            return true
        case .createTask, .updateTask, .createCategory, .generatePlan, .analytics, .other:
            return false
        }
    }
}

// 为了实现跨平台兼容的操作细节存储
// 使用Codable和Hashable协议以确保可以在各平台上使用
struct OperationDetails: Codable, Hashable {
    var values: [String: String]
    
    subscript(key: String) -> String? {
        get { return values[key] }
        set { values[key] = newValue }
    }
    
    init(values: [String: String] = [:]) {
        self.values = values
    }
    
    // 便捷初始化方法
    init(taskId: String? = nil, name: String? = nil, description: String? = nil, dueDate: String? = nil, operationType: OperationType? = nil) {
        var initialValues: [String: String] = [:]
        
        if let taskId = taskId {
            initialValues["taskId"] = taskId
        }
        
        if let name = name {
            initialValues["name"] = name
        }
        
        if let description = description {
            initialValues["description"] = description
        }
        
        if let dueDate = dueDate {
            initialValues["dueDate"] = dueDate
        }
        
        if let operationType = operationType {
            initialValues["operationType"] = operationType.rawValue
        }
        
        self.values = initialValues
    }
    
    // 添加支持Date类型的dueDate初始化方法
    init(taskId: String? = nil, name: String? = nil, description: String? = nil, dueDate: Date? = nil, operationType: OperationType? = nil) {
        var initialValues: [String: String] = [:]
        
        if let taskId = taskId {
            initialValues["taskId"] = taskId
        }
        
        if let name = name {
            initialValues["name"] = name
        }
        
        if let description = description {
            initialValues["description"] = description
        }
        
        if let dueDate = dueDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            initialValues["dueDate"] = dateFormatter.string(from: dueDate)
        }
        
        if let operationType = operationType {
            initialValues["operationType"] = operationType.rawValue
        }
        
        self.values = initialValues
    }
    
    // 便捷属性访问器
    var taskId: String? {
        return self["taskId"]
    }
    
    var name: String? {
        return self["name"]
    }
    
    var description: String? {
        return self["description"]
    }
    
    var dueDate: String? {
        return self["dueDate"]
    }
    
    // 添加Date类型的dueDate访问器
    var dueDateAsDate: Date? {
        guard let dateString = self["dueDate"] else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: dateString)
    }
    
    var operationType: OperationType? {
        if let typeString = self["operationType"] {
            return OperationType(rawValue: typeString)
        }
        return nil
    }
}

// 操作确认模型
struct OperationConfirmation: Identifiable, Hashable {
    let id: UUID
    let message: ChatMessage
    let operationDetails: OperationDetails
    let confirmationTimeLimit: TimeInterval
    let createdAt: Date
    
    var isExpired: Bool {
        return Date().timeIntervalSince(createdAt) > confirmationTimeLimit
    }
    
    init(id: UUID = UUID(), message: ChatMessage, operationDetails: OperationDetails, confirmationTimeLimit: TimeInterval = 30, createdAt: Date = Date()) {
        self.id = id
        self.message = message
        self.operationDetails = operationDetails
        self.confirmationTimeLimit = confirmationTimeLimit
        self.createdAt = createdAt
    }
} 