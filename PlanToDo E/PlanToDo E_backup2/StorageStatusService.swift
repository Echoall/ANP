import Foundation
import Combine

// 存储状态观察器，用于显示存储状态和调试
class StorageStatusService: ObservableObject {
    static let shared = StorageStatusService()
    
    @Published var lastLocalSaveTime: Date?
    @Published var lastCloudSyncTime: Date?
    @Published var storageInfo: String = ""
    @Published var isCloud: Bool = false // 是否使用云存储
    @Published var isCloudAvailable: Bool = false // 云存储是否可用
    
    // 同步状态
    enum SyncStatus: String {
        case syncing = "正在同步"
        case synced = "已同步"
        case failed = "同步失败"
        case offline = "离线"
        case unknown = "未知"
    }
    
    @Published var syncStatus: SyncStatus = .unknown
    
    private var storageTimer: Timer?
    
    enum StorageStatus: String {
        case saving = "正在保存"
        case saved = "已保存"
        case failed = "保存失败"
        case unknown = "未知"
    }
    
    @Published var status: StorageStatus = .unknown
    
    private init() {
        // 每10秒更新一次存储空间信息
        storageTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.updateStorageInfo()
        }
        storageTimer?.fire()
        
        // 检查iCloud是否可用
        checkCloudAvailability()
    }
    
    deinit {
        storageTimer?.invalidate()
    }
    
    // 检查iCloud是否可用
    private func checkCloudAvailability() {
        // 简单检查，实际应用中可能需要更复杂的检测
        let fileManager = FileManager.default
        if let _ = fileManager.ubiquityIdentityToken {
            isCloudAvailable = true
            syncStatus = .synced
        } else {
            isCloudAvailable = false
            syncStatus = .offline
        }
    }
    
    // 更新本地存储信息
    private func updateStorageInfo() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let documentsDirectoryAttributes = try fileManager.attributesOfItem(atPath: documentsURL.path)
            if let documentsFolderSize = documentsDirectoryAttributes[.size] as? NSNumber {
                let sizeInMB = Double(truncating: documentsFolderSize) / (1024.0 * 1024.0)
                storageInfo = String(format: "本地存储: %.2f MB", sizeInMB)
            }
        } catch {
            storageInfo = "无法获取存储信息"
        }
    }
    
    // 当开始存储时调用
    func didStartSaving() {
        status = .saving
    }
    
    // 当存储成功时调用
    func didCompleteSaving() {
        lastLocalSaveTime = Date()
        status = .saved
    }
    
    // 手动更新最后本地保存时间
    func updateLastLocalSaveTime() {
        lastLocalSaveTime = Date()
    }
    
    // 当存储失败时调用
    func didFailSaving() {
        status = .failed
    }
    
    // 当云同步开始时调用
    func didStartCloudSync() {
        syncStatus = .syncing
    }
    
    // 当云同步完成时调用
    func didCompleteCloudSync() {
        lastCloudSyncTime = Date()
        syncStatus = .synced
    }
    
    // 当云同步失败时调用
    func didFailCloudSync() {
        syncStatus = .failed
    }
    
    // 获取格式化的状态信息
    func getStatusInfo() -> String {
        let localTime = lastLocalSaveTime?.formatted(date: .omitted, time: .standard) ?? "从未"
        
        let statusText: String
        switch status {
        case .saving:
            statusText = "正在保存..."
        case .saved:
            statusText = "数据已保存"
        case .failed:
            statusText = "保存失败，请稍后重试"
        case .unknown:
            statusText = "未知状态"
        }
        
        return """
        本地存储：\(statusText)，最后保存于 \(localTime)
        \(storageInfo)
        """
    }
} 