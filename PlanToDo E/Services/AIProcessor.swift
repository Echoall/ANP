import Foundation
import Combine
import SwiftUI

/// AI响应模型
struct AIResponse {
    let text: String
    let requiresConfirmation: Bool
    let operationType: OperationType?
    let operationDetails: [String: Any]?
}

/// AI处理器错误
enum AIProcessorError: Error, LocalizedError {
    case apiUnavailable
    case apiError(Error)
    case responseParsingError
    case instanceReleased
    
    var errorDescription: String? {
        switch self {
        case .apiUnavailable:
            return "AI服务暂时不可用，请稍后再试"
        case .apiError(let error):
            return "AI服务错误: \(error.localizedDescription)"
        case .responseParsingError:
            return "无法解析AI服务的响应"
        case .instanceReleased:
            return "处理器实例已释放"
        }
    }
}

/// AI处理器，负责处理用户消息并生成响应
class AIProcessor: ObservableObject {
    /// 聊天消息
    @Published var messages: [ChatMessage] = []
    /// 等待AI响应中
    @Published var isWaitingForResponse = false
    /// API是否可用
    @Published var apiAvailable = true
    
    /// AI客户端
    private var qwenClient: QwenClient
    /// 取消订阅令牌
    private var cancellables = Set<AnyCancellable>()
    /// 最大重试次数
    private let maxRetries = 3
    /// 重试延迟时间（秒）
    private let retryDelay = 2.0
    
    /// 初始化
    /// - Parameter client: 可选的自定义QwenClient
    init(client: QwenClient? = nil) {
        // 使用提供的客户端或创建一个新的
        self.qwenClient = client ?? QwenClient.shared
        
        // 检查API是否可用
        checkAPIAvailability()
    }
    
