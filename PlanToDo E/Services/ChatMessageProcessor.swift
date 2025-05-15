import Foundation
import Combine
import Models

/// 聊天消息处理器错误
public enum ChatMessageProcessorError: Error {
    case invalidMessage
    case processingFailed
    case networkError
    case apiError(String)
    
    public var localizedDescription: String {
        switch self {
        case .invalidMessage:
            return "无效的消息格式"
        case .processingFailed:
            return "消息处理失败"
        case .networkError:
            return "网络连接错误"
        case .apiError(let message):
            return "API错误: \(message)"
        }
    }
}

/// 消息处理器协议
public protocol ChatMessageProcessorProtocol {
    /// 处理用户输入的消息并生成响应
    func processMessage(_ text: String) -> AnyPublisher<ChatResponse, Error>
    
    /// 执行确认的操作
    func executeOperation(_ details: [String: Any]) -> AnyPublisher<String, Error>
}

/// 聊天消息处理器 - 处理用户输入并生成响应
public class ChatMessageProcessor: ChatMessageProcessorProtocol {
    // MARK: - 属性
    /// AI处理器
    private let aiProcessor = AIProcessor()
    /// 取消标记存储
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    public init() {
        print("ChatMessageProcessor 初始化")
    }
    
    // MARK: - ChatMessageProcessorProtocol
    public func processMessage(_ text: String) -> AnyPublisher<ChatResponse, Error> {
        return aiProcessor.processMessage(text)
            .map { response -> ChatResponse in
                return ChatResponse(
                    message: ChatMessage.aiMessage(response),
                    requiresConfirmation: false
                )
            }
            .eraseToAnyPublisher()
    }
    
    public func executeOperation(_ details: [String: Any]) -> AnyPublisher<String, Error> {
        // 获取操作类型
        guard let type = details["type"] as? String else {
            return Fail(error: ChatMessageProcessorError.invalidMessage).eraseToAnyPublisher()
        }
        
        // 根据不同类型执行不同操作
        switch type {
        case "CREATE_TASK":
            let title = details["title"] as? String ?? "无标题任务"
            return Just("已成功创建任务：\(title)")
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            
        case "COMPLETE_TASK":
            return Just("已将任务标记为完成")
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            
        case "UPDATE_TASK":
            return Just("任务已更新")
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            
        case "DELETE_TASK":
            return Just("任务已删除")
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            
        default:
            return Fail(error: ChatMessageProcessorError.invalidMessage).eraseToAnyPublisher()
        }
    }
}

/// 消息处理错误类型
enum MessageProcessingError: Error {
    case processingFailed(String)
    case invalidOperation(String)
    case operationExecutionFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .processingFailed(let message):
            return "消息处理失败: \(message)"
        case .invalidOperation(let message):
            return "无效的操作: \(message)"
        case .operationExecutionFailed(let message):
            return "操作执行失败: \(message)"
        }
    }
}

/// 处理用户消息的返回结果
struct ChatResponse {
    let message: ChatMessage
    let requiresConfirmation: Bool
    let operationDetails: [String: Any]?
}

/// 默认的消息处理器实现
public class DefaultChatMessageProcessor: ChatMessageProcessorProtocol {
    private let mockResponses: Bool
    private let mockAPIProvider: MockAPIProvider?
    
    public init(mockResponses: Bool = false) {
        self.mockResponses = mockResponses
        self.mockAPIProvider = mockResponses ? MockAPIProvider() : nil
    }
    
    public func processMessage(_ text: String) -> AnyPublisher<ChatResponse, Error> {
        if mockResponses {
            return processMockMessage(text)
        }
        
        // 使用实际的消息处理逻辑
        return Future<ChatResponse, Error> { promise in
            let response = ChatResponse.simple("我收到了您的消息：\(text)")
            promise(.success(response))
        }
        .eraseToAnyPublisher()
    }
    
    public func executeOperation(_ details: [String: Any]) -> AnyPublisher<String, Error> {
        guard let typeString = details["type"] as? String,
              let type = OperationType(rawValue: typeString) else {
            return Fail(error: ChatMessageProcessorError.invalidMessage).eraseToAnyPublisher()
        }
        
        return Future<String, Error> { promise in
            switch type {
            case .createTask:
                let title = details["title"] as? String ?? "新任务"
                promise(.success("已创建任务：\(title)"))
            case .completeTask:
                promise(.success("任务已标记为完成"))
            case .updateTask:
                promise(.success("任务已更新"))
            case .deleteTask:
                promise(.success("任务已删除"))
            case .createCategory:
                promise(.success("分类已创建"))
            case .deleteCategory:
                promise(.success("分类已删除"))
            case .updateCategory:
                promise(.success("分类已更新"))
            case .generatePlan:
                promise(.success("计划已生成"))
            case .analytics:
                promise(.success("分析已完成"))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func processMockMessage(_ text: String) -> AnyPublisher<ChatResponse, Error> {
        guard let mockAPIProvider = mockAPIProvider else {
            return Fail(error: ChatMessageProcessorError.processingFailed).eraseToAnyPublisher()
        }
        
        let messages = [QwenMessage(role: "user", content: text)]
        return mockAPIProvider.mockChatResponse(messages: messages)
            .map { response -> ChatResponse in
                let (operationType, details) = self.analyzeResponse(response.output.text)
                
                if let type = operationType {
                    return ChatResponse.withConfirmation(response.output.text, type: type, details: details)
                } else {
                    return ChatResponse.simple(response.output.text)
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func analyzeResponse(_ text: String) -> (OperationType?, [String: Any]) {
        var operationType: OperationType? = nil
        var details: [String: Any] = [:]
        
        if text.contains("任务") {
            operationType = .createTask
            details = [
                "type": OperationType.createTask.rawValue,
                "title": "新任务",
                "description": "从AI助手创建的任务"
            ]
        }
        
        return (operationType, details)
    }
} 