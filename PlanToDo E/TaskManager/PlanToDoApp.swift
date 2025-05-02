import SwiftUI
import Combine
// 导入AppDelegate
#if os(iOS)
import UIKit
#endif

// 显式使用我们的Task模型

@main
struct PlanToDoApp: App {
    // 添加AppDelegate来处理应用级的设置和错误处理
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #else
    // macOS平台下直接创建AppDelegate实例
    let appDelegate = AppDelegate()
    #endif
    
    // 创建ViewModel实例
    @StateObject private var viewModel = MainViewModel()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                // 任务标签页
                MainView(viewModel: viewModel)
                    .tabItem {
                        Image(systemName: "checklist")
                        Text("任务")
                    }
                
                // 设置标签页
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("设置")
                    }
            }
            .accentColor(.blue) // 设置选中标签的颜色
        }
    }
} 
