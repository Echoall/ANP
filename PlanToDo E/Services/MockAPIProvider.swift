import Foundation
import Combine

/// 模拟响应生成器
class MockResponseGenerator {
    /// 生成模拟响应
    /// - Parameter input: 用户输入
    /// - Returns: 模拟的AI响应
    func generateResponse(for input: String) -> String {
        if input.contains("任务") {
            return "好的，我来帮您创建一个新任务。请问您想创建什么任务？"
        } else if input.contains("计划") {
            return "我可以帮您制定计划。您想规划什么内容？"
        } else if input.contains("分析") {
            return "我来为您分析一下数据。您想了解哪些方面？"
        } else {
            return "我已收到您的消息：\"\(input)\"。请问还有什么我可以帮您的吗？"
        }
    }
}

/// 模拟API提供者
class MockAPIProvider {
    // MARK: - 属性
    
    /// 响应生成器
    private let responseGenerator: MockResponseGenerator
    
    /// 延迟范围（秒）
    private let delayRange: ClosedRange<Double>
    
    // MARK: - 初始化
    
    /// 初始化模拟API提供者
    /// - Parameters:
    ///   - responseGenerator: 响应生成器
    ///   - delayRange: 延迟范围（秒）
    init(
        responseGenerator: MockResponseGenerator = MockResponseGenerator(),
        delayRange: ClosedRange<Double> = 0.5...1.5
    ) {
        self.responseGenerator = responseGenerator
        self.delayRange = delayRange
    }
    
    // MARK: - 公共方法
    
    /// 模拟聊天响应
    /// - Parameter messages: 消息数组
    /// - Returns: 包含响应的Publisher
    func mockChatResponse(messages: [QwenMessage]) -> AnyPublisher<QwenResponse, Error> {
        // 获取最后一条用户消息
        guard let lastMessage = messages.last,
              lastMessage.role == "user" else {
            return Fail(error: NSError(domain: "MockAPIError", code: 400, userInfo: [NSLocalizedDescriptionKey: "无效的消息格式"])).eraseToAnyPublisher()
        }
        
        // 生成模拟响应
        let responseContent = responseGenerator.generateResponse(for: lastMessage.content)
        
        // 创建模拟响应对象
        let mockResponse = QwenResponse(
            output: QwenOutput(
                text: responseContent,
                finish_reason: "stop"
            ),
            usage: QwenUsage(
                input_tokens: lastMessage.content.count / 4,
                output_tokens: responseContent.count / 4,
                total_tokens: (lastMessage.content.count + responseContent.count) / 4
            ),
            request_id: "mock-response-\(UUID().uuidString)"
        )
        
        // 随机延迟
        let delay = Double.random(in: delayRange)
        
        return Future<QwenResponse, Error> { promise in
            // 模拟网络延迟
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                promise(.success(mockResponse))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 模拟错误响应
    /// - Parameter errorType: 错误类型
    /// - Returns: 包含错误的发布者
    func mockErrorResponse(errorType: QwenError) -> AnyPublisher<QwenResponse, Error> {
        let delay = Double.random(in: delayRange)
        
        return Future<QwenResponse, Error> { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                promise(.failure(errorType))
            }
        }
        .eraseToAnyPublisher()
    }
} 