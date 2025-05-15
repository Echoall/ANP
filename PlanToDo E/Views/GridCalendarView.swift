import SwiftUI

struct GridCalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var selectedDate: Date
    @Binding var showingTaskCreateView: Bool
    @Binding var showingTaskEditSheet: Bool
    @Binding var selectedTask: Task?
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var currentMonth: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // 月份导航
            HStack {
                Button(action: {
                    withAnimation {
                        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
                            currentMonth = newDate
                        }
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .padding(8)
                }
                
                Spacer()
                
                Text(viewModel.monthYearFormatter.string(from: currentMonth))
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
                            currentMonth = newDate
                        }
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .padding(8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // 星期标题行
            HStack(spacing: 0) {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                    Text(day)
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(day == "日" || day == "六" ? .red : .primary)
                }
            }
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            // 日历网格 - 减少到28个单元格(4行x7列) 并取消间隔
            VStack(spacing: 1) {
                ForEach(0..<4) { row in
                    HStack(spacing: 1) {
                        ForEach(0..<7) { column in
                            let index = row * 7 + column
                            let days = extractDaysFromMonth()
                            if index < days.count, let date = days[index].date {
                                let hasTask = viewModel.tasksByDate.first(where: { Calendar.current.isDate($0.key, inSameDayAs: date) })?.value.count ?? 0 > 0
                                
                                GridDateCell(
                                    date: date, 
                                    isSelected: viewModel.isSameDay(date1: date, date2: selectedDate),
                                    isCurrentMonth: days[index].isCurrentMonth,
                                    tasks: viewModel.tasksByDate.first(where: { Calendar.current.isDate($0.key, inSameDayAs: date) })?.value ?? [],
                                    hasTask: hasTask,
                                    viewModel: viewModel
                                )
                                .id(days[index].id)
                                .onTapGesture {
                                    withAnimation {
                                        viewModel.selectedDate = date
                                        selectedDate = date
                                    }
                                }
                                .frame(maxWidth: hasTask ? .infinity : nil) // 有任务的格子占据更多空间
                            } else {
                                Rectangle()
                                    .foregroundColor(.clear)
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    if row < 3 {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1)
                    }
                }
            }
            .background(Color(.systemBackground))
            .padding(.horizontal, 2)
            
            // 选中日期的任务列表
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(viewModel.dateFormatter.string(from: selectedDate))
                            .font(.headline)
                        
                        Spacer()
                        
                        if let tasks = viewModel.tasksForSelectedDate(), !tasks.isEmpty {
                            Text("\(tasks.count)个任务")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    // 显示选中日期的任务
                    if let tasks = viewModel.tasksForSelectedDate(), !tasks.isEmpty {
                        ForEach(tasks) { task in
                            TaskListItem(task: task, viewModel: viewModel)
                                .padding(.horizontal)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTask = task
                                    showingTaskEditSheet = true
                                }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Spacer()
                            
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 36))
                                .foregroundColor(.gray)
                            
                            Text("这一天还没有任务")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .padding()
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }
    
    // 提取当前月的日期数据，避免日期重复
    private func extractDaysFromMonth() -> [DateInfo] {
        let calendar = Calendar.current
        
        // 获取当前月的第一天
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstDayOfMonth = calendar.date(from: components) else { return [] }
        
        // 获取当月的第一天是周几 (1是星期日, 2是星期一, ...)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // 获取当月的天数
        let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!
        let numberOfDaysInMonth = range.count
        
        var days: [DateInfo] = []
        
        // 填充上个月的日期
        if firstWeekday > 1 {
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstDayOfMonth)!
            let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)!.count
            
            for day in (daysInPreviousMonth - firstWeekday + 2)...daysInPreviousMonth {
                if let date = calendar.date(byAdding: .day, value: -(daysInPreviousMonth - day), to: firstDayOfMonth) {
                    days.append(DateInfo(id: UUID(), date: date, isCurrentMonth: false))
                }
            }
        }
        
        // 填充当月的日期 (最多填充到28格)
        let daysToShow = min(28 - days.count, numberOfDaysInMonth)
        
        for day in 1...daysToShow {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(DateInfo(id: UUID(), date: date, isCurrentMonth: true))
            }
        }
        
        // 填充下个月的日期，确保总共有28个格子
        let remainingDays = 28 - days.count
        if remainingDays > 0 {
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth)!
            
            for day in 1...remainingDays {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: nextMonth) {
                    days.append(DateInfo(id: UUID(), date: date, isCurrentMonth: false))
                }
            }
        }
        
        return days
    }
}

// 日期信息结构
struct DateInfo: Identifiable {
    let id: UUID
    let date: Date?
    let isCurrentMonth: Bool
}

// 任务列表项
struct TaskListItem: View {
    let task: Task
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 优先级颜色指示
            Circle()
                .fill(viewModel.priorityColor(task.priority))
                .frame(width: 14, height: 14)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                    .strikethrough(task.isCompleted)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Text(viewModel.formattedTime(task.dueDate))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 完成状态 - 添加点击功能
            Button(action: {
                toggleTaskCompletion()
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
    }
    
    // 切换任务完成状态
    private func toggleTaskCompletion() {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        updatedTask.updatedAt = Date()
        viewModel.updateTask(updatedTask)
    }
}

// 网格日期单元格 - 放大版
struct GridDateCell: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let tasks: [Task]
    let hasTask: Bool
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // 背景
            Rectangle()
                .fill(cellBackground)
            
            VStack(spacing: 2) {
                // 日期头部 - 居中显示
                HStack {
                    Spacer()
                    ZStack {
                        // 选中圆圈，调整位置
                        if isSelected {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 32, height: 32)
                        }
                        
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isSelected ? .white : textColor)
                    }
                    Spacer()
                }
                .padding(.top, 4)
                
                // 任务列表
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(tasks.prefix(3).indices, id: \.self) { index in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(viewModel.priorityColor(tasks[index].priority))
                                .frame(width: 6, height: 6)
                            
                            if hasTask {
                                Text(tasks[index].title)
                                    .font(.system(size: 10))
                                    .lineLimit(1)
                                    .foregroundColor(isCurrentMonth ? .primary : .gray.opacity(0.8))
                            }
                        }
                    }
                    
                    if tasks.count > 3 {
                        Text("+ \(tasks.count - 3) 更多")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                
                Spacer()
            }
            .padding(.bottom, 4)
        }
        .frame(minWidth: hasTask ? 50 : 40, idealWidth: hasTask ? 60 : 40, maxHeight: 80)
        .cornerRadius(0)
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .gray
        } else if Calendar.current.isDateInToday(date) {
            return .blue
        } else {
            return .primary
        }
    }
    
    private var cellBackground: Color {
        if isSelected {
            return Color.blue.opacity(0.1)
        } else if !isCurrentMonth {
            return Color.gray.opacity(0.05)
        } else {
            return Color(.systemBackground)
        }
    }
} 