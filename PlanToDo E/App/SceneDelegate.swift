import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // 启动网络监控
        _ = NetworkMonitor.shared
        print("Scene已连接，网络监控已启动")
        
        // 其他场景连接代码...
    }
    
    // 其他方法...
} 