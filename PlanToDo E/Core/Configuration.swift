import Foundation

/// 应用程序配置管理类
class Configuration {
    /// 共享实例
    static let shared = Configuration()
    
    /// Qwen API 密钥
    var qwenAPIKey: String {
        // 从ConfigurationManager获取配置
        return ConfigurationManager.shared.qwenAPIKey ?? ""
    }
    
    /// 私有初始化方法
    private init() {}
} 