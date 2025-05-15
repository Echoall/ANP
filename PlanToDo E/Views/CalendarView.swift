import SwiftUI

struct CalendarView: View {
    @StateObject var viewModel: CalendarViewModel
    
    // 状态变量
    @State private var showingTaskCreateView = false
    @State private var showingTaskEditSheet = false
    @State private var selectedTask: Task? = nil
    @State private var selectedDate = Date()
    @State private var calendarMode: CalendarMode = .month
    @State private var showingAddCategoryView = false
    @State private var categoryName: String = ""
    @State private var selectedColor: String = "#FF5733"
    
    // 日历模式枚举
    enum CalendarMode {
        case month, grid
    }
    
    init(mainViewModel: MainViewModel = MainViewModel.shared) {
        _viewModel = StateObject(wrappedValue: CalendarViewModel(mainViewModel: mainViewModel))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // 标题和切换视图按钮
                    HStack {
                        Text(calendarTitle)
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.leading)
                        
                        Spacer()
                        
                        if calendarMode == .grid {
                            Button(action: {
                                withAnimation {
                                    calendarMode = .month
                                }
                            }) {
                                Image(systemName: calendarIcon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                            }
                            .padding(.trailing)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // 根据模式显示不同的日历视图
                    Group {
                        if calendarMode == .month {
                            MonthCalendarView()
                        } else {
                            GridCalendarView(
                                viewModel: viewModel,
                                selectedDate: $selectedDate,
                                showingTaskCreateView: $showingTaskCreateView,
                                showingTaskEditSheet: $showingTaskEditSheet,
                                selectedTask: $selectedTask
                            )
                        }
                    }
                }
                .navigationBarHidden(true)
                
                // 新的任务创建和编辑表单
                .sheet(isPresented: $showingTaskCreateView) {
                    EnhancedTaskCreateView(
                        viewModel: viewModel.mainViewModel,
                        isPresented: $showingTaskCreateView,
                        initialDate: selectedDate
                    )
                }
                .sheet(isPresented: $showingTaskEditSheet) {
                    if let task = selectedTask {
                        TaskEditView(
                            viewModel: viewModel.mainViewModel,
                            task: task
                        )
                    }
                }
                .sheet(isPresented: $showingAddCategoryView) {
                    AddCategoryView()
                }
                
                // 添加全局悬浮按钮
                VStack {
                    Spacer()
                    HStack {
                        FloatingAddButton {
                            showingTaskCreateView = true
                        }
                        Spacer()
                    }
                }
            }
        }
    }
    
    // 计算当前模式的标题
    private var calendarTitle: String {
        switch calendarMode {
        case .month:
            return "月历"
        case .grid:
            return "日程"
        }
    }
    
    // 计算当前模式的图标
    private var calendarIcon: String {
        switch calendarMode {
        case .month:
            return "calendar"
        case .grid:
            return "calendar"
        }
    }
    
    // 月历视图
    private func MonthCalendarView() -> some View {
        VStack(spacing: 0) {
            // 月份导航
            HStack {
                Button(action: {
                    withAnimation {
                        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
                            selectedDate = newDate
                        }
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .padding(8)
                }
                
                Spacer()
                
                Text(viewModel.monthYearFormatter.string(from: selectedDate))
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
                            selectedDate = newDate
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
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(day == "日" || day == "六" ? .red : .primary)
                }
            }
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            // 日历网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(viewModel.daysInMonth(), id: \.self) { date in
                    if let date = date {
                        MonthDateCell(date: date, isSelected: viewModel.isSameDay(date1: date, date2: selectedDate))
                            .onTapGesture {
                                withAnimation {
                                    viewModel.selectedDate = date
                                    selectedDate = date
                                }
                            }
                    } else {
                        // 空白单元格
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(height: 40)
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // 选中日期的任务列表
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(viewModel.dateFormatter.string(from: selectedDate))
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                calendarMode = .grid
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.grid.2x2")
                                    .font(.system(size: 14))
                                Text("网格视图")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        }
                        
                        Button(action: {
                            showingTaskCreateView = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    
                    if let tasks = viewModel.tasksForSelectedDate(), !tasks.isEmpty {
                        ForEach(tasks) { task in
                            TaskRowView(task: task)
                                .padding(.horizontal)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTask = task
                                    showingTaskEditSheet = true
                                }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Spacer().frame(height: 20)
                            
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.7))
                            
                            Text("这一天没有任务")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("利用这段空闲时间来放松一下吧")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Spacer().frame(height: 20)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    // 日期单元格
    private func MonthDateCell(date: Date, isSelected: Bool) -> some View {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        let day = calendar.component(.day, from: date)
        let isCurrentMonth = calendar.isDate(date, equalTo: selectedDate, toGranularity: .month)
        
        return ZStack {
            Circle()
                .fill(isSelected ? Color.blue.opacity(0.2) : Color.clear)
                .frame(width: 35, height: 35)
            
            VStack {
                Text("\(day)")
                    .font(.system(size: 16))
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(isCurrentMonth ? (isToday ? .blue : .primary) : .gray)
                
                // 如果日期有任务，显示指示点
                if let tasks = viewModel.tasksByDate.first(where: { calendar.isDate($0.key, inSameDayAs: date) })?.value, !tasks.isEmpty && isCurrentMonth {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 5, height: 5)
                }
            }
        }
        .frame(height: 40)
    }
    
    // 任务行视图
    private func TaskRowView(task: Task) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // 优先级颜色指示
            Circle()
                .fill(priorityColor(task.priority))
                .frame(width: 14, height: 14)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                    .lineLimit(1)
                
                if task.description != "" {
                    Text(task.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    // 时间显示
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        
                        Text(formattedTime(task.dueDate))
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                    
                    // 分类名称
                    if let category = getCategoryForTask(task) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            
                            Text(category.name)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 2)
            }
            
            Spacer()
            
            // 完成状态
            Button(action: {
                toggleTaskCompletion(task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
    }
    
    // 获取任务的分类
    private func getCategoryForTask(_ task: Task) -> Category? {
        return viewModel.mainViewModel.categories.first { $0.id == task.categoryId }
    }
    
    // 切换任务完成状态
    private func toggleTaskCompletion(_ task: Task) {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        viewModel.updateTask(updatedTask)
    }
    
    // 格式化时间
    private func formattedTime(_ date: Date) -> String {
        return viewModel.formattedTime(date)
    }
    
    // 根据优先级获取颜色
    private func priorityColor(_ priority: TaskPriority) -> Color {
        return viewModel.priorityColor(priority)
    }
    
    // 添加分类视图
    private func AddCategoryView() -> some View {
        NavigationView {
            Form {
                Section(header: Text("分类信息")) {
                    TextField("分类名称", text: $categoryName)
                    
                    ColorPicker("选择颜色", selection: Binding(
                        get: { Color.blue },
                        set: { _ in selectedColor = "#FF5733" }
                    ))
                }
                
                Section {
                    Button(action: {
                        addCategory()
                    }) {
                        Text("保存分类")
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("添加新分类")
            .navigationBarItems(
                trailing: Button("取消") {
                    showingAddCategoryView = false
                }
            )
        }
    }
    
    // 添加新分类
    private func addCategory() {
        if !categoryName.isEmpty {
            let newCategory = Category(id: UUID(), name: categoryName, color: selectedColor)
            viewModel.addCategory(newCategory)
            showingAddCategoryView = false
        }
    }
}

// 日期单元格视图
struct DateCell: View {
    var date: Date
    var isSelected: Bool
    
    @Environment(\.calendar) var calendar
    @EnvironmentObject var viewModel: CalendarViewModel
    
    var body: some View {
        VStack(spacing: 4) {
            // 日期文本
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : isWeekend() ? .red : .primary)
                .frame(width: 25, height: 25)
                .background(isSelected ? Color.blue : Color.clear)
                .clipShape(Circle())
            
            // 任务指示器
            HStack(spacing: 4) {
                ForEach(taskIndicators(), id: \.self) { priority in
                    Circle()
                        .fill(priorityColor(priority))
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 6)
            .padding(.bottom, 4)
        }
        .frame(height: 40)
        .contentShape(Rectangle())
    }
    
    // 检查是否为周末
    private func isWeekend() -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7 // 1是周日,7是周六
    }
    
    // 获取任务指示器列表
    private func taskIndicators() -> [TaskPriority] {
        guard let tasks = viewModel.tasksForDate(date), !tasks.isEmpty else { return [] }
        
        var indicators: [TaskPriority] = []
        var priorities: Set<TaskPriority> = []
        
        for task in tasks {
            if !priorities.contains(task.priority) {
                priorities.insert(task.priority)
                indicators.append(task.priority)
                
                // 最多显示3个指示器
                if indicators.count >= 3 {
                    break
                }
            }
        }
        
        return indicators
    }
    
    // 获取优先级颜色
    private func priorityColor(_ priority: TaskPriority) -> Color {
        return viewModel.priorityColor(priority)
    }
}

// 自定义添加分类视图
struct AddCategoryView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var categoryName: String = ""
    @State private var selectedColor: String = "#FF5733"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("分类信息")) {
                    TextField("分类名称", text: $categoryName)
                    
                    // 色彩选择器 (简化版)
                    HStack {
                        Text("颜色")
                        Spacer()
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .navigationTitle("添加分类")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    if !categoryName.isEmpty {
                        let newCategory = Category(
                            id: UUID(),
                            name: categoryName,
                            color: selectedColor,
                            order: viewModel.mainViewModel.categories.count + 1
                        )
                        viewModel.addCategory(newCategory)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .disabled(categoryName.isEmpty)
            )
        }
    }
} 