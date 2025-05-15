import Foundation

/// 通义千问 API 响应结构
public struct QwenResponse: Codable {
    /// 输出内容
    public let output: Output
    /// 使用情况
    public let usage: Usage
    /// 请求ID
    public let requestId: String
    
    /// 输出内容结构
    public struct Output: Codable {
        /// 响应文本
        public let text: String
        /// 完成原因
        public let finishReason: String?
        
        private enum CodingKeys: String, CodingKey {
            case text
            case finishReason = "finish_reason"
        }
    }
    
    /// 使用情况结构
    public struct Usage: Codable {
        /// 输入token数量
        public let inputTokens: Int
        /// 输出token数量
        public let outputTokens: Int
        /// 总token数量
        public let totalTokens: Int
        
        private enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
            case totalTokens = "total_tokens"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case output
        case usage
        case requestId = "request_id"
    }
}

/// API 错误
public enum QwenError: Error {
    case invalidResponse
    case networkError
    case apiError(String)
    case decodingError
    
    public var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "无效的API响应"
        case .networkError:
            return "网络连接错误"
        case .apiError(let message):
            return "API错误: \(message)"
        case .decodingError:
            return "响应解析错误"
        }
    }
} 