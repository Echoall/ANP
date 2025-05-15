import Foundation

// 存储服务相关的错误类型
enum StorageError: Error {
    case dataNotFound      // 数据未找到
    case encodingError     // 编码错误
    case decodingError     // 解码错误
    case saveFailed        // 保存失败
    case deleteFailed      // 删除失败
    case invalidData       // 无效数据
    case networkError      // 网络错误
    case authError         // 认证错误
    case unknownError      // 未知错误
    
    var localizedDescription: String {
        switch self {
        case .dataNotFound:
            return "请求的数据未找到"
        case .encodingError:
            return "数据编码失败"
        case .decodingError:
            return "数据解码失败"
        case .saveFailed:
            return "数据保存失败"
        case .deleteFailed:
            return "数据删除失败"
        case .invalidData:
            return "数据格式无效"
        case .networkError:
            return "网络连接错误"
        case .authError:
            return "认证失败"
        case .unknownError:
            return "发生未知错误"
        }
    }
} 

/// 操作类型枚举
public enum OperationType: String {
    case createTask = "CREATE_TASK"
    case completeTask = "COMPLETE_TASK"
    case updateTask = "UPDATE_TASK"
    case deleteTask = "DELETE_TASK"
    case createCategory = "CREATE_CATEGORY"
    case deleteCategory = "DELETE_CATEGORY"
    case updateCategory = "UPDATE_CATEGORY"
    case generatePlan = "GENERATE_PLAN"
    case analytics = "ANALYTICS"
}

/// 聊天消息类型
public enum ChatMessage {
    case userMessage(String)
    case aiMessage(String)
    
    public var text: String {
        switch self {
        case .userMessage(let message), .aiMessage(let message):
            return message
        }
    }
    
    public var isUser: Bool {
        switch self {
        case .userMessage:
            return true
        case .aiMessage:
            return false
        }
    }
}

extension ChatResponse {
    static func simple(_ message: String) -> ChatResponse {
        return ChatResponse(
            message: .aiMessage(message),
            requiresConfirmation: false,
            operationDetails: nil
        )
    }
    
    static func withConfirmation(_ message: String, type: OperationType, details: [String: Any]) -> ChatResponse {
        return ChatResponse(
            message: .aiMessage(message),
            requiresConfirmation: true,
            operationDetails: details
        )
    }
} 