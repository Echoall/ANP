import Foundation

/// API密钥提供者协议
public protocol APIKeyProvider {
    /// 获取当前API密钥
    func getCurrentKey() -> String
    
    /// 获取所有可用的API密钥
    func getAllKeys() -> [String]
    
    /// 标记当前密钥已耗尽或失效，将尝试使用下一个可用密钥
    func markCurrentKeyExhausted()
    
    /// 重置密钥状态
    func reset()
}

/// 默认API密钥提供者实现
public class DefaultAPIKeyProvider: APIKeyProvider {
    private var primaryKey: String
    private var backupKeys: [String]
    private var currentKeyIndex: Int = 0
    
    /// 初始化密钥提供者
    /// - Parameters:
    ///   - primaryKey: 主要API密钥
    ///   - backupKeys: 备用API密钥数组
    public init(primaryKey: String, backupKeys: [String] = []) {
        self.primaryKey = primaryKey
        self.backupKeys = backupKeys
    }
    
    /// 获取当前API密钥
    public func getCurrentKey() -> String {
        if currentKeyIndex == 0 {
            return primaryKey
        } else if currentKeyIndex <= backupKeys.count {
            return backupKeys[currentKeyIndex - 1]
        } else {
            // 如果所有密钥都被标记为耗尽，重新使用主密钥
            currentKeyIndex = 0
            return primaryKey
        }
    }
    
    /// 获取所有可用的API密钥
    public func getAllKeys() -> [String] {
        return [primaryKey] + backupKeys
    }
    
    /// 标记当前密钥已耗尽或失效，将尝试使用下一个可用密钥
    public func markCurrentKeyExhausted() {
        currentKeyIndex += 1
        
        // 如果已用完所有备用密钥，重置为主密钥
        if currentKeyIndex > backupKeys.count {
            currentKeyIndex = 0
        }
    }
    
    /// 重置密钥状态
    public func reset() {
        currentKeyIndex = 0
    }
} 