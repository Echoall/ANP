import Foundation
import Combine
import SwiftUI

// 排序选项
enum SortOption: String, CaseIterable, Identifiable {
    case dueDate = "到期时间"
    case priority = "优先级"
    case title = "标题"
    case created = "创建时间"
    
    var id: String { rawValue }
}

class MainViewModel: ObservableObject {
    // 添加共享实例
    static let shared = MainViewModel()
    
    @Published var categories: [Category] = []
    @Published var tasks: [UUID: [Task]] = [:] // categoryId: [Task]
    @Published var searchText: String = ""
    @Published var selectedSortOption: SortOption = .dueDate
    @Published var isSearching: Bool = false
    
    private let storageService: StorageServiceProtocol
    private let storageStatusService = StorageStatusService.shared
    private var cancellables = Set<AnyCancellable>()
    private var searchDebounceTimer: Timer?
    
    // MARK: - 初始化
    
    init(storageService: StorageServiceProtocol = LocalStorageService.shared) {
        self.storageService = storageService
        
        // 从本地加载数据
        loadDataFromLocal()
        
        // 加载分类和任务
        loadCategories()
        
        // 设置搜索防抖
        setupSearchDebounce()
    }
    
    // 设置搜索防抖
    private func setupSearchDebounce() {
        $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.isSearching = false
            }
            .store(in: &cancellables)
    }
    
    // 从本地加载数据
    private func loadDataFromLocal() {
        // 加载分类
        let localCategories = storageService.loadCategories()
        if !localCategories.isEmpty {
            self.categories = localCategories
        } else {
            // 创建默认分类
            let defaultCategory = Category(name: "待办", color: "#007AFF", order: 0)
            self.categories = [defaultCategory]
            // 保存默认分类到本地
            storageService.saveCategories(self.categories)
            print("已创建默认分类'待办'")
        }
        
        // 加载任务
        let localTasks = storageService.loadTasks()
        if !localTasks.isEmpty {
            self.tasks = localTasks
        }
    }
    
    // 保存数据到本地
    private func saveDataToLocal() {
        storageService.saveCategories(categories)
        storageService.saveTasks(tasks)
    }
    
    func loadCategories() {
        storageStatusService.didStartSaving()
        
        storageService.fetchCategories()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("加载分类失败: \(error)")
                    self?.storageStatusService.didFailSaving()
                }
            } receiveValue: { [weak self] categories in
                guard let self = self else { return }
                
                self.categories = categories.sorted(by: { $0.order < $1.order })
                self.storageStatusService.didCompleteSaving()
                
                // 加载所有分类的任务
                self.loadTasksForAllCategories()
            }
            .store(in: &cancellables)
    }
    
    private func loadTasksForAllCategories() {
        categories.forEach { category in
            loadTasks(for: category.id)
        }
    }
    
    func loadTasks(for categoryId: UUID) {
        storageStatusService.didStartSaving()
        
        storageService.fetchTasks(categoryId: categoryId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("加载任务失败: \(error)")
                    self?.storageStatusService.didFailSaving()
                }
            } receiveValue: { [weak self] tasks in
                guard let self = self else { return }
                
                self.tasks[categoryId] = tasks
                self.storageStatusService.didCompleteSaving()
            }
            .store(in: &cancellables)
    }
    
    func createCategory(_ category: Category) {
        storageStatusService.didStartSaving()
        
        storageService.createCategory(category)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("创建分类失败: \(error)")
                    self?.storageStatusService.didFailSaving()
                }
            } receiveValue: { [weak self] category in
                guard let self = self else { return }
                
                self.categories.append(category)
                self.storageStatusService.didCompleteSaving()
            }
            .store(in: &cancellables)
    }
    
    func updateCategory(_ category: Category) {
        storageStatusService.didStartSaving()
        
        storageService.updateCategory(category)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("更新分类失败: \(error)")
                    self?.storageStatusService.didFailSaving()
                }
            } receiveValue: { [weak self] updatedCategory in
                guard let self = self else { return }
                
                if let index = self.categories.firstIndex(where: { $0.id == updatedCategory.id }) {
                    self.categories[index] = updatedCategory
                    self.storageStatusService.didCompleteSaving()
                }
            }
            .store(in: &cancellables)
    }
    
    func deleteCategory(_ categoryId: UUID) {
        storageStatusService.didStartSaving()
        
        storageService.deleteCategory(categoryId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("删除分类失败: \(error)")
                    self?.storageStatusService.didFailSaving()
                }
            } receiveValue: { [weak self] success in
                guard let self = self, success else { return }
                
                self.categories.removeAll { $0.id == categoryId }
                self.tasks[categoryId] = nil
                self.storageStatusService.didCompleteSaving()
            }
            .store(in: &cancellables)
    }
    
    func createTask(_ task: Task) {
        // 立即在本地添加任务
        tasks[task.categoryId, default: []].append(task)
        
        // 保存到本地
        saveDataToLocal()
        
        // 设置提醒
        if let reminderDate = task.reminderDate {
            NotificationService.shared.scheduleTaskReminder(for: task)
        }
        
        // 通知UI刷新
        objectWillChange.send()
        
        // 异步保存到存储服务
        storageStatusService.didStartSaving()
        
        storageService.createTask(task)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("创建任务失败: \(error)")
                    self?.storageStatusService.didFailSaving()
                }
            } receiveValue: { [weak self] _ in
                self?.storageStatusService.didCompleteSaving()
            }
            .store(in: &cancellables)
    }
    
    // 添加一个更便捷的任务添加方法，处理边缘情况
    func addTask(title: String, description: String = "", dueDate: Date, priority: TaskPriority, categoryId: UUID) {
        print("添加任务: \(title), 分类ID: \(categoryId)")
        
        // 验证分类是否存在
        let categoryExists = categories.contains { $0.id == categoryId }
        
        // 如果分类不存在，尝试使用第一个分类
        var finalCategoryId = categoryId
        if !categoryExists {
            print("警告: 尝试添加任务到不存在的分类 \(categoryId)")
            if let firstCategory = categories.first {
                print("使用第一个可用分类: \(firstCategory.name)")
                finalCategoryId = firstCategory.id
            } else {
                print("错误: 无法添加任务，没有可用分类")
                return // 无法添加任务
            }
        }
        
        // 创建新任务
        let newTask = Task(
            categoryId: finalCategoryId,
            title: title,
            description: description,
            dueDate: dueDate,
            priority: priority,
            isCompleted: false
        )
        
        // 调用任务创建方法
        createTask(newTask)
        
        // 通知UI刷新
        objectWillChange.send()
    }
    
    func updateTask(_ task: Task) {
        // 立即在本地更新任务
        if let index = tasks[task.categoryId]?.firstIndex(where: { $0.id == task.id }) {
            tasks[task.categoryId]?[index] = task
            
            // 保存到本地
            saveDataToLocal()
            
            // 更新提醒
            NotificationService.shared.cancelTaskReminder(for: task.id)
            if let reminderDate = task.reminderDate {
                NotificationService.shared.scheduleTaskReminder(for: task)
            }
        }
        
        // 使用存储服务更新
        storageStatusService.didStartSaving()
        
        storageService.updateTask(task)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("更新任务失败: \(error)")
                    self?.storageStatusService.didFailSaving()
                }
            } receiveValue: { [weak self] _ in
                self?.storageStatusService.didCompleteSaving()
            }
            .store(in: &cancellables)
    }
    
    func deleteTask(_ task: Task) {
        // 立即在本地删除任务
        tasks[task.categoryId]?.removeAll { $0.id == task.id }
        
        // 保存到本地
        saveDataToLocal()
        
        // 取消提醒
        NotificationService.shared.cancelTaskReminder(for: task.id)
        
        // 使用存储服务删除
        storageStatusService.didStartSaving()
        
        storageService.deleteTask(task.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("删除任务失败: \(error)")
                    self?.storageStatusService.didFailSaving()
                }
            } receiveValue: { [weak self] _ in
                self?.storageStatusService.didCompleteSaving()
            }
            .store(in: &cancellables)
    }
    
    // 搜索和排序功能
    func filteredTasks(for categoryId: UUID) -> [Task] {
        let categoryTasks = tasks[categoryId] ?? []
        
        // 如果搜索文本为空，直接返回所有任务
        if searchText.isEmpty {
            return categoryTasks
        }
        
        // 标记正在搜索
        isSearching = true
        
        // 执行搜索
        return categoryTasks.filter { task in
            task.title.localizedCaseInsensitiveContains(searchText) ||
            task.description.localizedCaseInsensitiveContains(searchText) ||
            (task.subtasks.contains(where: { $0.title.localizedCaseInsensitiveContains(searchText) }))
        }
    }
    
    private func sortTasks(_ tasks: [Task]) -> [Task] {
        switch selectedSortOption {
        case .dueDate:
            return tasks.sorted { $0.dueDate < $1.dueDate }
        case .priority:
            return tasks.sorted { $0.priority.rawValue > $1.priority.rawValue }
        case .title:
            return tasks.sorted { $0.title < $1.title }
        case .created:
            return tasks.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    func addTask(_ task: Task) {
        print("添加任务对象: \(task.title), 分类ID: \(task.categoryId)")
        
        // 确保分类存在
        if !categories.contains(where: { $0.id == task.categoryId }) {
            print("警告: 尝试添加到不存在的分类，将使用第一个可用分类")
            if let firstCategory = categories.first {
                var modifiedTask = task
                modifiedTask = Task(
                    id: task.id,
                    categoryId: firstCategory.id,
                    title: task.title,
                    description: task.description,
                    dueDate: task.dueDate,
                    priority: task.priority,
                    isCompleted: task.isCompleted,
                    reminderDate: task.reminderDate,
                    createdAt: task.createdAt,
                    updatedAt: task.updatedAt,
                    subtasks: task.subtasks
                )
                createTask(modifiedTask)
                return
            } else {
                print("错误: 无可用分类，无法添加任务")
                return
            }
        }
        
        // 正常添加任务
        createTask(task)
        
        // 触发视图刷新
        objectWillChange.send()
    }
    
    // 重命名这个方法避免与现有方法冲突
    func createNewTask(title: String, description: String = "", dueDate: Date, priority: TaskPriority, categoryId: UUID) {
        print("通过参数创建任务: \(title), 分类ID: \(categoryId)")
        
        // 验证分类是否存在
        let categoryExists = categories.contains { $0.id == categoryId }
        
        // 如果分类不存在，尝试使用第一个分类
        var finalCategoryId = categoryId
        if !categoryExists {
            print("警告: 尝试添加任务到不存在的分类 \(categoryId)")
            if let firstCategory = categories.first {
                print("使用第一个可用分类: \(firstCategory.name)")
                finalCategoryId = firstCategory.id
            } else {
                print("错误: 无法添加任务，没有可用分类")
                return // 无法添加任务
            }
        }
        
        // 创建新任务
        let newTask = Task(
            categoryId: finalCategoryId,
            title: title,
            description: description,
            dueDate: dueDate,
            priority: priority,
            isCompleted: false
        )
        
        // 调用任务创建方法
        createTask(newTask)
        
        // 通知UI刷新
        objectWillChange.send()
    }
} 