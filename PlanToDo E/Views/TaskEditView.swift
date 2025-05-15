import SwiftUI

struct TaskEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: MainViewModel
    @State private var taskTitle: String
    @State private var taskDescription: String
    @State private var dueDate: Date
    @State private var selectedPriority: TaskPriority
    @State private var selectedCategoryId: UUID
    @State private var isCompleted: Bool
    
    private var isNewTask: Bool
    private var originalTask: Task
    
    // 使用categoryId构造器创建新任务
    init(viewModel: MainViewModel, categoryId: UUID) {
        self.viewModel = viewModel
        
        // 创建临时任务对象
        let newTask = Task(
            categoryId: categoryId,
            title: "",
            description: "",
            dueDate: Date().addingTimeInterval(3600), // 1小时后
            priority: .medium,
            isCompleted: false
        )
        
        self._taskTitle = State(initialValue: newTask.title)
        self._taskDescription = State(initialValue: newTask.description)
        self._dueDate = State(initialValue: newTask.dueDate)
        self._selectedPriority = State(initialValue: newTask.priority)
        self._selectedCategoryId = State(initialValue: newTask.categoryId)
        self._isCompleted = State(initialValue: newTask.isCompleted)
        
        self.isNewTask = true
        self.originalTask = newTask
    }
    
    // 使用现有任务进行编辑
    init(viewModel: MainViewModel, task: Task) {
        self.viewModel = viewModel
        self.originalTask = task
        
        self._taskTitle = State(initialValue: task.title)
        self._taskDescription = State(initialValue: task.description)
        self._dueDate = State(initialValue: task.dueDate)
        self._selectedPriority = State(initialValue: task.priority)
        self._selectedCategoryId = State(initialValue: task.categoryId)
        self._isCompleted = State(initialValue: task.isCompleted)
        
        self.isNewTask = false
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("任务标题", text: $taskTitle)
                    
                    TextField("任务描述", text: $taskDescription)
                        .frame(height: 80)
                }
                
                Section(header: Text("日期和时间")) {
                    DatePicker("截止日期", selection: $dueDate)
                }
                
                Section(header: Text("优先级")) {
                    Picker("优先级", selection: $selectedPriority) {
                        ForEach(TaskPriority.allCases) { priority in
                            HStack {
                                Circle()
                                    .fill(priorityColor(priority))
                                    .frame(width: 12, height: 12)
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("分类")) {
                    Picker("分类", selection: $selectedCategoryId) {
                        ForEach(viewModel.categories) { category in
                            Text(category.name).tag(category.id)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                if !isNewTask {
                    Section {
                        Toggle("已完成", isOn: $isCompleted)
                    }
                }
            }
            .navigationTitle(isNewTask ? "添加任务" : "编辑任务")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveTask()
                }
            )
        }
    }
    
    private func saveTask() {
        print("保存任务: \(taskTitle), 是新任务: \(isNewTask)")
        
        // 创建更新后的任务
        let updatedTask = Task(
            id: originalTask.id,
            categoryId: selectedCategoryId,
            title: taskTitle,
            description: taskDescription,
            dueDate: dueDate,
            priority: selectedPriority,
            isCompleted: isCompleted
        )
        
        if isNewTask {
            print("添加新任务到分类: \(selectedCategoryId)")
            viewModel.createTask(updatedTask)
        } else {
            print("更新现有任务: \(updatedTask.id)")
            viewModel.updateTask(updatedTask)
        }
        
        // 关闭编辑视图
        presentationMode.wrappedValue.dismiss()
    }
    
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
}