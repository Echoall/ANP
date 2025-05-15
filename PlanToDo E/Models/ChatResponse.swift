import Foundation

/// 聊天响应模型
public struct ChatResponse {
    /// 聊天消息
    public let message: ChatMessage
    /// 是否需要确认
    public let requiresConfirmation: Bool
    /// 操作类型
    public let operationType: OperationType?
    /// 操作详情
    public let operationDetails: [String: Any]?
    
    public init(
        message: ChatMessage,
        requiresConfirmation: Bool,
        operationType: OperationType? = nil,
        operationDetails: [String: Any]? = nil
    ) {
        self.message = message
        self.requiresConfirmation = requiresConfirmation
        self.operationType = operationType
        self.operationDetails = operationDetails
    }
    
    /// 创建一个简单的响应
    /// - Parameter text: 响应文本
    /// - Returns: 不需要确认的简单响应
    public static func simple(_ text: String) -> ChatResponse {
        return ChatResponse(
            message: ChatMessage.aiMessage(text),
            requiresConfirmation: false
        )
    }
    
    /// 创建一个需要确认的响应
    /// - Parameters:
    ///   - text: 响应文本
    ///   - type: 操作类型
    ///   - details: 操作详情
    /// - Returns: 需要确认的响应
    public static func withConfirmation(
        _ text: String,
        type: OperationType,
        details: [String: Any]? = nil
    ) -> ChatResponse {
        return ChatResponse(
            message: ChatMessage.aiMessage(text, requiresConfirmation: true, operationType: type),
            requiresConfirmation: true,
            operationType: type,
            operationDetails: details
        )
    }
}