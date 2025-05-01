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
        case month, day
    }
    
    init(mainViewModel: MainViewModel = MainViewModel.shared) {
        _viewModel = StateObject(wrappedValue: CalendarViewModel(mainViewModel: mainViewModel))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标题和切换视图按钮
                HStack {
                    Text(calendarMode == .month ? "月历" : "日程")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.leading)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            calendarMode = calendarMode == .month ? .day : .month
                        }
                    }) {
                        Image(systemName: calendarMode == .month ? "list.bullet" : "calendar")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing)
                }
                .padding(.vertical, 8)
                
                // 根据模式显示不同的日历视图
                Group {
                    if calendarMode == .month {
                        MonthCalendarView()
                    } else {
                        DayCalendarView()
                    }
                }
                
                // 新建任务和编辑任务的表单
                .sheet(isPresented: $showingTaskCreateView) {
                    TaskQuickCreateView(
                        viewModel: viewModel.mainViewModel,
                        isPresented: $showingTaskCreateView
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
            }
            .navigationBarHidden(true)
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
                        DateCell(date: date, isSelected: viewModel.isSameDay(date1: date, date2: selectedDate))
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
                            Spacer()
                            
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            Text("这一天还没有任务")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                showingTaskCreateView = true
                            }) {
                                Text("添加任务")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: 250)
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }
    
    // 日视图
    private func DayCalendarView() -> some View {
        VStack(spacing: 0) {
            // 日期导航
            HStack {
                Button(action: {
                    withAnimation {
                        if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                            selectedDate = newDate
                            viewModel.selectedDate = newDate
                        }
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .padding(8)
                }
                
                Spacer()
                
                Text(viewModel.dateFormatter.string(from: selectedDate))
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                            selectedDate = newDate
                            viewModel.selectedDate = newDate
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
            
            Divider()
            
            // 任务时间线
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: {
                        showingTaskCreateView = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("添加任务")
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    
                    if let tasks = viewModel.tasksForSelectedDate(), !tasks.isEmpty {
                        ForEach(tasks) { task in
                            TaskRowView(task: task)
                                .padding(.horizontal)
                                .padding(.vertical, 4)
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
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            Text("今日暂无任务")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // 日期单元格
    private func DateCell(date: Date, isSelected: Bool) -> some View {
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
                                .fill(Color(hex: category.color))
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
        viewModel.mainViewModel.updateTask(updatedTask)
    }
    
    // 格式化时间
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // 根据优先级获取颜色
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .green
        }
    }
    
    // 添加分类视图
    private func AddCategoryView() -> some View {
        NavigationView {
            Form {
                Section(header: Text("分类信息")) {
                    TextField("分类名称", text: $categoryName)
                    
                    ColorPicker("选择颜色", selection: Binding(
                        get: { Color(hex: selectedColor) },
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
            viewModel.mainViewModel.createCategory(newCategory)
            showingAddCategoryView = false
        }
    }
} 