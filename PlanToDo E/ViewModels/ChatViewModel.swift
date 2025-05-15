import Foundation
import SwiftUI
import Combine
import Models

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isProcessing: Bool = false
    @Published var pendingConfirmation: OperationConfirmation? = nil
    @Published var showConfirmationTimer: Bool = false
    @Published var remainingTime: TimeInterval = 30
    
    private var cancellables = Set<AnyCancellable>()
    private var confirmationTimer: Timer?
    private var messageProcessor: ChatMessageProcessor
    
    // 加载更多消息的分页参数
    private var currentPage: Int = 1
    private let pageSize: Int = 20
    private var hasMoreMessages: Bool = true
    
    init(messageProcessor: ChatMessageProcessor = DefaultChatMessageProcessor()) {
        self.messageProcessor = messageProcessor
        loadInitialMessages()
        
        // 添加欢迎消息
        if messages.isEmpty {
            let welcomeMessage = ChatMessage.aiMessage(
                "您好，我是您的AI助手。我可以帮助您管理任务、创建计划，或者回答您的问题。有什么我能帮您的吗？"
            )
            messages.append(welcomeMessage)
        }
    }
    
    // 加载初始消息
    private func loadInitialMessages() {
        // 这里可以从本地存储加载最近的消息
        // 简化处理，实际应用中应从数据库加载
    }
    
    // 加载更多历史消息（分页）
    func loadMoreMessages() {
        guard hasMoreMessages && !isProcessing else { return }
        isProcessing = true
        
        // 模拟加载更多消息的延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // 这里应该从持久化存储加载更多历史消息
            // 示例中只是模拟
            self.currentPage += 1
            self.hasMoreMessages = self.currentPage < 5 // 假设总共有5页数据
            self.isProcessing = false
        }
    }
    
    // 发送消息
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // 取消任何正在进行的确认操作
        cancelPendingConfirmation()
        
        // 创建并添加用户消息
        let userMessage = ChatMessage.userMessage(text)
        addMessage(userMessage)
        
        // 标记正在处理
        isProcessing = true
        
        // 处理用户消息并生成回复
        messageProcessor.processMessage(text)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isProcessing = false
                
                if case .failure(let error) = completion {
                    // 处理错误
                    print("消息处理失败: \(error)")
                    let errorMessage = ChatMessage.aiMessage("抱歉，我在处理您的请求时遇到了问题。请稍后再试。")
                    self.addMessage(errorMessage)
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                // 添加AI回复消息
                self.addMessage(response.message)
                
                // 如果需要确认，设置确认操作
                if response.requiresConfirmation, let details = response.operationDetails {
                    self.setupConfirmation(message: response.message, details: details)
                }
                
                // 处理完成
                self.isProcessing = false
            }
            .store(in: &cancellables)
    }
    
    // 添加新消息
    private func addMessage(_ message: ChatMessage) {
        messages.append(message)
        // 滚动到底部（由View层实现）
    }
    
    // 设置需要确认的操作
    private func setupConfirmation(message: ChatMessage, details: [String: Any]) {
        // 创建确认操作对象
        let operationDetails = convertToOperationDetails(details)
        let confirmation = OperationConfirmation(
            message: message,
            operationDetails: operationDetails
        )
        
        pendingConfirmation = confirmation
        remainingTime = confirmation.confirmationTimeLimit
        showConfirmationTimer = true
        
        // 设置倒计时计时器
        confirmationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if self.remainingTime > 0 {
                self.remainingTime -= 1
            } else {
                // 时间到，自动取消确认
                self.cancelConfirmation()
                timer.invalidate()
            }
        }
    }
    
    // 将[String: Any]转换为OperationDetails
    private func convertToOperationDetails(_ details: [String: Any]) -> OperationDetails {
        var stringValues = [String: String]()
        
        for (key, value) in details {
            // 将各种值类型转换为字符串
            if let stringValue = value as? String {
                stringValues[key] = stringValue
            } else if let dateValue = value as? Date {
                // 日期转为ISO格式字符串
                let formatter = ISO8601DateFormatter()
                stringValues[key] = formatter.string(from: dateValue)
            } else if let numberValue = value as? NSNumber {
                stringValues[key] = numberValue.stringValue
            } else if let boolValue = value as? Bool {
                stringValues[key] = boolValue ? "true" : "false"
            } else {
                // 其他类型尝试使用String(describing:)
                stringValues[key] = String(describing: value)
            }
        }
        
        return OperationDetails(values: stringValues)
    }
    
    // 确认操作
    func confirmOperation() {
        guard let confirmation = pendingConfirmation, !confirmation.isExpired else {
            cancelPendingConfirmation()
            return
        }
        
        // 执行确认操作的逻辑
        let details = convertToStringAnyDict(confirmation.operationDetails)
        messageProcessor.executeOperation(details)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("操作执行失败: \(error)")
                    let errorMessage = ChatMessage.aiMessage("抱歉，我在执行操作时遇到了问题。请稍后再试。")
                    self?.addMessage(errorMessage)
                }
                
                self?.cancelPendingConfirmation()
            } receiveValue: { [weak self] result in
                guard let self = self else { return }
                
                // 添加操作结果消息
                let resultMessage = ChatMessage.aiMessage(result)
                self.addMessage(resultMessage)
                
                // 清除确认状态
                self.cancelPendingConfirmation()
            }
            .store(in: &cancellables)
    }
    
    // 将OperationDetails转换回[String: Any]
    private func convertToStringAnyDict(_ details: OperationDetails) -> [String: Any] {
        var result = [String: Any]()
        
        for (key, stringValue) in details.values {
            // 先尝试转换为常见类型
            if let boolValue = Bool(stringValue) {
                result[key] = boolValue
            } else if let intValue = Int(stringValue) {
                result[key] = intValue
            } else if let doubleValue = Double(stringValue) {
                result[key] = doubleValue
            } else if stringValue.starts(with: "20"), stringValue.count > 10 {
                // 可能是ISO日期字符串
                let formatter = ISO8601DateFormatter()
                if let date = formatter.date(from: stringValue) {
                    result[key] = date
                } else {
                    result[key] = stringValue
                }
            } else {
                result[key] = stringValue
            }
        }
        
        return result
    }
    
    // 取消确认
    func cancelConfirmation() {
        let cancelMessage = ChatMessage.aiMessage("操作已取消。")
        addMessage(cancelMessage)
        cancelPendingConfirmation()
    }
    
    // 清除确认状态
    private func cancelPendingConfirmation() {
        pendingConfirmation = nil
        showConfirmationTimer = false
        confirmationTimer?.invalidate()
        confirmationTimer = nil
    }
    
    // 清除所有消息（保留欢迎消息）
    func clearMessages() {
        // 只保留欢迎消息
        let welcomeMessage = messages.first { !$0.isFromUser }
        messages.removeAll()
        
        if let welcome = welcomeMessage {
            messages.append(welcome)
        } else {
            let newWelcome = ChatMessage.aiMessage(
                "您好，我是您的AI助手。我可以帮助您管理任务、创建计划，或者回答您的问题。有什么我能帮您的吗？"
            )
            messages.append(newWelcome)
        }
    }
}

