import Foundation
import Combine

/// Qwen API错误类型
enum QwenError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case rateLimitError
    case authenticationError
    case serverError
    case clientError
    case responseParsingError
    case invalidAPIKey
    case modelUnavailable
    case contextLengthExceeded
    case contentFilterError
    case generalError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的API URL"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .rateLimitError:
            return "API调用频率超限，请稍后重试"
        case .authenticationError:
            return "API认证失败，请检查API密钥"
        case .serverError:
            return "Qwen服务器错误，请稍后重试"
        case .clientError:
            return "客户端请求错误"
        case .responseParsingError:
            return "响应解析错误"
        case .invalidAPIKey:
            return "无效的API密钥"
        case .modelUnavailable:
            return "请求的模型不可用"
        case .contextLengthExceeded:
            return "输入内容超过模型最大上下文长度"
        case .contentFilterError:
            return "内容被安全过滤器拦截"
        case .generalError(let message):
            return message
        }
    }
}

/// Qwen API消息
struct QwenMessage: Codable {
    let role: String
    let content: String
}

/// Qwen API请求体
struct QwenRequest: Codable {
    let model: String
    let messages: [QwenMessage]
    let temperature: Double?
    let top_p: Double?
    let max_tokens: Int?
    let stream: Bool?
    
    init(
        model: String,
        messages: [QwenMessage],
        temperature: Double? = 0.7,
        top_p: Double? = 0.95,
        max_tokens: Int? = 2048,
        stream: Bool? = false
    ) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.top_p = top_p
        self.max_tokens = max_tokens
        self.stream = stream
    }
    
    // 确保编码后的JSON格式符合API要求
    func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys] // 这有助于保持稳定的键顺序
        return try encoder.encode(self)
    }
}

/// Qwen API消息对象
struct QwenResponseMessage: Codable {
    let role: String
    let content: String
}

/// Qwen API选择对象
struct QwenChoice: Codable {
    let index: Int
    let message: QwenResponseMessage
    let finish_reason: String?
}

/// Qwen API使用量对象
struct QwenUsage: Codable {
    let input_tokens: Int
    let output_tokens: Int
    let total_tokens: Int
    
    // 兼容旧版API
    var prompt_tokens: Int { input_tokens }
    var completion_tokens: Int { output_tokens }
}

/// Qwen API响应体
struct QwenResponse: Codable {
    let output: QwenOutput
    let usage: QwenUsage
    let request_id: String
    
    // 兼容旧版API
    var id: String { request_id }
    var object: String { "chat.completion" }
    var created: Int { Int(Date().timeIntervalSince1970) }
    var choices: [QwenChoice] {
        [QwenChoice(
            index: 0,
            message: QwenResponseMessage(role: "assistant", content: output.text),
            finish_reason: output.finish_reason
        )]
    }
}

/// Qwen API输出
struct QwenOutput: Codable {
    let text: String
    let finish_reason: String?
}

/// Qwen API错误响应
struct QwenErrorResponse: Codable {
    let error: QwenErrorDetail
}

/// Qwen API错误详情
struct QwenErrorDetail: Codable {
    let message: String?
    let type: String?
    let param: String?
    let code: String?
}

/// AI消息结构体
struct AIMessage {
    let role: String
    let content: String
}

/// Qwen客户端协议
protocol QwenClientProtocol {
    /// 发送聊天消息
    /// - Parameter messages: 消息数组
    /// - Returns: 包含流式响应字符串的Publisher
    func sendMessageStream(messages: [AIMessage]) -> AnyPublisher<String, Error>
    
    /// 发送聊天消息（非流式）
    /// - Parameter messages: 消息数组
    /// - Returns: 包含响应的Publisher
    func sendChatMessage(_ messages: [QwenMessage]) -> AnyPublisher<QwenResponse, Error>
    
    /// 测试API连接
    /// - Returns: 包含成功结果的Publisher
    func testConnection() -> AnyPublisher<Bool, Error>
    
    /// 更新API密钥
    /// - Parameter newKey: 新的API密钥
    func updateApiKey(_ newKey: String)
}

/// Qwen通义千问客户端
class QwenClient: QwenClientProtocol {
    /// 共享实例
    static let shared = QwenClient()
    
    /// 基础URL
    #if targetEnvironment(simulator)
    private let baseURL = URL(string: "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation")!
    #else
    private let baseURL = URL(string: "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation")!
    #endif
    /// 模型名称
    private let model: String
    /// API密钥
    private var apiKey: String
    /// URL会话
    private let session: URLSession
    /// 网络监视器
    private let networkMonitor = NetworkMonitor.shared
    
