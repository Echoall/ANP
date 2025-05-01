import Foundation
import Combine
import SwiftUI

class CalendarViewModel: ObservableObject {
    // 使用自定义的任务类型别名
    typealias TaskItem = Task
    
    @Published var tasksByDate: [Date: [TaskItem]] = [:]
    @Published var selectedDate = Date()
    @Published var isLoading = false
    @Published var error: Error?
    
    let mainViewModel: MainViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(mainViewModel: MainViewModel = MainViewModel.shared) {
        self.mainViewModel = mainViewModel
        
        // 监听任务变化
        setupTasksSubscription()
        
        // 初始加载数据
        loadTasks()
    }
    
    private func setupTasksSubscription() {
        mainViewModel.$tasks
            .sink { [weak self] tasks in
                self?.organizeTasksByDate(from: tasks)
            }
            .store(in: &cancellables)
    }
    
    private func loadTasks() {
        organizeTasksByDate(from: mainViewModel.tasks)
    }
    
    private func organizeTasksByDate(from tasksByCategory: [UUID: [TaskItem]]) {
        var newTasksByDate: [Date: [TaskItem]] = [:]
        
        // 遍历所有分类的任务
        for (_, tasks) in tasksByCategory {
            for task in tasks {
                // 获取任务日期的0点时间，作为字典的键
                let calendar = Calendar.current
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: task.dueDate)
                if let dateKey = calendar.date(from: dateComponents) {
                    // 将任务添加到对应日期的数组中
                    if newTasksByDate[dateKey] == nil {
                        newTasksByDate[dateKey] = []
                    }
                    newTasksByDate[dateKey]?.append(task)
                }
            }
        }
        
        // 更新发布的变量
        DispatchQueue.main.async {
            self.tasksByDate = newTasksByDate
        }
    }
    
    // 获取所选日期的任务
    func tasksForSelectedDate() -> [TaskItem]? {
        let calendar = Calendar.current
        return tasksByDate.first(where: { calendar.isDate($0.key, inSameDayAs: selectedDate) })?.value
    }
    
    // 判断日期是否有任务
    func hasTasks(for date: Date) -> Bool {
        tasksByDate.keys.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) })
    }
    
    // 获取月份中的所有日期
    func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let currentMonth = Date()
        
        // 获取当月的第一天
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstDayOfMonth = calendar.date(from: components) else { return [] }
        
        // 获取当月的天数
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let numberOfDaysInMonth = range.count
        
        // 获取第一天是星期几 (0 是星期日)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // 填充前面的空格
        var days = Array(repeating: nil as Date?, count: firstWeekday - 1)
        
        // 填充当月的日期
        for day in 1...numberOfDaysInMonth {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(dayDate)
            }
        }
        
        // 确保总数是7的倍数以完整显示网格
        let remainder = days.count % 7
        if remainder > 0 {
            days.append(contentsOf: Array(repeating: nil as Date?, count: 7 - remainder))
        }
        
        return days
    }
    
    // 判断两个日期是否是同一天
    func isSameDay(date1: Date, date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    // 日期格式化
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    // 月份年份格式化
    let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
} 