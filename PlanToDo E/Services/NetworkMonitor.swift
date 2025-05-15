import Foundation
import Network

/// 网络状态监控器
public class NetworkMonitor: ObservableObject {
    /// 单例实例
    static let shared = NetworkMonitor()
    
    /// 网络是否可用
    @Published public private(set) var isConnected = false
    /// 连接类型
    @Published public private(set) var connectionType = ConnectionType.unknown
    /// 详细的网络状态
    @Published var detailedNetworkStatus: DetailedNetworkStatus = .unknown
    /// 上次连接失败的原因
    @Published var lastConnectionFailureReason: String?
    /// 连续失败次数
    private var consecutiveFailures = 0
    
    /// 网络路径监控器
    private let monitor = NWPathMonitor()
    /// 监控队列
    private let queue = DispatchQueue(label: "NetworkMonitor")
    /// 定时重试计时器
    private var retryTimer: Timer?
    
    /// 连接类型枚举
    public enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    /// 详细网络状态枚举
    enum DetailedNetworkStatus {
        case connected           // 已连接且工作正常
        case connectedLimited    // 已连接但功能受限
        case wifiDenied          // WiFi接口访问被拒绝
        case cellularDenied      // 蜂窝数据访问被拒绝
        case disconnected        // 完全断开连接
        case unknown             // 未知状态
    }
    
    /// 私有初始化方法
    private init() {
        #if targetEnvironment(simulator)
        // 在模拟器环境中，默认设置网络为可用状态
        print("[NetworkMonitor] 模拟器环境检测：默认设置网络为可用")
        isConnected = true
        detailedNetworkStatus = .connected
        connectionType = .wifi
        #endif
        
        startMonitoring()
    }
    
    /// 开始监控网络状态
    public func startMonitoring() {
        stopMonitoring() // 确保先停止之前的监控
        
        #if targetEnvironment(simulator)
        // 在模拟器中，优先设置网络为可用状态，但仍然继续监控
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = true
            self?.detailedNetworkStatus = .connected
            self?.connectionType = .wifi
            print("[NetworkMonitor] 模拟器环境：强制设置网络为可用状态")
        }
        #endif
        
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let oldIsConnected = self?.isConnected ?? false
                
                #if targetEnvironment(simulator)
                // 模拟器环境下，保持网络为可用状态，但仍记录实际网络状态
                let actualConnected = path.status == .satisfied
                print("[NetworkMonitor] 模拟器环境：实际网络状态 - \(actualConnected ? "已连接" : "未连接")")
                
                // 分析实际网络状态供参考，但不影响isConnected值
                self?.analyzeNetworkPathDetails(path: path)
                self?.extractFailureReason(path)
                
                // 保持模拟器中网络为可用状态
                self?.isConnected = true
                #else
                // 真机环境下正常处理
                // 首先更新详细状态
                self?.analyzeNetworkPathDetails(path: path)
                
                // 提取可能的失败原因
                self?.extractFailureReason(path)
                
                // 根据路径状态和详细状态更新isConnected
                // 即使path.status是satisfied，如果是wifiDenied或cellularDenied，也视为不可连接
                if path.status == .satisfied {
                    let detailedStatus = self?.detailedNetworkStatus ?? .unknown
                    if detailedStatus != .wifiDenied && detailedStatus != .cellularDenied {
                        self?.isConnected = true
                    } else {
                        self?.isConnected = false
                        // 这里有权限问题，记录失败原因
                        if detailedStatus == .wifiDenied {
                            self?.lastConnectionFailureReason = "WiFi接口访问被拒绝，需要在设置中允许应用访问本地网络"
                        } else {
                            self?.lastConnectionFailureReason = "蜂窝数据接口访问被拒绝，需要在设置中允许应用使用蜂窝数据"
                        }
                    }
                } else {
                    self?.isConnected = false
                }
                #endif
                
                // 如果连接状态变化，进行相应处理
                if oldIsConnected != self?.isConnected {
                    if self?.isConnected == true {
                        // 连接恢复，重置失败计数
                        self?.consecutiveFailures = 0
                        self?.stopRetryTimer()
                    } else {
                        // 连接丢失，增加失败计数
                        self?.handleConnectionLoss(path)
                    }
                }
                
