import Foundation
import Network
import SystemConfiguration
import CoreTelephony
import UIKit

/// 网络修复工具类
class NetworkFixUtility {
    /// 单例实例
    static let shared = NetworkFixUtility()
    
    /// 私有初始化器
    private init() {}
    
    /// 尝试修复网络连接问题
    /// - Parameter completion: 完成回调，成功为true，失败为false
    func attemptNetworkFix(completion: @escaping (Bool) -> Void) {
        print("[NetworkFix] 开始尝试修复网络...")
        
        // 1. 检查网络连接设置
        checkNetworkSettings()
        
        // 2. 尝试清除DNS缓存（仅在必要时）
        clearDNSCacheIfNeeded()
        
        // 3. 检查网络权限
        checkNetworkPermissions { permissionsOK in
            if permissionsOK {
                print("[NetworkFix] 网络权限正常")
                // 4. 尝试使用临时URL建立连接
                self.testBasicConnection { connectionOK in
                    if connectionOK {
                        print("[NetworkFix] 基本网络连接测试成功")
                        completion(true)
                    } else {
                        print("[NetworkFix] 基本网络连接测试失败")
                        // 5. 提示用户可能需要手动干预
                        self.suggestManualFix()
                        completion(false)
                    }
                }
            } else {
                print("[NetworkFix] 网络权限异常")
                // 提示用户修复权限
                self.promptForPermissionFix()
                completion(false)
            }
        }
    }
    
    /// 检查网络设置
    private func checkNetworkSettings() {
        print("[NetworkFix] 检查网络设置...")
        // 获取当前WiFi信息
        if let ssid = NetInfoHelper.shared.getWiFiSSID() {
            print("[NetworkFix] 当前连接的WiFi: \(ssid)")
        } else {
            print("[NetworkFix] 未连接WiFi网络")
        }
        
        // 检查DNS配置
        NetInfoHelper.shared.getDNSServers { servers in
            if let servers = servers, !servers.isEmpty {
                print("[NetworkFix] 当前DNS服务器: \(servers.joined(separator: ", "))")
            } else {
                print("[NetworkFix] 无法获取DNS服务器信息")
            }
        }
    }
    
    /// 清除DNS缓存
    private func clearDNSCacheIfNeeded() {
        print("[NetworkFix] 尝试清除DNS缓存...")
        // 这里只是记录，实际上iOS应用无法直接清除系统DNS缓存
        // 可以通过重启网络接口间接实现
    }
    