// 消息处理器协议
protocol ChatMessageProcessor {
    func processMessage(_ text: String) -> AnyPublisher<ChatResponse, Error>
    func executeOperation(_ details: [String: Any]) -> AnyPublisher<String, Error>
}

// 默认消息处理器实现
class DefaultChatMessageProcessor: ChatMessageProcessor {
    func processMessage(_ text: String) -> AnyPublisher<ChatResponse, Error> {
        // 简单的演示实现，实际应用中应该调用AI服务
        return Future<ChatResponse, Error> { promise in
            // 模拟网络延迟
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // 这里应该是实际的AI处理逻辑
                // 简单示例：对于包含"任务"的消息，返回一个需要确认的回复
                if text.contains("任务") || text.contains("todo") || text.contains("待办") {
                    let message = ChatMessage.aiMessage(
                        "您想创建一个新任务吗？我可以帮您安排。",
                        requiresConfirmation: true,
                        operationType: .createTask
                    )
                    
                    let details: [String: Any] = [
                        "operationType": OperationType.createTask.rawValue,
                        "taskTitle": "从AI创建的任务",
                        "dueDate": Date().addingTimeInterval(86400) // 明天
                    ]
                    
                    let response = ChatResponse(message: message, requiresConfirmation: true, operationDetails: details)
                    promise(.success(response))
                } else {
                    // 普通回复
                    let message = ChatMessage.aiMessage("我已收到您的消息: \"\(text)\"。有其他问题请随时告诉我。")
                    let response = ChatResponse(message: message, requiresConfirmation: false)
                    promise(.success(response))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func executeOperation(_ details: [String: Any]) -> AnyPublisher<String, Error> {
        return Future<String, Error> { promise in
            // 模拟操作执行
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // 根据操作类型执行不同逻辑
                if let operationTypeString = details["operationType"] as? String,
                   let operationType = OperationType(rawValue: operationTypeString) {
                    
                    switch operationType {
                    case .createTask:
                        if let title = details["taskTitle"] as? String {
                            // 这里应该调用实际的任务创建逻辑
                            promise(.success("任务「\(title)」已成功创建!"))
                        } else {
                            promise(.failure(NSError(domain: "ChatError", code: 400, userInfo: [NSLocalizedDescriptionKey: "缺少任务标题"])))
                        }
                    case .completeTask:
                        promise(.success("任务已标记为完成!"))
                    case .updateTask:
                        promise(.success("任务信息已更新!"))
                    case .deleteTask:
                        promise(.success("任务已删除!"))
                    case .createCategory:
                        promise(.success("新分类已创建!"))
                    case .generatePlan:
                        promise(.success("已为您生成详细的行动计划!"))
                    case .analytics:
                        promise(.success("数据分析已完成!"))
                    }
                } else {
                    promise(.failure(NSError(domain: "ChatError", code: 400, userInfo: [NSLocalizedDescriptionKey: "无效的操作类型"])))
                }
            }
        }.eraseToAnyPublisher()
    }
}