import Foundation
import Combine

class StorageService {
    static let shared = StorageService()
    
    private init() {}
    
    // 清除所有本地数据
    func clearAllLocalData() {
        // 清除本地数据存储
        LocalStorageService.shared.clearAllData()
        
        // 发送通知
        NotificationCenter.default.post(name: NSNotification.Name("DataCleared"), object: nil)
        
        // 更新存储状态
        StorageStatusService.shared.updateLastLocalSaveTime()
    }
} 