    /// 初始化Qwen客户端
    /// - Parameters:
    ///   - apiKey: API密钥（可选，默认从环境变量或配置获取）
    ///   - model: 模型名称（默认为qwen-turbo）
    ///   - session: URL会话（默认为shared）
    init(apiKey: String? = nil, model: String = "qwen-turbo", session: URLSession = .shared) {
        self.model = model
        self.session = session
        self.apiKey = apiKey ?? ConfigurationManager.shared.qwenAPIKey ?? ""
        
        // 检查API密钥是否为空
        if self.apiKey.isEmpty {
            print("警告：API密钥为空。请在配置中设置有效的API密钥。")
        }
    }
    
    /// 更新API密钥
    /// - Parameter newKey: 新的API密钥
    func updateApiKey(_ newKey: String) {
        self.apiKey = newKey
        print("已更新API密钥")
    }
    
    /// 创建API请求
    /// - Parameters:
    ///   - endpoint: API端点（可选）
    ///   - method: HTTP方法
    ///   - body: 请求体
    /// - Returns: URLRequest
    private func createRequest<T: Encodable>(
        endpoint: String? = nil,
        method: String,
        body: T? = nil
    ) -> URLRequest? {
        // 构建完整URL
        var url = baseURL
        if let endpoint = endpoint, !endpoint.isEmpty {
            guard let endpointURL = URL(string: endpoint, relativeTo: baseURL) else {
                print("错误: 无效的API端点")
                return nil
            }
            url = endpointURL
        }
        
        #if targetEnvironment(simulator)
        print("模拟器环境URL请求: \(url.absoluteString)")
        #endif
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // 添加超时设置，增加请求超时时间
        request.timeoutInterval = 30
        
        // 添加请求体
        if let body = body {
            // 特殊处理QwenRequest类型，使用专用编码方法
            if let qwenRequest = body as? QwenRequest {
                do {
                    request.httpBody = try qwenRequest.encode()
                    #if targetEnvironment(simulator)
                    if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
                        print("模拟器环境请求体: \(bodyString)")
                    }
                    #endif
                } catch {
                    print("错误: 无法编码QwenRequest - \(error.localizedDescription)")
                    return nil
                }
            } else {
                // 处理其他Encodable类型
                let encoder = JSONEncoder()
                do {
                    request.httpBody = try encoder.encode(body)
                } catch {
                    print("错误: 无法编码请求体 - \(error.localizedDescription)")
                    return nil
                }
            }
        }
        