                // 打印详细的网络路径信息，便于调试
                print("网络状态更新：\(path.status == .satisfied ? "已连接" : "未连接")")
                print("网络接口：\(path.availableInterfaces.map { $0.name }.joined(separator: ", "))")
                print("网络路径信息：\(path.debugDescription)")
                if let self = self {
                    print("实际连接状态：\(self.isConnected ? "可用" : "不可用")")
                    print("详细网络状态：\(self.detailedNetworkStatusString)")
                }
            }
        }
        
        // 正确的位置：在设置完 pathUpdateHandler 后启动监控
        monitor.start(queue: queue)
    }
    
    /// 获取详细网络状态字符串描述
    private var detailedNetworkStatusString: String {
        switch detailedNetworkStatus {
        case .connected: return "已连接，网络正常"
        case .connectedLimited: return "已连接，但网络功能受限"
        case .wifiDenied: return "Wi-Fi接口访问被拒绝"
        case .cellularDenied: return "蜂窝数据接口访问被拒绝"
        case .disconnected: return "网络已断开"
        case .unknown: return "未知状态"
        }
    }
    
    /// 停止监控
    public func stopMonitoring() {
        monitor.cancel()
        stopRetryTimer()
    }
    
    /// 停止重试计时器
    private func stopRetryTimer() {
        retryTimer?.invalidate()
        retryTimer = nil
    }
    
    /// 处理连接丢失
    /// - Parameter path: 网络路径
    private func handleConnectionLoss(_ path: NWPath) {
        consecutiveFailures += 1
        
        // 提取连接失败原因
        extractFailureReason(path)
        
        // 如果连续失败次数较多，尝试进行网络修复
        if consecutiveFailures >= 3 {
            print("连续网络连接失败\(consecutiveFailures)次，尝试自动修复")
            attemptAutoRepair()
        } else if retryTimer == nil {
            // 启动定时重试
            scheduleRetry()
        }
    }
    
    /// 提取连接失败原因
    /// - Parameter path: 网络路径
    private func extractFailureReason(_ path: NWPath) {
        let pathDescription = path.debugDescription
        
        if pathDescription.contains("Denied over Wi-Fi interface") {
            lastConnectionFailureReason = "WiFi接口访问被拒绝"
            detailedNetworkStatus = .wifiDenied
        } else if pathDescription.contains("Denied over cellular interface") {
            lastConnectionFailureReason = "蜂窝数据接口访问被拒绝"
            detailedNetworkStatus = .cellularDenied
        } else if path.status == .unsatisfied {
            lastConnectionFailureReason = "网络连接不满足要求"
            detailedNetworkStatus = .disconnected
        } else if path.status == .satisfied && 
                  (detailedNetworkStatus != .wifiDenied && 
                   detailedNetworkStatus != .cellularDenied) {
            // 如果路径满足并且没有特定的拒绝状态，清除失败原因
            lastConnectionFailureReason = nil
        }
    }
    
    /// 分析网络路径详情
    /// - Parameter path: 网络路径
    private func analyzeNetworkPathDetails(path: NWPath) {
        // 首先根据路径状态更新基本连接状态
        let pathSatisfied = path.status == .satisfied
        
        // 分析详细的网络状态
        if pathSatisfied {
            // 路径满足要求的情况
            if path.isConstrained {
                detailedNetworkStatus = .connectedLimited
                isConnected = true  // 虽然受限但仍然可用
            } else {
                detailedNetworkStatus = .connected
                isConnected = true
            }
        } else {
            // 路径不满足要求的情况
            let hasWifi = path.availableInterfaces.contains(where: { $0.type == .wifi })
            let hasCellular = path.availableInterfaces.contains(where: { $0.type == .cellular })
            let usesWifi = path.usesInterfaceType(.wifi)
            let usesCellular = path.usesInterfaceType(.cellular)
            
            if hasWifi && !usesWifi && !usesCellular {
                // WiFi接口可用但不被使用，且没有使用蜂窝数据，可能是被拒绝了
                detailedNetworkStatus = .wifiDenied
                isConnected = false
                print("[NetworkMonitor] 检测到WiFi接口可用但未被使用 - 可能是访问被拒绝")
                // 尝试自动修复
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.attemptAutoRepair()
                }
            } else if hasCellular && !usesCellular && !usesWifi {
                // 蜂窝接口可用但不被使用，且没有使用WiFi，可能是被拒绝了
                detailedNetworkStatus = .cellularDenied
                isConnected = false
                print("[NetworkMonitor] 检测到蜂窝接口可用但未被使用 - 可能是访问被拒绝")
                // 尝试自动修复
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.attemptAutoRepair()
                }
            } else {
                // 其他未连接情况
                detailedNetworkStatus = .disconnected
                isConnected = false
            }
        }
        
        // 更新连接类型
        connectionType = checkConnectionType(path)
        
        // 输出详细的网络状态日志
        print(getNetworkStatusDescription())
    }
    
    /// 接口类型转字符串
    /// - Parameter type: 接口类型
    /// - Returns: 字符串描述
    private func interfaceTypeToString(_ type: NWInterface.InterfaceType) -> String {
        switch type {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return "蜂窝数据"
        case .wiredEthernet:
            return "有线以太网"
        case .loopback:
            return "回环"
        case .other:
            return "其他"
        @unknown default:
            return "未知"
        }
    }
    
    /// 安排重试
    private func scheduleRetry() {
        DispatchQueue.main.async { [weak self] in
            self?.retryTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
                print("尝试重新检测网络状态...")
                // 临时重启网络监控器
                self?.monitor.cancel()
                
                // 短暂延迟后重新启动监控
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.monitor.start(queue: self?.queue ?? DispatchQueue(label: "NetworkMonitor.Retry"))
                }
            }
        }
    }
    
    /// 尝试自动修复
    private func attemptAutoRepair() {
        // 尝试自动修复网络问题
        switch detailedNetworkStatus {
        case .wifiDenied:
            print("[NetworkMonitor] 尝试修复WiFi访问被拒绝问题...")
            
            // 1. 尝试关闭并重新启动网络监控
            stopMonitoring()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.startMonitoring()
            }
            
            // 2. 检查是否可以使用蜂窝网络
            if monitor.currentPath.availableInterfaces.contains(where: { $0.type == .cellular }) {
                print("[NetworkMonitor] 检测到蜂窝网络可用，系统将自动尝试切换...")
            }
            
            // 3. 通知用户可能需要检查网络设置
            NotificationCenter.default.post(
                name: NSNotification.Name("NetworkRepairAttempted"),
                object: nil,
                userInfo: ["status": "wifiDenied", "message": "WiFi访问权限被拒绝，请检查应用设置中的网络权限"]
            )
            
        case .cellularDenied:
            print("[NetworkMonitor] 尝试修复蜂窝网络访问被拒绝问题...")
            
            // 1. 尝试关闭并重新启动网络监控
            stopMonitoring()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.startMonitoring()
            }
            
            // 2. 检查是否可以使用WiFi网络
            if monitor.currentPath.availableInterfaces.contains(where: { $0.type == .wifi }) {
                print("[NetworkMonitor] 检测到WiFi网络可用，系统将自动尝试切换...")
            }
            
            // 通知用户
            NotificationCenter.default.post(
                name: NSNotification.Name("NetworkRepairAttempted"),
                object: nil, 
                userInfo: ["status": "cellularDenied", "message": "蜂窝数据访问权限被拒绝，请检查应用设置中的网络权限"]
            )
            
        case .disconnected:
            print("[NetworkMonitor] 网络断开，尝试重新连接...")
            
            // 重新开始监控
            stopMonitoring()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.startMonitoring()
            }
            
        default:
            print("[NetworkMonitor] 当前网络状态不需要修复")
        }
    }
    
    /// 获取连接类型
    /// - Parameter path: 网络路径
    private func checkConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
    
    /// 获取当前网络状态详细描述
    /// - Returns: 状态描述字符串
    func getNetworkStatusDescription() -> String {
        var description = "网络状态: "
        
        switch detailedNetworkStatus {
        case .connected:
            description += "已连接，网络正常"
        case .connectedLimited:
            description += "已连接，但网络功能受限"
        case .wifiDenied:
            description += "Wi-Fi接口访问被拒绝"
        case .cellularDenied:
            description += "蜂窝数据接口访问被拒绝"
        case .disconnected:
            description += "网络已断开"
        case .unknown:
            description += "未知状态"
        }
        
        description += "\n连接类型: "
        switch connectionType {
        case .wifi:
            description += "Wi-Fi"
        case .cellular:
            description += "蜂窝数据"
        case .ethernet:
            description += "有线以太网"
        case .unknown:
            description += "未知"
        }
        
        if let reason = lastConnectionFailureReason {
            description += "\n上次连接失败原因: \(reason)"
        }
        
        return description
    }
    
    deinit {
        stopMonitoring()
    }
} 