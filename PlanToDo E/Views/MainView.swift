import SwiftUI

// 辅助获取安全区域的扩展
#if os(iOS)
extension UIApplication {
    static var safeAreaTop: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.top
        }
        return 0
    }
}
#else
// macOS平台下的替代实现
struct UIApplication {
    static var safeAreaTop: CGFloat {
        return 0
    }
}
#endif

// 定义特殊分类的ID
enum SpecialCategory: String, Identifiable, CaseIterable {
    case allTasks = "all_tasks"  // 待办任务
    case upcoming = "upcoming"   // 即将到来
    case completed = "completed" // 已完成
    
    var id: String {
        return self.rawValue
    }
    
    var name: String {
        switch self {
        case .allTasks: return "待办任务"
        case .upcoming: return "即将到来"
        case .completed: return "已完成"
        }
    }
    
    var icon: String {
        switch self {
        case .allTasks: return "list.bullet"
        case .upcoming: return "clock"
        case .completed: return "checkmark.circle"
        }
    }
    
    var color: String {
        switch self {
        case .allTasks: return "#007AFF" // 蓝色
        case .upcoming: return "#FF9500" // 橙色
        case .completed: return "#34C759" // 绿色
        }
    }
}

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var showingAddTask = false
    @State private var showingSortOptions = false
    @State private var selectedTask: Task? = nil
    @State private var selectedTaskForEditing: Task? = nil
    @State private var showingTaskEditSheet = false
    @State private var selectedCategoryId: UUID? = nil
    @State private var selectedSpecialCategory: SpecialCategory? = .allTasks
    @State private var showingCategoryEdit = false
    @State private var editingTask: Task? = nil
    @State private var editingCategory: Category? = nil
    @State private var showingCategoryManager = false
    @State private var showingSideMenu = false
    @State private var showCompletedTasks = false
    @State private var showSearchBar = false
    @State private var showCalendarView = false
    @State private var showAIChat = false
    
    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack(spacing: 0) {
                    // 顶部控制区
                    HStack {
                        // 菜单按钮
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                showingSideMenu = true
                            }
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                        .padding(.trailing, 8)
                        
                        // 当前分类名称
                        Text(currentCategoryName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // 搜索按钮
                        Button(action: {
                            withAnimation(.spring()) {
                                showSearchBar.toggle()
                            }
                        }) {
                            Image(systemName: showSearchBar ? "xmark.circle.fill" : "magnifyingglass")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                        .padding(.trailing, 8)
                        
                        // 排序选项
                        Button(action: {
                            showingSortOptions = true
                        }) {
                            HStack(spacing: 4) {
                                Text("排序")
                                    .foregroundColor(.primary)
                                
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    #if os(iOS)
                                    .fill(Color(.systemGray6))
                                    #else
                                    .fill(Color.gray.opacity(0.2))
                                    #endif
                            )
                        }
                        .popover(isPresented: $showingSortOptions) {
                            SortOptionsPicker(selectedOption: $viewModel.selectedSortOption)
                                .padding()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                    
                    // 搜索栏 (可隐藏)
                    if showSearchBar {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("搜索任务...", text: $viewModel.searchText)
                                .font(.body)
                            
                            if !viewModel.searchText.isEmpty {
                                Button(action: {
                                    viewModel.searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(10)
                        #if os(iOS)
                        .background(Color(.secondarySystemBackground))
                        #else
                        .background(Color.gray.opacity(0.1))
                        #endif
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // 分隔线
                    Divider()
                    
                    // 任务列表区
                    if filteredActiveTasks.isEmpty && filteredCompletedTasks.isEmpty {
                        // 空状态视图
                        EmptyStateView(
                            title: viewModel.searchText.isEmpty ? "没有任务" : "没有匹配的任务",
                            message: viewModel.searchText.isEmpty ? 
                                     (isSpecialCategorySelected ? "没有符合条件的任务" : "添加一个新任务开始您的计划") : 
                                     "尝试使用其他搜索词",
                            systemImageName: viewModel.searchText.isEmpty ? "checklist" : "magnifyingglass",
                            buttonTitle: viewModel.searchText.isEmpty && selectedCategoryId != nil && !isSpecialCategorySelected ? "添加任务" : nil,
                            buttonAction: viewModel.searchText.isEmpty && selectedCategoryId != nil && !isSpecialCategorySelected ? {
                                showingAddTask = true
                            } : nil
                        )
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            // 搜索状态指示器
                            if viewModel.isSearching {
                                LoadingIndicatorView(title: "正在搜索...")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                            }
                            
                            LazyVStack(spacing: 0) {
                                // 进行中任务区域
                                if !filteredActiveTasks.isEmpty {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("进行中")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .padding(.horizontal)
                                            .padding(.top, 10)
                                            .padding(.bottom, 5)
                                        
                                        ForEach(filteredActiveTasks.sorted(by: sortTasks)) { task in
                                            TaskItemView(
                                                task: task,
                                                onToggleComplete: { isCompleted in
                                                    toggleTaskCompletion(task, isCompleted: isCompleted)
                                                },
                                                onSubTaskToggleComplete: { subtaskId, isCompleted in
                                                    toggleSubTaskCompletion(taskId: task.id, subtaskId: subtaskId, isCompleted: isCompleted)
                                                },
                                                onTaskTap: {
                                                    selectedTaskForEditing = task
                                                    showingTaskEditSheet = true
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                
                                // 已完成任务区域 (可折叠)
                                if !filteredCompletedTasks.isEmpty {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Button(action: {
                                            withAnimation(.spring()) {
                                                showCompletedTasks.toggle()
                                            }
                                        }) {
                                            HStack {
                                                Text("已完成")
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                
                                                Text("(\(filteredCompletedTasks.count))")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                
                                                Spacer()
                                                
                                                Image(systemName: showCompletedTasks ? "chevron.up" : "chevron.down")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.top, 15)
                                        .padding(.bottom, 5)
                                        
                                        if showCompletedTasks {
                                            ForEach(filteredCompletedTasks.sorted(by: { $0.updatedAt > $1.updatedAt })) { task in
                                                TaskItemView(
                                                    task: task,
                                                    onToggleComplete: { isCompleted in
                                                        toggleTaskCompletion(task, isCompleted: isCompleted)
                                                    },
                                                    onSubTaskToggleComplete: { subtaskId, isCompleted in
                                                        toggleSubTaskCompletion(taskId: task.id, subtaskId: subtaskId, isCompleted: isCompleted)
                                                    },
                                                    onTaskTap: {
                                                        selectedTaskForEditing = task
                                                        showingTaskEditSheet = true
                                                    }
                                                )
                                            }
                                            .transition(.opacity.combined(with: .move(edge: .top)))
                                        }
                                    }
                                    .padding(.horizontal)
                                    .animation(.spring(), value: showCompletedTasks)
                                }
                            }
                            .padding(.bottom, 80) // 为底部添加按钮腾出空间
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                .overlay(
                    Group {} // 移除原有的悬浮添加按钮，改用全局添加按钮
                )
                .navigationBarHidden(true) // 隐藏导航栏
                .sheet(isPresented: $showingAddTask) {
                    EnhancedTaskCreateView(
                        viewModel: viewModel, 
                        isPresented: $showingAddTask,
                        initialCategoryId: (!isSpecialCategorySelected && selectedCategoryId != nil) ? selectedCategoryId : nil
                    )
                }
                .sheet(isPresented: $showingTaskEditSheet) {
                    if let task = selectedTaskForEditing {
                        TaskEditView(viewModel: viewModel, task: task)
                    }
                }
                .sheet(isPresented: $showingCategoryEdit) {
                    CategoryEditView(viewModel: viewModel, category: editingCategory)
                }
                .sheet(isPresented: $showingCategoryManager) {
                    CategoryManagerView(viewModel: viewModel, selectedCategoryId: $selectedCategoryId)
                }
                .onAppear {
                    // 默认选择"待办任务"分类
                    selectedSpecialCategory = .allTasks
                    selectedCategoryId = nil
                }
                // 添加右滑手势显示菜单
                .gesture(
                    DragGesture()
                        .onEnded { gesture in
                            if gesture.translation.width > 50 && gesture.startLocation.x < 50 {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    showingSideMenu = true
                                }
                            }
                        }
                )
            }
            
            // 侧边菜单
            SideMenuView(
                isShowing: $showingSideMenu,
                selectedCategoryId: $selectedCategoryId,
                selectedSpecialCategory: $selectedSpecialCategory,
                categories: viewModel.categories,
                onAddCategory: {
                    editingCategory = nil
                    showingCategoryEdit = true
                },
                onManageCategories: {
                    showingCategoryManager = true
                },
                onCalendarTap: handleCalendarTap,
                viewModel: viewModel
            )
            .zIndex(1) // 确保菜单在最上层

            // 日历视图
            .sheet(isPresented: $showCalendarView) {
                CalendarView(mainViewModel: viewModel)
            }
            
            // Coral聊天页面视图
            .sheet(isPresented: $showAIChat) {
                NavigationView {
                    ChatView()
                }
            }
            
            // 全局悬浮按钮部分
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    FloatingAddButton {
                        showingAddTask = true
                    }
                    Spacer()
                }
            }
        }
    }
    
    // 是否选择了特殊分类
    private var isSpecialCategorySelected: Bool {
        return selectedSpecialCategory != nil
    }
    
    // 获取当前分类名称
    private var currentCategoryName: String {
        if let specialCategory = selectedSpecialCategory {
            return specialCategory.name
        } else if let categoryId = selectedCategoryId,
                  let category = viewModel.categories.first(where: { $0.id == categoryId }) {
            return category.name
        }
        return "任务"
    }
    
    // 未完成的任务
    private var filteredActiveTasks: [Task] {
        filteredTasks.filter { !$0.isCompleted }
    }
    
    // 已完成的任务
    private var filteredCompletedTasks: [Task] {
        // 对于"待办任务"和"即将到来"分类，不显示已完成任务
        if selectedSpecialCategory == .allTasks || selectedSpecialCategory == .upcoming {
            return []
        }
        return filteredTasks.filter { $0.isCompleted }
    }
    
    // 根据选中的分类过滤任务
    private var filteredTasks: [Task] {
        // 如果选择了特殊分类
        if let specialCategory = selectedSpecialCategory {
            let allTasks = viewModel.categories.flatMap { categoryId in
                viewModel.tasks[categoryId.id] ?? []
            }
            
            switch specialCategory {
            case .allTasks:
                // 所有未完成的任务
                let filtered = allTasks.filter { !$0.isCompleted }
                return applySearchFilter(to: filtered)
                
            case .upcoming:
                // 24小时内到期的未完成任务
                let nextDay = Date().addingTimeInterval(24 * 60 * 60)
                let filtered = allTasks.filter { 
                    !$0.isCompleted && 
                    $0.dueDate <= nextDay && 
                    $0.dueDate >= Date()
                }
                return applySearchFilter(to: filtered)
                
            case .completed:
                // 所有已完成的任务
                let filtered = allTasks.filter { $0.isCompleted }
                return applySearchFilter(to: filtered)
            }
        }
        
        // 常规分类
        guard let categoryId = selectedCategoryId else { return [] }
        
        let categoryTasks = viewModel.tasks[categoryId] ?? []
        return applySearchFilter(to: categoryTasks)
    }
    
    // 应用搜索过滤
    private func applySearchFilter(to tasks: [Task]) -> [Task] {
        if viewModel.searchText.isEmpty {
            return tasks
        } else {
            return tasks.filter { task in
                task.title.localizedCaseInsensitiveContains(viewModel.searchText) ||
                task.description.localizedCaseInsensitiveContains(viewModel.searchText)
            }
        }
    }
    
    // 排序任务
    private func sortTasks(lhs: Task, rhs: Task) -> Bool {
        switch viewModel.selectedSortOption {
        case .dueDate:
            return lhs.dueDate < rhs.dueDate
        case .priority:
            let priorityOrder: [TaskPriority: Int] = [.high: 0, .medium: 1, .low: 2]
            return priorityOrder[lhs.priority]! < priorityOrder[rhs.priority]!
        case .title:
            return lhs.title < rhs.title
        case .created:
            return lhs.createdAt < rhs.createdAt
        }
    }
    
    // 切换任务完成状态
    private func toggleTaskCompletion(_ task: Task, isCompleted: Bool) {
        var updatedTask = task
        updatedTask.isCompleted = isCompleted
        updatedTask.updatedAt = Date()
        
        viewModel.updateTask(updatedTask)
    }
    
    // 切换子任务完成状态
    private func toggleSubTaskCompletion(taskId: UUID, subtaskId: UUID, isCompleted: Bool) {
        // 找到任务所属的分类
        var foundTask: Task? = nil
        var foundCategoryId: UUID? = nil
        
        // 在所有分类中查找任务
        for category in viewModel.categories {
            if let tasks = viewModel.tasks[category.id],
               let task = tasks.first(where: { $0.id == taskId }) {
                foundTask = task
                foundCategoryId = category.id
                break
            }
        }
        
        // 如果找到了任务和分类
        if var task = foundTask, let categoryId = foundCategoryId,
           let taskIndex = viewModel.tasks[categoryId]?.firstIndex(where: { $0.id == taskId }) {
            
            // 查找并更新子任务
            if let subtaskIndex = task.subtasks.firstIndex(where: { $0.id == subtaskId }) {
                task.subtasks[subtaskIndex].isCompleted = isCompleted
                
                // 检查是否所有子任务都已完成
                let allSubtasksCompleted = task.subtasks.allSatisfy { $0.isCompleted }
                
                // 更新主任务完成状态
                if allSubtasksCompleted && !task.isCompleted {
                    task.isCompleted = true
                } else if !allSubtasksCompleted && task.isCompleted {
                    task.isCompleted = false
                }
                
                task.updatedAt = Date()
                viewModel.updateTask(task)
            }
        }
    }
    
    // 处理日历点击
    private func handleCalendarTap() {
        showCalendarView = true
    }
}

// 分类管理视图
struct CategoryManagerView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: MainViewModel
    @Binding var selectedCategoryId: UUID?
    @State private var showingCategoryEdit = false
    @State private var editingCategory: Category? = nil
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: Category? = nil
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.categories) { category in
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                        
                        Text(category.name)
                            .font(.body)
                        
                        Spacer()
                        
                        if selectedCategoryId == category.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // 选择分类
                        selectedCategoryId = category.id
                        presentationMode.wrappedValue.dismiss()
                    }
                    .contextMenu {
                        Button(action: {
                            editingCategory = category
                            showingCategoryEdit = true
                        }) {
                            Label("编辑", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: {
                            categoryToDelete = category
                            showingDeleteAlert = true
                        }) {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
                .onDelete { indexSet in
                    // 转换索引集为分类数组
                    let categoriesToDelete = indexSet.map { viewModel.categories[$0] }
                    
                    // 删除每个分类
                    for category in categoriesToDelete {
                        viewModel.deleteCategory(category.id)
                        
                        // 如果删除的是当前选中的分类，则重置选中状态
                        if selectedCategoryId == category.id {
                            selectedCategoryId = viewModel.categories.first?.id
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("管理分类")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        editingCategory = nil
                        showingCategoryEdit = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCategoryEdit) {
                CategoryEditView(viewModel: viewModel, category: editingCategory)
            }
            .alert("确认删除", isPresented: $showingDeleteAlert, presenting: categoryToDelete) { category in
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    viewModel.deleteCategory(category.id)
                    if selectedCategoryId == category.id {
                        selectedCategoryId = viewModel.categories.first?.id
                    }
                }
            } message: { category in
                Text("确定要删除分类「\(category.name)」吗？所有属于该分类的任务也将被删除。")
            }
        }
    }
} 