        return request
    }
    
    /// 测试API连接
    /// - Returns: 包含成功结果的发布者
    func testConnection() -> AnyPublisher<Bool, Error> {
        // 创建简单的测试消息
        let messages = [QwenMessage(role: "user", content: "Hello")]
        let request = QwenRequest(model: model, messages: messages, max_tokens: 10)
        
        // 发送API请求
        return chat(messages: messages, maxTokens: 10)
            .map { _ in true }
            .eraseToAnyPublisher()
    }
    
    /// 检查API可用性
    /// - Returns: 包含可用性结果的发布者
    func checkAvailability() -> AnyPublisher<Bool, Error> {
        return testConnection()
            .catch { error -> AnyPublisher<Bool, Error> in
                print("API可用性检查失败: \(error.localizedDescription)")
                return Just(false).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    /// 通用的API调用方法
    /// - Parameter request: URL请求
    /// - Returns: 包含数据的发布者
    private func call(request: URLRequest) -> AnyPublisher<Data, Error> {
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                // 验证HTTP响应
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw QwenError.networkError(NSError(domain: "InvalidResponse", code: 0, userInfo: nil))
                }
                
                // 检查HTTP状态码
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    // 解析错误响应
                    if let errorResponse = try? JSONDecoder().decode(QwenErrorResponse.self, from: data) {
                        print("认证错误: \(errorResponse.error.message ?? "")")
                    }
                    throw QwenError.authenticationError
                case 429:
                    throw QwenError.rateLimitError
                case 500...599:
                    throw QwenError.serverError
                default:
                    // 尝试解析错误响应
                    if let errorResponse = try? JSONDecoder().decode(QwenErrorResponse.self, from: data) {
                        print("API错误: \(errorResponse.error.message ?? "")")
                        
                        // 根据错误类型返回特定错误
                        if let errorType = errorResponse.error.type {
                            if errorType.contains("invalid_api_key") {
                                throw QwenError.invalidAPIKey
                            } else if errorType.contains("context_length_exceeded") {
                                throw QwenError.contextLengthExceeded
                            } else if errorType.contains("content_filter") {
                                throw QwenError.contentFilterError
                            }
                        }
                        
                        throw QwenError.generalError(errorResponse.error.message ?? "")
                    }
                    
                    // 一般客户端错误
                    throw QwenError.clientError
                }
            }
            .mapError { error -> Error in
                // 转换网络错误
                if let urlError = error as? URLError {
                    print("网络错误: \(urlError.localizedDescription)")
                    return QwenError.networkError(urlError)
                }
                
                // 保留已转换的错误
                if let qwenError = error as? QwenError {
                    return qwenError
                }
                
                // 返回原始错误
                return error
            }
            .eraseToAnyPublisher()
    }
    
    /// 发送聊天请求
    /// - Parameters:
    ///   - messages: 消息数组
    ///   - temperature: 温度参数
    ///   - maxTokens: 最大令牌数
    /// - Returns: 包含API响应的发布者
    func chat(
        messages: [QwenMessage],
        temperature: Double = 0.7,
        maxTokens: Int = 2048
    ) -> AnyPublisher<QwenResponse, Error> {
        // 首先检查API密钥是否设置
        if self.apiKey.isEmpty {
            print("API密钥未设置，无法发送请求")
            return Fail(error: QwenError.invalidAPIKey).eraseToAnyPublisher()
        }
        
        #if targetEnvironment(simulator)
        // 模拟器环境特殊处理
        print("模拟器环境检测：跳过网络可用性检查")
        #else
        // 检查网络是否可用
        if !NetworkMonitor.shared.isConnected {
            print("网络连接不可用，无法发送请求")
            
            // 输出更详细的网络诊断信息
            let monitor = NetworkMonitor.shared
            let detailedStatus = monitor.detailedNetworkStatus
            let failureReason = monitor.lastConnectionFailureReason ?? "未知原因"
            print("详细网络状态: \(detailedStatus), 失败原因: \(failureReason)")
            
            return Fail(error: QwenError.networkError(NSError(
                domain: "NetworkUnavailable", 
                code: -1009, 
                userInfo: [
                    NSLocalizedDescriptionKey: "网络连接不可用，请检查您的网络设置: \(failureReason)"
                ]
            ))).eraseToAnyPublisher()
        }
        #endif
        
        // 创建请求对象
        let requestBody = QwenRequest(
            model: model,
            messages: messages,
            temperature: temperature,
            max_tokens: maxTokens
        )
        
        // 创建HTTP请求
        guard let request = createRequest(
            method: "POST",
            body: requestBody
        ) else {
            return Fail(error: QwenError.invalidURL).eraseToAnyPublisher()
        }
        
        // 打印请求详情用于调试
        print("发送请求到: \(request.url?.absoluteString ?? "未知URL")")
        print("请求头: \(request.allHTTPHeaderFields ?? [:])")
        if let httpBody = request.httpBody, let bodyString = String(data: httpBody, encoding: .utf8) {
            print("请求体: \(bodyString)")
            
            // 尝试解析请求体，验证JSON格式
            do {
                let _ = try JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: Any]
            } catch {
                print("警告: 请求体JSON格式可能有问题: \(error.localizedDescription)")
            }
        }
        
        // 发送请求并解析响应
        return call(request: request)
            .tryMap { data -> QwenResponse in
                // 尝试解析成标准响应
                let decoder = JSONDecoder()
                do {
                    let response = try decoder.decode(QwenResponse.self, from: data)
                    return response
                } catch {
                    print("解析响应失败: \(error.localizedDescription)")
                    
                    // 输出原始响应数据用于调试
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("原始响应: \(jsonString)")
                        
                        // 尝试解析为简单的JSON对象
                        if let jsonObj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            print("JSON结构: \(jsonObj.keys)")
                        }
                    }
                    
                    // 尝试解析错误响应
                    if let errorResponse = try? decoder.decode(QwenErrorResponse.self, from: data) {
                        if let errorMessage = errorResponse.error.message {
                            throw QwenError.generalError(errorMessage)
                        }
                    }
                    
                    throw QwenError.responseParsingError
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// 发送流式聊天请求，返回实时响应片段
    /// - Parameter messages: AI消息数组
    /// - Returns: 包含响应片段的Publisher
    func sendMessageStream(messages: [AIMessage]) -> AnyPublisher<String, Error> {
        // 将AIMessage转换为QwenMessage
        let qwenMessages = messages.map { QwenMessage(role: $0.role, content: $0.content) }
        
        // 使用现有的chat方法发送请求
        return chat(messages: qwenMessages)
            .map { response -> String in
                return response.output.text
            }
            .eraseToAnyPublisher()
    }
    
    /// 发送聊天消息（非流式）
    /// - Parameter messages: 消息数组
    /// - Returns: 包含响应的Publisher
    func sendChatMessage(_ messages: [QwenMessage]) -> AnyPublisher<QwenResponse, Error> {
        return chat(messages: messages)
    }
    
    /// 简化的消息发送方法
    /// - Parameter text: 文本消息
    /// - Returns: 包含API响应的发布者
    func sendMessage(_ text: String) -> AnyPublisher<QwenResponse, Error> {
        let message = QwenMessage(role: "user", content: text)
        return chat(messages: [message])
    }
} 