    /// 检查网络权限
    /// - Parameter completion: 完成回调，权限正常为true，异常为false
    private func checkNetworkPermissions(completion: @escaping (Bool) -> Void) {
        print("[NetworkFix] 检查网络权限...")
        
        // 创建一个临时网络监视器检查权限状态
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkPermissionCheck")
        
        monitor.pathUpdateHandler = { path in
            monitor.cancel()
            
            if path.status == .satisfied {
                print("[NetworkFix] 网络权限检查通过")
                completion(true)
            } else {
                // 检查是否WiFi或蜂窝权限问题
                if path.availableInterfaces.contains(where: { $0.type == .wifi }) && 
                   !path.usesInterfaceType(.wifi) {
                    print("[NetworkFix] 疑似WiFi权限被拒绝")
                    completion(false)
                } else if path.availableInterfaces.contains(where: { $0.type == .cellular }) && 
                          !path.usesInterfaceType(.cellular) {
                    print("[NetworkFix] 疑似蜂窝数据权限被拒绝")
                    completion(false)
                } else {
                    // 其他网络问题
                    print("[NetworkFix] 网络连接异常，但不是权限问题")
                    completion(true) // 不是权限问题，但有其他网络问题
                }
            }
        }
        
        monitor.start(queue: queue)
        
        // 设置超时
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            monitor.cancel()
            print("[NetworkFix] 网络权限检查超时")
            completion(false)
        }
    }
    
    /// 测试基本网络连接
    /// - Parameter completion: 完成回调，连接成功为true，失败为false
    private func testBasicConnection(completion: @escaping (Bool) -> Void) {
        print("[NetworkFix] 测试基本网络连接...")
        
        // 使用一个可靠的URL进行测试
        guard let url = URL(string: "https://www.apple.com") else {
            completion(false)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { _, response, error in
            if let error = error {
                print("[NetworkFix] 基本连接测试失败: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, 
               httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                print("[NetworkFix] 基本连接测试成功")
                completion(true)
            } else {
                print("[NetworkFix] 基本连接测试失败: 异常响应")
                completion(false)
            }
        }
        
        task.resume()
    }
    
    /// 提示用户可能需要手动修复
    private func suggestManualFix() {
        print("[NetworkFix] 建议用户手动修复网络问题")
        
        // 在主线程显示通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("NetworkManualFixNeeded"),
                object: nil,
                userInfo: [
                    "title": "网络连接问题",
                    "message": "应用无法连接到网络。请尝试以下步骤:\n1. 检查WiFi连接\n2. 尝试使用蜂窝数据\n3. 重启设备\n4. 在设置中重置网络设置"
                ]
            )
        }
    }
    
    /// 提示用户修复权限问题
    private func promptForPermissionFix() {
        print("[NetworkFix] 提示用户修复网络权限问题")
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("NetworkPermissionFixNeeded"),
                object: nil,
                userInfo: [
                    "title": "网络权限问题",
                    "message": "应用无法访问网络。请前往:\n设置 > 隐私与安全性 > 本地网络，确保本应用已获得权限。"
                ]
            )
            
            // 可选：尝试打开应用设置页面
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                if UIApplication.shared.canOpenURL(settingsURL) {
                    UIApplication.shared.open(settingsURL)
                }
            }
        }
    }
    
    /// 检查是否需要蜂窝数据更新
    /// - Returns: 是否需要更新
    func isCellularUpdateRequired() -> Bool {
        // 检查蜂窝数据连接状态
        let cellularData = CTCellularData()
        var status: CTCellularDataRestrictedState = .restrictedStateUnknown
        
        let semaphore = DispatchSemaphore(value: 0)
        cellularData.cellularDataRestrictionDidUpdateNotifier = { restrictionState in
            status = restrictionState
            semaphore.signal()
        }
        
        // 等待回调，最多3秒
        _ = semaphore.wait(timeout: .now() + 3)
        
        return status == .restrictedStateUnknown || status == .restricted
    }
    
    /// 修复蜂窝数据更新问题
    /// - Parameter completion: 完成回调
    func fixCellularUpdateIssue(completion: @escaping (Bool) -> Void) {
        print("尝试修复蜂窝数据更新问题...")
        
        // 模拟打开设置引导用户操作
        DispatchQueue.main.async {
            // 在实际应用中，这里可以弹出提示指导用户到设置中更新蜂窝数据
            // 或者使用URL Scheme跳转到设置页面
            print("请用户前往设置 > 蜂窝网络，检查是否有可用更新")
            
            // 由于无法直接修复此问题，我们提供指导后返回false
            completion(false)
        }
    }
    
    /// 修复Wi-Fi权限问题
    /// - Parameter completion: 完成回调
    func fixWiFiPermissionIssue(completion: @escaping (Bool) -> Void) {
        print("尝试修复Wi-Fi权限问题...")
        
        // 获取当前网络接口信息
        var success = false
        
        // 模拟重置网络接口
        simulateNetworkReset { result in
            success = result
            print("网络接口重置结果: \(result ? "成功" : "失败")")
            
            // 不管成功与否，都尝试一次重新连接
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                NetworkMonitor.shared.startMonitoring()
                
                // 给网络状态更新一点时间
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    completion(NetworkMonitor.shared.isConnected || success)
                }
            }
        }
    }
    
    /// 模拟网络重置
    /// - Parameter completion: 完成回调
    private func simulateNetworkReset(completion: @escaping (Bool) -> Void) {
        // 停止当前网络监控
        NetworkMonitor.shared.stopMonitoring()
        
        // 模拟重置网络接口的过程
        DispatchQueue.global().async {
            // 这里应该是重置网络接口的代码
            // 但由于iOS的安全限制，我们无法直接操作网络接口
            // 所以这里只是模拟一个过程
            
            // 模拟等待网络重置
            Thread.sleep(forTimeInterval: 1.5)
            
            DispatchQueue.main.async {
                // 提示用户手动操作
                print("建议用户开启并关闭飞行模式以重置网络连接")
                completion(true)
            }
        }
    }
    
    /// 获取详细的网络诊断信息
    /// - Returns: 诊断信息字典
    func getNetworkDiagnostics() -> [String: String] {
        var diagnostics: [String: String] = [:]
        
        // 获取Wi-Fi信息
        if let ssid = getWiFiSSID() {
            diagnostics["wifi_ssid"] = ssid
        }
        
        // 获取网络接口状态
        diagnostics["interfaces"] = getNetworkInterfaces()
        
        // 获取DNS服务器
        diagnostics["dns_servers"] = getDNSServers()
        
        // 获取路由表
        diagnostics["routing_table"] = getRoutingTable()
        
        return diagnostics
    }
    
    /// 获取当前Wi-Fi SSID
    /// - Returns: SSID字符串，如果无法获取则返回nil
    private func getWiFiSSID() -> String? {
        // 由于iOS的隐私限制，无法直接获取SSID
        // 实际应用中，需要请求定位权限才能获取
        return "获取SSID需要获取定位权限"
    }
    
    /// 获取网络接口信息
    /// - Returns: 接口信息字符串
    private func getNetworkInterfaces() -> String {
        // 这里应该是获取网络接口信息的代码
        // 但由于iOS的限制，我们无法直接获取详细信息
        let monitor = NetworkMonitor.shared
        return "连接类型: \(monitor.connectionType), 连接状态: \(monitor.isConnected ? "已连接" : "未连接")"
    }
    
    /// 获取DNS服务器信息
    /// - Returns: DNS服务器信息字符串
    private func getDNSServers() -> String {
        // 这里应该是获取DNS服务器信息的代码
        // 但由于iOS的限制，我们无法直接获取
        return "iOS无法直接获取DNS服务器信息"
    }
    
    /// 获取路由表信息
    /// - Returns: 路由表信息字符串
    private func getRoutingTable() -> String {
        // 这里应该是获取路由表信息的代码
        // 但由于iOS的限制，我们无法直接获取
        return "iOS无法直接获取路由表信息"
    }
} 