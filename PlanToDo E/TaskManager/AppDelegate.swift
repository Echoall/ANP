import Foundation
#if os(iOS)
import UIKit

// 应用程序的AppDelegate，独立为一个单独的文件以避免重复定义
public class AppDelegate: NSObject, UIApplicationDelegate {
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 应用程序启动时的初始化代码
        print("应用程序已启动")
        
        // 设置用户通知
        setupNotifications()
        
        return true
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