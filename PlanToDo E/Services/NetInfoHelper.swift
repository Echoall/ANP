import Foundation
import Network
import CoreLocation
import SystemConfiguration.CaptiveNetwork
import UIKit
import Darwin.POSIX.netdb
import Darwin.POSIX.sys.socket

/// 网络信息助手
class NetInfoHelper {
    /// 单例
    static let shared = NetInfoHelper()
    
    /// 位置管理器（用于获取WiFi信息）
    private let locationManager = CLLocationManager()
    /// 最后一次成功的SSID
    private var lastKnownSSID: String?
    
    /// 初始化
    private init() {
        setupLocationManager()
    }
    
    /// 设置位置管理器
    private func setupLocationManager() {
        locationManager.delegate = nil
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        // 仅用于获取WiFi信息，不进行实际定位
    }
    
    /// 获取当前WiFi SSID
    /// - Returns: SSID字符串，如果无法获取则返回nil
    func getCurrentWiFiSSID() -> String? {
        #if targetEnvironment(simulator)
        return "Simulator WiFi"
        #else
        // 需要定位权限才能获取SSID
        guard CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
              CLLocationManager.authorizationStatus() == .authorizedAlways else {
            // 没有定位权限，返回上次已知的SSID或提示
            return lastKnownSSID ?? "需要定位权限才能获取WiFi信息"
        }
        
        // 尝试获取SSID
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
            return nil
        }
        
        for interface in interfaces {
            guard let interfaceInfo = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] else {
                continue
            }
            
            if let ssid = interfaceInfo["SSID"] as? String {
                lastKnownSSID = ssid
                return ssid
            }
        }
        #endif
        
        return nil
    }
    
    /// 检查是否可能是蜂窝数据更新问题
    /// - Returns: 是否可能需要更新
    func isCellularDataUpdatePossiblyNeeded() -> Bool {
        let monitor = NetworkMonitor.shared
        
        // 如果WiFi已连接但API访问被拒绝，可能是需要更新蜂窝数据
        if monitor.connectionType == .wifi && monitor.detailedNetworkStatus == .wifiDenied {
            // 检查是否是首次运行应用
            let isFirstRun = UserDefaults.standard.bool(forKey: "hasRunBefore") == false
            if isFirstRun {
                UserDefaults.standard.set(true, forKey: "hasRunBefore")
                return true
            }
        }
        
        return false
    }
    
    /// 请求定位权限（用于获取WiFi信息）
    func requestLocationPermission() {
        locationManager.delegate = LocationDelegate.shared
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// 打开系统设置
    /// - Parameter settingType: 设置类型
    func openSystemSettings(settingType: SettingsType) {
        var settingsUrl: URL?
        
        switch settingType {
        case .wifi:
            settingsUrl = URL(string: UIApplication.openSettingsURLString)
        case .cellular:
            settingsUrl = URL(string: UIApplication.openSettingsURLString)
        case .networkSettings:
            settingsUrl = URL(string: UIApplication.openSettingsURLString)
        }
        
        if let url = settingsUrl, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    /// 设置类型枚举
    enum SettingsType {
        case wifi
        case cellular
        case networkSettings
    }
    
    /// 执行网络诊断
    /// - Parameter completion: 完成回调
    func performNetworkDiagnostics(completion: @escaping ([String: String]) -> Void) {
        var diagnostics: [String: String] = [:]
        
        // 记录基本网络状态
        let networkMonitor = NetworkMonitor.shared
        diagnostics["connection_status"] = networkMonitor.isConnected ? "已连接" : "未连接"
        diagnostics["connection_type"] = connectionTypeString(networkMonitor.connectionType)
        
        // 记录网络接口
        if let ssid = getCurrentWiFiSSID() {
            diagnostics["wifi_ssid"] = ssid
        }
        
        // 检查是否可以访问特定API
        checkAPIAccess { accessResult in
            diagnostics["api_access"] = accessResult ? "可访问" : "不可访问"
            
            // 记录DNS解析情况
            self.testDNSResolution { dnsResult in
                diagnostics["dns_resolution"] = dnsResult
                
                // 记录网络连接历史
                diagnostics["connection_history"] = self.getConnectionHistory()
                
                // 返回诊断结果
                completion(diagnostics)
            }
        }
    }
    
    /// 连接类型字符串
    /// - Parameter type: 连接类型
    /// - Returns: 描述字符串
    private func connectionTypeString(_ type: NetworkMonitor.ConnectionType) -> String {
        switch type {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "蜂窝数据"
        case .ethernet:
            return "有线以太网"
        case .unknown:
            return "未知"
        }
    }
    
    /// 检查API访问
    /// - Parameter completion: 完成回调
    private func checkAPIAccess(completion: @escaping (Bool) -> Void) {
        // 尝试访问一个简单的API端点
        guard let url = URL(string: "https://www.apple.com/library/test/success.html") else {
            completion(false)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("API访问测试失败: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false)
                return
            }
            
            completion(httpResponse.statusCode == 200)
        }
        
        task.resume()
    }
    
    /// 测试DNS解析
    /// - Parameter completion: 完成回调
    private func testDNSResolution(completion: @escaping (String) -> Void) {
        let hostnames = ["apple.com", "google.com", "baidu.com"]
        var results: [String] = []
        let group = DispatchGroup()
        
        for hostname in hostnames {
            group.enter()
            
            let host = CFHostCreateWithName(nil, hostname as CFString).takeRetainedValue()
            CFHostStartInfoResolution(host, .addresses, nil)
            
            var success: DarwinBoolean = false
            if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?,
               success.boolValue {
                results.append("\(hostname): 解析成功")
            } else {
                results.append("\(hostname): 解析失败")
            }
            
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(results.joined(separator: "\n"))
        }
    }
    
    /// 获取连接历史
    /// - Returns: 连接历史字符串
    private func getConnectionHistory() -> String {
        // 这里可以实现一个简单的连接历史记录系统
        // 但由于需要持久化存储，此处仅返回模拟数据
        return "最近一次连接尝试: \(Date().description)"
    }
    
    /// 获取当前WiFi SSID（简化命名，与NetworkFixUtility调用匹配）
    /// - Returns: SSID字符串，如果无法获取则返回nil
    func getWiFiSSID() -> String? {
        return getCurrentWiFiSSID()
    }
    
    /// 获取DNS服务器列表
    /// - Parameter completion: 完成回调，返回DNS服务器字符串数组
    func getDNSServers(completion: @escaping ([String]?) -> Void) {
        // 由于iOS系统限制，难以直接获取DNS服务器配置
        // 使用模拟数据作为DNS服务器列表
        DispatchQueue.global(qos: .background).async {
            #if targetEnvironment(simulator)
            // 模拟器环境
            let servers = ["8.8.8.8", "8.8.4.4"] // Google DNS
            #else
            // 实际设备，尝试使用常见DNS
            let servers = ["8.8.8.8", "8.8.4.4", "114.114.114.114", "223.5.5.5"]
            #endif
            
            DispatchQueue.main.async {
                completion(servers)
            }
        }
    }
}

/// 位置管理器代理
class LocationDelegate: NSObject, CLLocationManagerDelegate {
    static let shared = LocationDelegate()
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            // 权限获取成功，可以尝试获取WiFi信息
            _ = NetInfoHelper.shared.getCurrentWiFiSSID()
        }
    }
} 