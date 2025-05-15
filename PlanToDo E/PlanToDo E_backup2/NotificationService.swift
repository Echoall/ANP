import Foundation
#if os(iOS)
import UserNotifications
#else
import AppKit
#endif

class NotificationService {
    static let shared = NotificationService()
    
    private init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        #if os(iOS)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("通知权限已获取")
            } else if let error = error {
                print("通知权限获取失败: \(error.localizedDescription)")
            }
        }
        #else
        // macOS不需要请求通知权限
        print("macOS平台不需要请求通知权限")
        #endif
    }
    
    func scheduleTaskReminder(for task: Task) {
        guard let reminderDate = task.reminderDate else { return }
        
        #if os(iOS)
        let content = UNMutableNotificationContent()
        content.title = "任务提醒"
        content.body = task.title
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("添加提醒失败: \(error.localizedDescription)")
            }
        }
        #else
        // macOS通知实现（为简单起见提供空实现）
        print("macOS平台上暂未实现任务提醒功能: \(task.title)")
        #endif
    }
    
    func cancelTaskReminder(for taskId: UUID) {
        #if os(iOS)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [taskId.uuidString])
        #else
        // macOS取消通知实现（为简单起见提供空实现）
        print("macOS平台上取消任务提醒: \(taskId)")
        #endif
    }
} 