import Foundation
import SwiftUI

// 简单版本的消息模型（不使用CoreData）
struct ChatMessage: Identifiable, Hashable {
    let id: UUID
    let content: String
    let timestamp: Date
    let isFromUser: Bool
    let requiresConfirmation: Bool
    let operationType: OperationType?
    
    init(id: UUID = UUID(), content: String, timestamp: Date = Date(), isFromUser: Bool, requiresConfirmation: Bool = false, operationType: OperationType? = nil) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isFromUser = isFromUser
        self.requiresConfirmation = requiresConfirmation
        self.operationType = operationType
    }
    
    // 创建用户消息
    static func userMessage(_ content: String) -> ChatMessage {
        return ChatMessage(content: content, isFromUser: true)
    }
    
    // 创建AI消息
    static func aiMessage(_ content: String, requiresConfirmation: Bool = false, operationType: OperationType? = nil) -> ChatMessage {
        return ChatMessage(content: content, isFromUser: false, requiresConfirmation: requiresConfirmation, operationType: operationType)
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
        }
    }
    
    var confirmationRequired: Bool {
        switch self {
        case .deleteTask:
            return true
        case .completeTask:
            return true
        case .createTask, .updateTask, .createCategory, .generatePlan, .analytics:
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