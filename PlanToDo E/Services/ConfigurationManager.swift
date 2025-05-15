import Foundation

/// 配置管理器 - 管理应用程序配置和API密钥
class ConfigurationManager {
    /// 共享实例
    static let shared = ConfigurationManager()
    
    /// Qwen API 密钥
    var qwenAPIKey: String? {
        get {
            return UserDefaults.standard.string(forKey: "QwenAPIKey") ?? getAPIKeyFromPlist("QwenAPIKey")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "QwenAPIKey")
        }
    }
    
    /// 用户设置
    private let userDefaults = UserDefaults.standard
    
    /// 私有初始化方法
    private init() {
        // 从环境变量或配置文件加载初始配置
        loadInitialConfiguration()
    }
    
    /// 加载初始配置
    private func loadInitialConfiguration() {
        // 如果还没有设置API密钥，尝试从配置文件或环境变量获取
        if qwenAPIKey == nil || qwenAPIKey?.isEmpty == true {
            // 使用用户提供的API密钥
            qwenAPIKey = "sk-06e811e5b9124d24b9c88efc6fd23584"
        }
    }
    
    /// 从Plist配置文件中获取API密钥
    /// - Parameter key: 密钥名称
    /// - Returns: API密钥，如果未找到则返回nil
    private func getAPIKeyFromPlist(_ key: String) -> String? {
        // 尝试从Configuration.plist文件中读取
        if let path = Bundle.main.path(forResource: "Configuration", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let apiKey = dict[key] as? String {
            return apiKey
        }
        return nil
    }
    
    /// 保存所有配置到用户设置
    func saveConfiguration() {
        // 目前只是保存到UserDefaults，未来可能添加其他持久化方式
        userDefaults.synchronize()
    }
    
    /// 重置配置到默认状态
    func resetToDefaults() {
        // 清除用户设置中的API密钥
        userDefaults.removeObject(forKey: "QwenAPIKey")
        
        // 重新加载默认配置
        loadInitialConfiguration()
    }
} 