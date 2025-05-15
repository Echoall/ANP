import UIKit
import CoreData

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // 启动网络监控
        _ = NetworkMonitor.shared
        print("应用程序已启动，网络监控已启动")
        
        // 设置网络修复相关的通知接收者
        setupNetworkNotifications()
        
        // 延迟检查网络状态，如果有问题则尝试自动修复
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.checkAndRepairNetworkIfNeeded()
        }
        
        // 注册应用激活通知，用于每次应用从后台恢复时检查网络
        NotificationCenter.default.addObserver(self, 
                                               selector: #selector(applicationDidBecomeActive), 
                                               name: UIApplication.didBecomeActiveNotification, 
                                               object: nil)
        
        return true
    }
    
    /// 设置网络修复相关的通知接收
    private func setupNetworkNotifications() {
        // 监听网络修复尝试通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNetworkRepairAttempted),
            name: NSNotification.Name("NetworkRepairAttempted"),
            object: nil
        )
        
        // 监听需要手动修复网络的通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNetworkManualFixNeeded),
            name: NSNotification.Name("NetworkManualFixNeeded"),
            object: nil
        )
        
        // 监听需要修复网络权限的通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNetworkPermissionFixNeeded),
            name: NSNotification.Name("NetworkPermissionFixNeeded"),
            object: nil
        )
    }
    
    /// 处理网络修复尝试通知
    @objc private func handleNetworkRepairAttempted(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let status = userInfo["status"] as? String,
              let message = userInfo["message"] as? String else {
            return
        }
        
        print("[AppDelegate] 收到网络修复尝试通知: \(status) - \(message)")
        
        // 这里可以根据不同的状态执行不同的操作
        // 例如显示一个临时提示或者记录日志
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            // 延迟后再次检查网络状态
            self.checkAndRepairNetworkIfNeeded()
        }
    }
    
    /// 处理需要手动修复网络的通知
    @objc private func handleNetworkManualFixNeeded(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let title = userInfo["title"] as? String,
              let message = userInfo["message"] as? String else {
            return
        }
        
        print("[AppDelegate] 收到需要手动修复网络的通知: \(title)")
        
        // 在主线程显示提示
        DispatchQueue.main.async {
            // 这里应显示一个弹窗提示用户
            // 由于这是AppDelegate，我们需要获取当前的主窗口来显示警告
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "好的", style: .default))
                alert.addAction(UIAlertAction(title: "打开设置", style: .default) { _ in
                    // 打开设置应用
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString),
                       UIApplication.shared.canOpenURL(settingsURL) {
                        UIApplication.shared.open(settingsURL)
                    }
                })
                
                window.rootViewController?.present(alert, animated: true)
            }
        }
    }
    
    /// 处理需要修复网络权限的通知
    @objc private func handleNetworkPermissionFixNeeded(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let title = userInfo["title"] as? String,
              let message = userInfo["message"] as? String else {
            return
        }
        
        print("[AppDelegate] 收到需要修复网络权限的通知: \(title)")
        
        // 在主线程显示提示
        DispatchQueue.main.async {
            // 这里应显示一个弹窗提示用户
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "稍后再说", style: .cancel))
                alert.addAction(UIAlertAction(title: "打开设置", style: .default) { _ in
                    // 打开设置应用
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString),
                       UIApplication.shared.canOpenURL(settingsURL) {
                        UIApplication.shared.open(settingsURL)
                    }
                })
                
                window.rootViewController?.present(alert, animated: true)
            }
        }
    }
    
    /// 应用程序激活时调用
    @objc func applicationDidBecomeActive() {
        // 每次应用激活时检查网络状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkAndRepairNetworkIfNeeded()
        }
    }
    
    /// 检查并在需要时修复网络
    private func checkAndRepairNetworkIfNeeded() {
        let networkMonitor = NetworkMonitor.shared
        
        print("[AppDelegate] 检查网络状态: \(networkMonitor.isConnected ? "已连接" : "未连接")")
        print("[AppDelegate] 详细网络状态: \(networkMonitor.getNetworkStatusDescription())")
        
        // 如果检测到网络有问题，尝试修复
        if !networkMonitor.isConnected || networkMonitor.detailedNetworkStatus != .connected {
            print("[AppDelegate] 检测到网络问题，尝试自动修复...")
            
            // 检查是否是蜂窝数据更新问题
            if NetInfoHelper.shared.isCellularDataUpdatePossiblyNeeded() {
                print("[AppDelegate] 可能需要蜂窝数据更新，提示用户...")
                // 显示蜂窝数据更新提示
                showCellularUpdateNeededAlert()
            }
            
            // 查看详细网络状态，针对性处理
            switch networkMonitor.detailedNetworkStatus {
            case .wifiDenied:
                print("[AppDelegate] 检测到WiFi访问被拒绝")
                // 提示用户授予WiFi权限
                showNetworkPermissionAlert(forType: "WiFi")
                
            case .cellularDenied:
                print("[AppDelegate] 检测到蜂窝数据访问被拒绝")
                // 提示用户授予蜂窝数据权限
                showNetworkPermissionAlert(forType: "蜂窝数据")
                
            default:
                // 针对其他类型的网络问题，尝试自动修复
                NetworkFixUtility.shared.attemptNetworkFix { [weak self] success in
                    guard let self = self else { return }
                    
                    if success {
                        print("[AppDelegate] 网络自动修复成功！")
                        // 可以通知用户网络已恢复
                    } else {
                        print("[AppDelegate] 网络自动修复失败，需要用户手动干预")
                        // 提示用户手动处理
                        self.showNetworkManualFixAlert()
                    }
                }
            }
        } else {
            print("[AppDelegate] 网络连接正常，无需修复")
        }
    }
    
    /// 显示蜂窝数据更新需要的提示
    private func showCellularUpdateNeededAlert() {
        // 在主线程显示提示
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                
                let alert = UIAlertController(
                    title: "蜂窝数据需要更新",
                    message: "您的应用需要访问蜂窝数据。请前往设置 > 蜂窝网络，确保本应用已获得权限。",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "稍后再说", style: .cancel))
                alert.addAction(UIAlertAction(title: "打开设置", style: .default) { _ in
                    // 打开设置应用
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString),
                       UIApplication.shared.canOpenURL(settingsURL) {
                        UIApplication.shared.open(settingsURL)
                    }
                })
                
                window.rootViewController?.present(alert, animated: true)
            }
        }
    }
    
    /// 显示网络权限提示
    private func showNetworkPermissionAlert(forType type: String) {
        // 在主线程显示提示
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                
                let alert = UIAlertController(
                    title: "\(type)访问权限问题",
                    message: "应用无法访问\(type)网络。请前往设置 > 隐私与安全性，确保本应用已获得\(type)访问权限。",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "稍后再说", style: .cancel))
                alert.addAction(UIAlertAction(title: "打开设置", style: .default) { _ in
                    // 打开设置应用
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString),
                       UIApplication.shared.canOpenURL(settingsURL) {
                        UIApplication.shared.open(settingsURL)
                    }
                })
                
                window.rootViewController?.present(alert, animated: true)
            }
        }
    }
    
    /// 显示手动修复网络提示
    private func showNetworkManualFixAlert() {
        // 在主线程显示提示
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                
                let alert = UIAlertController(
                    title: "网络连接问题",
                    message: "应用无法连接到网络。请尝试以下步骤:\n1. 检查WiFi连接\n2. 尝试使用蜂窝数据\n3. 重启设备\n4. 在设置中重置网络设置",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "好的", style: .default))
                alert.addAction(UIAlertAction(title: "打开设置", style: .default) { _ in
                    // 打开设置应用
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString),
                       UIApplication.shared.canOpenURL(settingsURL) {
                        UIApplication.shared.open(settingsURL)
                    }
                })
                
                window.rootViewController?.present(alert, animated: true)
            }
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting scene: UIScene, willMoveToSession session: UISceneSession, options: UIScene.ConnectionOptions) {
        // Called when a new scene is being created.
        // Use this method to select a configuration to create the new scene with.
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called when the user quits.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "PlanToDo_Clean")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 