    /// 检查API可用性
    func checkAPIAvailability() {
        qwenClient.checkAvailability()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("API可用性检查失败: \(error.localizedDescription)")
                    self.apiAvailable = false
                }
            } receiveValue: { isAvailable in
                self.apiAvailable = isAvailable
                print("API可用性: \(isAvailable ? "可用" : "不可用")")
            }
            .store(in: &cancellables)
    }
    
    /// 发送消息并获取AI响应
    /// - Parameter content: 消息内容
    /// - Returns: 包含响应的发布者
    func sendMessage(_ content: String) -> AnyPublisher<String, Error> {
        // 创建用户消息
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            content: content,
            role: .user,
            timestamp: Date()
        )
        
        // 更新消息列表
        DispatchQueue.main.async {
            self.messages.append(userMessage)
            self.isWaitingForResponse = true
        }
        
        // 准备发送到API的消息
        let qwenMessages = self.messages.map { message in
            QwenMessage(
                role: message.role == .user ? "user" : "assistant",
                content: message.content
            )
        }
        
        // 调用API
        return callAPIWithRetry(messages: qwenMessages, retryCount: 0)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { responseContent in
                // 创建AI响应消息
                let aiMessage = ChatMessage(
                    id: UUID().uuidString,
                    content: responseContent,
                    role: .assistant,
                    timestamp: Date()
                )
                
                // 更新消息列表和状态
                self.messages.append(aiMessage)
                self.isWaitingForResponse = false
            }, receiveCompletion: { completion in
                if case .failure = completion {
                    self.isWaitingForResponse = false
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// 带重试的API调用
    private func callAPIWithRetry(messages: [QwenMessage], retryCount: Int) -> AnyPublisher<String, Error> {
        // 如果是第一次尝试，尝试使用具有后备机制的方法
        if retryCount == 0 && messages.count > 0 {
            let userMessage = messages.last?.content ?? ""
            return self.qwenClient.sendMessage(userMessage)
                .tryMap { response -> String in
                    return response.output.text
                }
                .eraseToAnyPublisher()
        }
        
        // 常规的API调用方法（用于重试）
        return self.qwenClient.chat(messages: messages)
            .tryMap { response -> String in
                return response.output.text
            }
            .catch { [weak self] error -> AnyPublisher<String, Error> in
                guard let self = self else {
                    return Fail(error: AIProcessorError.instanceReleased).eraseToAnyPublisher()
                }
                
                // 记录错误
                print("Qwen API 错误 (尝试 \(retryCount + 1)/\(self.maxRetries)): \(error.localizedDescription)")
                
                // 检查是否应该重试
                if retryCount < self.maxRetries {
                    // 对某些错误类型进行重试
                    if let qwenError = error as? QwenError {
                        switch qwenError {
                        case .rateLimitError, .serverError, .networkError:
                            // 这些错误可以重试
                            return Just(())
                                .delay(for: .seconds(self.retryDelay * Double(retryCount + 1)), scheduler: DispatchQueue.global())
                                .flatMap { _ in
                                    self.callAPIWithRetry(messages: messages, retryCount: retryCount + 1)
                                }
                                .eraseToAnyPublisher()
                        default:
                            // 其他错误不重试
                            break
                        }
                    }
                }
                
                // 如果是网络错误，标记API不可用
                if let qwenError = error as? QwenError {
                    if case .networkError = qwenError {
                        self.apiAvailable = false
                        // 安排一个延迟的API可用性检查
                        DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
                            self.checkAPIAvailability()
                        }
                    }
                }
                
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    /// 获取聊天历史
    /// - Returns: 聊天消息数组
    func getChatHistory() -> [ChatMessage] {
        return messages
    }
    
    /// 分析任务描述并生成计划
    /// - Parameter taskDescription: 任务描述
    /// - Returns: 包含分析结果的发布者
    func analyzeTaskDescription(_ taskDescription: String) -> AnyPublisher<String, Error> {
        let prompt = """
        我需要帮助分析以下任务并制定一个详细的执行计划：

        任务描述：
        \(taskDescription)

        请提供：
        1. 任务分解：将任务拆分为小的可管理步骤
        2. 时间估计：每个步骤大约需要多少时间
        3. 优先级安排：哪些步骤需要首先完成
        4. 潜在挑战：可能遇到的障碍和解决方案
        5. 所需资源：完成任务所需的工具、信息或支持

        请给出结构化的回答，使计划易于遵循。
        """
        
        let message = QwenMessage(role: "user", content: prompt)
        
        // 直接调用API，不加入到聊天历史
        return qwenClient.chat(messages: [message])
            .tryMap { response -> String in
                return response.output.text
            }
            .eraseToAnyPublisher()
    }
    
    /// 优化日程安排
    /// - Parameters:
    ///   - tasks: 任务列表
    ///   - availableTime: 可用时间（小时）
    /// - Returns: 包含优化建议的发布者
    func optimizeSchedule(tasks: [String], availableTime: Double) -> AnyPublisher<String, Error> {
        let taskList = tasks.enumerated().map { index, task in
            return "\(index + 1). \(task)"
        }.joined(separator: "\n")
        
        let prompt = """
        我有以下任务需要完成，但只有\(availableTime)小时的可用时间。请帮我优化日程安排：

        任务列表：
        \(taskList)

        请考虑：
        1. 任务优先级（基于紧急性和重要性）
        2. 每个任务合理的时间分配
        3. 如果无法完成所有任务，哪些可以推迟
        4. 如何最有效地安排这些任务
        5. 休息和缓冲时间的安排

        请给出详细的时间表和优化建议。
        """
        
        let message = QwenMessage(role: "user", content: prompt)
        
        return qwenClient.chat(messages: [message])
            .tryMap { response -> String in
                return response.output.text
            }
            .eraseToAnyPublisher()
    }
    
    /// 清除聊天历史
    func clearChatHistory() {
        messages.removeAll()
    }
    
    /// 处理消息并返回AI响应
    func process(_ message: String) -> AnyPublisher<AIResponse, Error> {
        return Future<AIResponse, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(AIProcessorError.instanceReleased))
                return
            }
            
            // 如果API不可用，先检查可用性
            if !self.apiAvailable {
                self.checkAPIAvailability()
                promise(.failure(AIProcessorError.apiUnavailable))
                return
            }
            
            // 准备系统提示
            let systemPrompt = """
            你是PlantoDo应用的AI助手，专注于帮助用户管理任务和目标。回复请使用中文。
            
            你可以帮助用户创建、修改、删除和完成任务，也可以创建、修改和删除分类。
            
            当用户请求执行这些操作时，你应该生成需要确认的响应。响应格式如下：
            
            1. 如果是创建任务: "您确认要创建任务【任务名称】吗？"
            2. 如果是删除任务: "您确认要删除任务【任务名称】吗？"
            3. 如果是完成任务: "您确认要将任务【任务名称】标记为完成吗？"
            4. 如果是修改任务: "您确认要修改任务【任务名称】吗？"
            5. 如果是创建分类: "您确认要创建分类【分类名称】吗？"
            6. 如果是删除分类: "您确认要删除分类【分类名称】吗？警告：删除分类会导致该分类下的所有任务变为未分类状态。"
            7. 如果是修改分类: "您确认要修改分类【分类名称】吗？"
            
            分析用户的输入，提取出操作类型和相关的任务或分类名称，然后返回适当的响应。
            如果用户的请求不涉及上述操作，请提供有用的建议或回答他们的问题。
            """
            
            // 准备消息
            let messages = [
                QwenMessage(role: "system", content: systemPrompt),
                QwenMessage(role: "user", content: message)
            ]
            
            // 带重试的调用 Qwen API
            self.callAPIWithRetry(messages: messages, retryCount: 0)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(AIProcessorError.apiError(error)))
                        }
                    },
                    receiveValue: { response in
                        // 分析响应，检测是否需要确认以及操作类型
                        let (requiresConfirmation, operationType, operationDetails) = self.analyzeResponse(response, originalMessage: message)
                        
                        let aiResponse = AIResponse(
                            text: response,
                            requiresConfirmation: requiresConfirmation,
                            operationType: operationType,
                            operationDetails: operationDetails
                        )
                        
                        promise(.success(aiResponse))
                    }
                )
                .store(in: &self.cancellables)
        }
        .eraseToAnyPublisher()
    }
    
    /// 分析AI的响应，检测是否需要确认以及操作类型
    private func analyzeResponse(_ response: String, originalMessage: String) -> (Bool, OperationType?, [String: Any]?) {
        // 检查是否包含确认请求的关键词
        let confirmPhrases = [
            "您确认要创建任务",
            "您确认要删除任务",
            "您确认要将任务",
            "您确认要修改任务",
            "您确认要创建分类",
            "您确认要删除分类",
            "您确认要修改分类"
        ]
        
        // 判断是否需要确认
        let requiresConfirmation = confirmPhrases.contains { response.contains($0) }
        
        var operationType: OperationType? = nil
        var operationDetails: [String: Any]? = nil
        
        if requiresConfirmation {
            // 提取操作类型
            if response.contains("创建任务") {
                operationType = .createTask
                operationDetails = [
                    "operationType": OperationType.createTask.rawValue,
                    "title": self.extractName(from: response, prefix: "【", suffix: "】") ?? "新任务",
                    "description": "从AI助手创建的任务"
                ]
            } else if response.contains("删除任务") {
                operationType = .deleteTask
                let taskName = self.extractName(from: response, prefix: "【", suffix: "】") ?? "指定任务"
                operationDetails = [
                    "operationType": OperationType.deleteTask.rawValue,
                    "taskId": UUID().uuidString, // 实际应用中应从任务存储中查找真实ID
                    "taskName": taskName
                ]
            } else if response.contains("将任务") && response.contains("标记为完成") {
                operationType = .completeTask
                let taskName = self.extractName(from: response, prefix: "【", suffix: "】") ?? "指定任务"
                operationDetails = [
                    "operationType": OperationType.completeTask.rawValue,
                    "taskId": UUID().uuidString, // 实际应用中应从任务存储中查找真实ID
                    "taskName": taskName
                ]
            } else if response.contains("修改任务") {
                operationType = .updateTask
                let taskName = self.extractName(from: response, prefix: "【", suffix: "】") ?? "指定任务"
                operationDetails = [
                    "operationType": OperationType.updateTask.rawValue,
                    "taskId": UUID().uuidString, // 实际应用中应从任务存储中查找真实ID
                    "taskName": taskName,
                    "updatedFields": "标题,描述,截止日期" // 在实际应用中，应该根据用户的请求确定要更新的字段
                ]
            } else if response.contains("创建分类") {
                operationType = .createCategory
                let categoryName = self.extractName(from: response, prefix: "【", suffix: "】") ?? "新分类"
                operationDetails = [
                    "operationType": OperationType.createCategory.rawValue,
                    "name": categoryName,
                    "color": "#4287f5" // 默认颜色
                ]
            } else if response.contains("删除分类") {
                operationType = .deleteCategory
                let categoryName = self.extractName(from: response, prefix: "【", suffix: "】") ?? "指定分类"
                operationDetails = [
                    "operationType": OperationType.deleteCategory.rawValue,
                    "categoryId": UUID().uuidString, // 实际应用中应从分类存储中查找真实ID
                    "categoryName": categoryName
                ]
            } else if response.contains("修改分类") {
                operationType = .updateCategory
                let categoryName = self.extractName(from: response, prefix: "【", suffix: "】") ?? "指定分类"
                operationDetails = [
                    "operationType": OperationType.updateCategory.rawValue,
                    "categoryId": UUID().uuidString, // 实际应用中应从分类存储中查找真实ID
                    "categoryName": categoryName,
                    "updatedFields": "名称,颜色" // 在实际应用中，应该根据用户的请求确定要更新的字段
                ]
            }
        }
        
        return (requiresConfirmation, operationType, operationDetails)
    }
    
    /// 从文本中提取名称（通常在【】或""中）
    private func extractName(from text: String, prefix: String, suffix: String) -> String? {
        guard let prefixRange = text.range(of: prefix),
              let suffixRange = text.range(of: suffix, range: prefixRange.upperBound..<text.endIndex) else {
            return nil
        }
        
        return String(text[prefixRange.upperBound..<suffixRange.lowerBound])
    }
    
    /// 执行操作
    func executeOperation(_ details: [String: Any]) -> AnyPublisher<String, Error> {
        return Future<String, Error> { promise in
            // 模拟执行操作的延迟
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                // 通过details中的信息确定操作类型
                if let operationTypeString = details["operationType"] as? String,
                   let operationType = OperationType(rawValue: operationTypeString) {
                    
                    switch operationType {
                    case .createTask:
                        if let taskName = details["title"] as? String {
                            promise(.success("任务【\(taskName)】创建成功。"))
                        } else {
                            promise(.success("新任务创建成功。"))
                        }
                        
                    case .deleteTask:
                        if let taskName = details["taskName"] as? String {
                            promise(.success("任务【\(taskName)】删除成功。"))
                        } else {
                            promise(.success("任务删除成功。"))
                        }
                        
                    case .completeTask:
                        if let taskName = details["taskName"] as? String {
                            promise(.success("任务【\(taskName)】已标记为完成。"))
                        } else {
                            promise(.success("任务已标记为完成。"))
                        }
                        
                    case .updateTask:
                        if let taskName = details["taskName"] as? String {
                            promise(.success("任务【\(taskName)】修改成功。"))
                        } else {
                            promise(.success("任务修改成功。"))
                        }
                        
                    case .createCategory:
                        if let categoryName = details["name"] as? String {
                            promise(.success("分类【\(categoryName)】创建成功。"))
                        } else {
                            promise(.success("新分类创建成功。"))
                        }
                        
                    case .deleteCategory:
                        if let categoryName = details["categoryName"] as? String {
                            promise(.success("分类【\(categoryName)】删除成功。"))
                        } else {
                            promise(.success("分类删除成功。"))
                        }
                        
                    case .updateCategory:
                        if let categoryName = details["categoryName"] as? String {
                            promise(.success("分类【\(categoryName)】修改成功。"))
                        } else {
                            promise(.success("分类修改成功。"))
                        }
                        
                    case .generatePlan, .analytics:
                        // 对于这些操作，直接返回成功
                        promise(.success("操作执行成功。"))
                    }
                } else {
                    // 如果没有操作类型，返回一个通用的成功消息
                    promise(.success("操作执行成功。"))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 处理取消操作的反馈
    func handleCancellation(_ details: [String: Any]) -> String {
        // 通过details中的信息确定被取消的操作类型
        if let operationTypeString = details["operationType"] as? String,
           let operationType = OperationType(rawValue: operationTypeString) {
            
            switch operationType {
            case .createTask:
                return "已取消创建任务操作。"
                
            case .deleteTask:
                if let taskName = details["taskName"] as? String {
                    return "已取消删除任务【\(taskName)】的操作。"
                } else {
                    return "已取消删除任务操作。"
                }
                
            case .completeTask:
                if let taskName = details["taskName"] as? String {
                    return "已取消将任务【\(taskName)】标记为完成的操作。"
                } else {
                    return "已取消标记任务完成的操作。"
                }
                
            case .updateTask:
                if let taskName = details["taskName"] as? String {
                    return "已取消修改任务【\(taskName)】的操作。"
                } else {
                    return "已取消修改任务操作。"
                }
                
            case .createCategory:
                if let categoryName = details["name"] as? String {
                    return "已取消创建分类【\(categoryName)】的操作。"
                } else {
                    return "已取消创建分类操作。"
                }
                
            case .deleteCategory:
                if let categoryName = details["categoryName"] as? String {
                    return "已取消删除分类【\(categoryName)】的操作。"
                } else {
                    return "已取消删除分类操作。"
                }
                
            case .updateCategory:
                if let categoryName = details["categoryName"] as? String {
                    return "已取消修改分类【\(categoryName)】的操作。"
                } else {
                    return "已取消修改分类操作。"
                }
                
            case .generatePlan, .analytics:
                return "已取消操作。"
            }
        } else {
            // 如果没有操作类型，返回一个通用的取消消息
            return "操作已取消。"
        }
    }
} 
 