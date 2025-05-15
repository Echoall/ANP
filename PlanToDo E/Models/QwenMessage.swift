import Foundation

/// 通义千问消息结构体
public struct QwenMessage: Codable {
    /// 消息角色（user/assistant/system）
    public let role: String
    /// 消息内容
    public let content: String
    
    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
} 