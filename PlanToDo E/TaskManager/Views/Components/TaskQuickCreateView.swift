import SwiftUI
import Combine

// 子任务模型
struct SubTaskItem: Identifiable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
}

struct TaskQuickCreateView: View {
    @ObservedObject var viewModel: MainViewModel
    @Binding var isPresented: Bool
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var selectedDate: Date = Date()
    @State private var startTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var endTime: Date = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var selectedCategoryId: UUID? = nil
    @State private var selectedPriority: TaskPriority = .medium
    @State private var showingDatePicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // 子任务管理
    @State private var subtasks: [SubTaskItem] = []
    @State private var newSubtaskTitle: String = ""
    
    // 键盘高度处理
    @State private var keyboardHeight: CGFloat = 0
    @State private var safeAreaInsets: EdgeInsets = EdgeInsets()
    
    // 格式化时间显示
    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let startTimeStr = formatter.string(from: startTime)
        let endTimeStr = formatter.string(from: endTime)
        
        // 判断是今天还是明天
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        
        let today = dayFormatter.string(from: Date())
        let selectedDay = dayFormatter.string(from: selectedDate)
        
        let dayText = today == selectedDay ? "今天" : "明天"
        
        return "\(dayText) \(startTimeStr)~\(endTimeStr)"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 顶部拖动条和关闭按钮
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 5)
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 24))
                    }
                    .padding(.trailing, 16)
                }
                .padding(.top, 12)
                
                // 标题输入框
                TextField("记些重要的事情吧", text: $title)
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                
                Divider()
                
                // 备注输入框
                ZStack(alignment: .topLeading) {
                    if notes.isEmpty {
                        Text("输入备注")
                            .foregroundColor(Color.gray.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color.clear)
                }
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                
                Divider()
                
                // 日期和时间小组件
                TaskOptionWidget(title: "日期和时间", iconName: "calendar") {
                    VStack(alignment: .leading, spacing: 12) {
                        // 日期选择器
                        DatePicker("日期", selection: $selectedDate, displayedComponents: [.date])
                            .datePickerStyle(CompactDatePickerStyle())
                        
                        // 时间范围选择器
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("开始时间")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("结束时间")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                // 优先级选择小组件
                TaskOptionWidget(title: "重要程度", iconName: "flag") {
                    Picker("优先级", selection: $selectedPriority) {
                        Text("低").tag(TaskPriority.low)
                        Text("中").tag(TaskPriority.medium)
                        Text("高").tag(TaskPriority.high)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal, 16)
                
                // 分类选择小组件
                TaskOptionWidget(title: "分类", iconName: "folder") {
                    Menu {
                        ForEach(viewModel.categories) { category in
                            Button(action: {
                                selectedCategoryId = category.id
                            }) {
                                HStack {
                                    Circle()
                                        .fill(Color(hex: category.color))
                                        .frame(width: 12, height: 12)
                                    Text(category.name)
                                    if selectedCategoryId == category.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            if let selectedId = selectedCategoryId,
                               let category = viewModel.categories.first(where: { $0.id == selectedId }) {
                                Circle()
                                    .fill(Color(hex: category.color))
                                    .frame(width: 12, height: 12)
                                Text(category.name)
                            } else {
                                Text("选择分类")
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                
                // 子任务小组件
                TaskOptionWidget(title: "子任务", iconName: "checklist") {
                    VStack(spacing: 8) {
                        // 已添加的子任务列表
                        ForEach(subtasks) { subtask in
                            HStack {
                                Button(action: {
                                    toggleSubtaskCompletion(id: subtask.id)
                                }) {
                                    Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(subtask.isCompleted ? .blue : .gray)
                                }
                                
                                Text(subtask.title)
                                    .strikethrough(subtask.isCompleted)
                                    .foregroundColor(subtask.isCompleted ? .gray : .primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    removeSubtask(id: subtask.id)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red.opacity(0.7))
                                        .font(.footnote)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // 添加新子任务
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                            
                            TextField("添加子任务", text: $newSubtaskTitle, onCommit: {
                                addSubtask()
                            })
                            
                            if !newSubtaskTitle.isEmpty {
                                Button(action: {
                                    addSubtask()
                                }) {
                                    Text("添加")
                                        .foregroundColor(.blue)
                                        .font(.footnote)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                // 如果有错误，显示错误信息
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal, 16)
                }
                
                Spacer(minLength: 50)
                
                // 创建按钮
                Button(action: {
                    createTaskWithValidation()
                }) {
                    Text("完成")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(title.isEmpty ? Color.blue.opacity(0.6) : Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .disabled(title.isEmpty)
                
                // 额外的底部空间，确保按钮不被键盘遮挡
                Spacer()
                    .frame(height: keyboardHeight > 0 ? keyboardHeight - safeAreaInsets.bottom + 20 : 0)
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .gesture(DragGesture().onChanged { _ in
            // 滑动手势隐藏键盘
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        })
        .onAppear {
            // 获取安全区域
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                let insets = window.safeAreaInsets
                safeAreaInsets = EdgeInsets(
                    top: insets.top,
                    leading: insets.left,
                    bottom: insets.bottom,
                    trailing: insets.right
                )
            }
            
            // 键盘监听
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                    keyboardHeight = keyboardSize.height
                }
            }
            
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                keyboardHeight = 0
            }
        }
        .onTapGesture {
            // 点击背景隐藏键盘
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // 切换子任务完成状态
    private func toggleSubtaskCompletion(id: UUID) {
        if let index = subtasks.firstIndex(where: { $0.id == id }) {
            subtasks[index].isCompleted.toggle()
        }
    }
    
    // 添加子任务
    private func addSubtask() {
        guard !newSubtaskTitle.isEmpty else { return }
        
        subtasks.append(SubTaskItem(title: newSubtaskTitle))
        newSubtaskTitle = ""
    }
    
    // 移除子任务
    private func removeSubtask(id: UUID) {
        subtasks.removeAll { $0.id == id }
    }
    
    // 验证并创建任务
    private func createTaskWithValidation() {
        // 检查结束时间是否早于开始时间
        if endTime < startTime {
            showError = true
            errorMessage = "结束时间不能早于开始时间"
            return
        }
        
        // 清除错误状态
        showError = false
        errorMessage = ""
        
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            createTask()
            isPresented = false
        }
    }
    
    // 创建任务
    private func createTask() {
        // 确定分类ID
        let categoryId: UUID
        if let selectedId = selectedCategoryId {
            categoryId = selectedId
        } else if let todoCategory = viewModel.categories.first(where: { $0.name == "待办" }) {
            categoryId = todoCategory.id
        } else if let firstCategory = viewModel.categories.first {
            categoryId = firstCategory.id
        } else {
            // 如果没有任何分类，这种情况应该由前面的代码处理
            return
        }
        
        // 结合日期和时间
        let dueDate = combineDateAndTime(date: selectedDate, time: endTime)
        let reminderDate = combineDateAndTime(date: selectedDate, time: startTime)
        
        // 创建任务
        var newTask = Task(
            categoryId: categoryId,
            title: title,
            description: notes,
            dueDate: dueDate,
            priority: selectedPriority,
            isCompleted: false,
            reminderDate: reminderDate
        )
        
        // 添加子任务
        for subtask in subtasks {
            newTask.subtasks.append(SubTask(
                id: subtask.id,
                title: subtask.title,
                isCompleted: subtask.isCompleted
            ))
        }
        
        // 保存任务
        viewModel.createTask(newTask)
    }
    
    // 结合日期和时间
    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = timeComponents.second
        
        return calendar.date(from: combinedComponents) ?? Date()
    }
}

// 扩展Date，提供格式化方法
extension Date {
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
} 