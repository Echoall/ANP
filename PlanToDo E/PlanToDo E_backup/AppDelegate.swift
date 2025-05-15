import Foundation
#if os(iOS)
import UIKit
import SwiftUI
import Combine
import UserNotifications

// 应用程序的AppDelegate，独立为一个单独的文件以避免重复定义
public class AppDelegate: NSObject, UIApplicationDelegate {
    // 最大后台运行时间（秒）
    private let maxBackgroundTime: TimeInterval = 300 // 5分钟
    private var isAppRestartNeeded = false
    private var applicationWasInBackground = false
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 应用程序启动时的初始化代码
        print("应用程序已启动")
        
        // 设置用户通知
        setupNotifications()
        
        // 设置监听内存警告通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // 重置WebView检查状态
        UserDefaults.standard.set(false, forKey: "webViewCheckFailed")
        // 设置初始检查时间
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastWebViewCheck")
        
        return true
    }
    
    // 应用即将进入后台
    public func applicationDidEnterBackground(_ application: UIApplication) {
        print("应用程序进入后台")
        applicationWasInBackground = true
        
        // 记录进入后台的时间戳
        UserDefaults.standard.set(Date(), forKey: "backgroundEnterDate")
        
        // 保存最后一次会话状态（可以在这里保存任何需要在恢复时加载的数据）
        let currentSession = [
            "timestamp": Date().timeIntervalSince1970,
            "lastAction": "entered_background"
        ] as [String: Any]
        
        if let sessionData = try? JSONSerialization.data(withJSONObject: currentSession),
           let sessionString = String(data: sessionData, encoding: .utf8) {
            UserDefaults.standard.set(sessionString, forKey: "lastChatSession")
        }
        
        UserDefaults.standard.synchronize()
    }
    
    // 应用即将进入前台
    public func applicationWillEnterForeground(_ application: UIApplication) {
        print("应用程序即将进入前台")
        
        // 仅当应用之前在后台时才执行恢复逻辑
        if applicationWasInBackground {
            // 检查应用后台运行时间
            if let enterBackgroundDate = UserDefaults.standard.object(forKey: "backgroundEnterDate") as? Date {
                let timeInBackground = Date().timeIntervalSince(enterBackgroundDate)
                
                // 如果后台时间超过设定阈值，标记需要重启
                if timeInBackground > maxBackgroundTime {
                    print("应用在后台时间过长(\(timeInBackground)秒)，标记需要重新加载")
                    isAppRestartNeeded = true
                }
            }
            
            applicationWasInBackground = false
        }
    }
    
    // 应用变为活动状态
    public func applicationDidBecomeActive(_ application: UIApplication) {
        print("applicationDidBecomeActive")
        
        // 如果需要重启应用，延迟执行以确保视图已完全加载
        if isAppRestartNeeded {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.restartApplication()
                self.isAppRestartNeeded = false
            }
        } else {
            // 否则仅发送检查WebView完整性的通知
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: NSNotification.Name("CheckWebViewIntegrity"), object: nil)
            }
        }
    }
    
    private func setupNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("用户已允许通知")
            } else if let error = error {
                print("通知授权错误: \(error.localizedDescription)")
            }
        }
    }
    
    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // 处理从其他应用或系统唤起的情况，如通用链接(Universal Links)
        // 在这里添加处理逻辑，make sure to keep this call
        return true
    }
    
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationCenter.default.post(name: .capacitorDidRegisterForRemoteNotifications, object: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationCenter.default.post(name: .capacitorDidFailToRegisterForRemoteNotifications, object: error)
    }
    
    func restartApplication() {
        // 创建一个简单的视图控制器作为过渡期间的占位符
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground
        let label = UILabel()
        label.text = "正在刷新应用..."
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])
        
        let navCtrl = UINavigationController(rootViewController: viewController)
        
        guard
            let window = UIApplication.shared.windows.first,
            let rootViewController = window.rootViewController
        else {
            return
        }
        
        navCtrl.view.frame = rootViewController.view.frame
        navCtrl.view.layoutIfNeeded()
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = navCtrl
        }) { _ in
            // 短暂延迟以提高用户体验
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // 过渡之后，通过重新创建主视图控制器来重新加载应用
                if let initialViewController = self.getInitialViewController() {
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                        window.rootViewController = initialViewController
                    }) { _ in
                        // 发布一个通知，可以在网页视图中捕获，以重新加载应用程序状态
                        NotificationCenter.default.post(name: Notification.Name("AppRestartRequired"), object: nil)
                        print("应用重启完成")
                    }
                }
            }
        }
    }
    
    // 获取初始视图控制器
    private func getInitialViewController() -> UIViewController? {
        // 使用SwiftUI视图作为初始视图控制器
        return UIHostingController(rootView: 
            TabView {
                // 任务标签页
                MainView(viewModel: MainViewModel.shared)
                    .tabItem { 
                        Image(systemName: "checklist")
                        Text("任务") 
                    }
                
                // AI助手标签页
                NavigationView {
                    ChatView()
                }
                .tabItem { 
                    Image(systemName: "message")
                    Text("AI助手") 
                }
                
                // 设置标签页
                SettingsView()
                    .tabItem { 
                        Image(systemName: "gear")
                        Text("设置") 
                    }
                
                // API测试标签页
                QwenApiTestView()
                    .tabItem {
                        Image(systemName: "network")
                        Text("API测试")
                    }
            }
            .accentColor(.blue)
        )
    }
    
    // 处理内存警告
    @objc func handleMemoryWarning() {
        print("收到内存警告")
        
        // 仅当应用处于后台时才设置恢复标志
        if UIApplication.shared.applicationState == .background {
            // 设置一个旧日期以确保下次重启
            let staleDate = Date(timeIntervalSinceNow: -(maxBackgroundTime * 2))
            UserDefaults.standard.set(staleDate, forKey: "backgroundEnterDate")
            UserDefaults.standard.synchronize() // 立即刷新数据
            print("🔴 后台内存警告: 设置过期时间戳 \(staleDate)")
        } else {
            // 应用在前台时，尝试释放一些内存资源
            print("前台内存警告：尝试释放内存资源")
            
            // 尝试清理一些缓存或临时数据
            URLCache.shared.removeAllCachedResponses()
            
            // 发送通知让各组件清理非必要资源
            NotificationCenter.default.post(name: NSNotification.Name("LowMemoryWarning"), object: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// 扩展Notification.Name以添加Capacitor通知名称
extension Notification.Name {
    static let capacitorDidRegisterForRemoteNotifications = Notification.Name("capacitorDidRegisterForRemoteNotifications")
    static let capacitorDidFailToRegisterForRemoteNotifications = Notification.Name("capacitorDidFailToRegisterForRemoteNotifications")
}
#else
// macOS版本的应用程序代理
public class AppDelegate: NSObject {
    public func application() -> Bool {
        print("应用程序已启动 (macOS)")
        return true
    }
}
#endif 