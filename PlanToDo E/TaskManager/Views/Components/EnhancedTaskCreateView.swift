import SwiftUI
// 我们不需要再另外导入Task，因为它很可能是通过MainViewModel访问的

struct EnhancedTaskCreateView: View {
    @ObservedObject var viewModel: MainViewModel
    @Binding var isPresented: Bool
    var initialCategoryId: UUID?
    var initialDate: Date?
    
    // 任务基本信息
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var selectedPriority: TaskPriority = .medium
    @State private var selectedCategoryId: UUID? = nil
    @State private var enableReminder: Bool = true
    @State private var reminderTime: Date = Calendar.current.date(byAdding: .minute, value: -30, to: Date()) ?? Date()
    
    // 子任务管理
    @State private var subtasks: [SubTask] = []
    @State private var newSubtaskTitle: String = ""
    
    // UI状态
    @State private var activeTab: TaskCreateTab = .basic
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isSubtaskFocused: Bool
    
    // 键盘状态
    @State private var keyboardHeight: CGFloat = 0
    
    // 新分类创建
    @State private var isShowingCategoryCreation = false
    @State private var newCategoryName = ""
    @State private var newCategoryColor = "#007AFF" // 默认蓝色
    
    // 折叠面板状态
    @State private var isBasicInfoExpanded = true
    @State private var isTimeSettingsExpanded = true
    @State private var isPrioritySettingsExpanded = true
    @State private var isSubtasksExpanded = true
    
    // 颜色方案
    private let accentGradient = LinearGradient(
        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let grayGradient = LinearGradient(
        gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // 新增环境变量获取当前颜色方案
    @Environment(\.colorScheme) private var colorScheme
    
    init(viewModel: MainViewModel, isPresented: Binding<Bool>, initialCategoryId: UUID? = nil, initialDate: Date? = nil) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        self.initialCategoryId = initialCategoryId
        self.initialDate = initialDate
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 顶部栏
                topBar
                
                // 主要内容区域
                ScrollView {
                    VStack(spacing: 16) {
                        // 标题输入
                        titleInput
                        
                        // 分隔线
                        Divider()
                            .padding(.horizontal)
                        
                        // 内容区域 - 改为线性布局，不使用标签页
                        VStack(spacing: 20) {
                            // 基本信息 - 可折叠
                            collapsibleSection(
                                title: "基本信息",
                                isExpanded: $isBasicInfoExpanded,
                                content: { basicInfoView }
                            )
                            
                            Divider()
                                .padding(.horizontal, 16)
                                .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                            
                            // 时间设置 - 可折叠
                            collapsibleSection(
                                title: "时间设置",
                                isExpanded: $isTimeSettingsExpanded,
                                content: { timeSettingsView }
                            )
                            
                            Divider()
                                .padding(.horizontal, 16)
                                .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                            
                            // 重要级别 - 可折叠
                            collapsibleSection(
                                title: "重要级别",
                                isExpanded: $isPrioritySettingsExpanded,
                                content: { prioritySettingsView }
                            )
                            
                            Divider()
                                .padding(.horizontal, 16)
                                .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                            
                            // 子任务 - 可折叠
                            collapsibleSection(
                                title: "子任务",
                                isExpanded: $isSubtasksExpanded,
                                content: { subtasksView }
                            )
                            
                            // 底部创建按钮 - 移动到滚动视图内部
                            createButton
                                .padding(.top, 20)
                                .padding(.bottom, keyboardHeight > 0 ? keyboardHeight : 20)
                        }
                    }
                    .padding(.horizontal)
                    .frame(width: min(geometry.size.width, 600)) // 限制最大宽度
                    .frame(maxWidth: .infinity) // 确保居中
                }
                .padding(.bottom, 8)
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .onAppear {
                setupInitialValues()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTitleFocused = true
                }
                
                #if os(iOS)
                // 注册键盘通知
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                    let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
                    keyboardHeight = keyboardFrame.height - geometry.safeAreaInsets.bottom
                    if keyboardHeight < 0 {
                        keyboardHeight = 0
                    }
                }
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    keyboardHeight = 0
                }
                #endif
            }
            .onDisappear {
                #if os(iOS)
                // 移除通知观察者
                NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
                NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
                #endif
            }
            .sheet(isPresented: $isShowingCategoryCreation) {
                createNewCategoryView
            }
        }
    }
    
    // 可折叠组件
    private func collapsibleSection<Content: View>(
        title: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            // 标题栏（可点击切换展开/收起）
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.wrappedValue.toggle()
                }
            }) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 内容区域
            if isExpanded.wrappedValue {
                content()
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.vertical, 5)
        .background(colorScheme == .dark ? Color(.systemGray5).opacity(0.3) : Color(.systemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    // MARK: - 组件
    
    private var topBar: some View {
        HStack {
            Button(action: {
                isPresented = false
            }) {
                Text("取消")
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text("创建任务")
                .font(.headline)
            
            Spacer()
            
            Button(action: {
                createTaskWithValidation()
            }) {
                Text("完成")
                    .foregroundColor(title.isEmpty ? .gray : .blue)
            }
            .disabled(title.isEmpty)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.systemGray4)),
            alignment: .bottom
        )
    }
    
    private var titleInput: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("任务标题")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("记些重要的事情吧", text: $title)
                .font(.system(size: 20, weight: .semibold))
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .focused($isTitleFocused)
        }
    }
    
    private var basicInfoView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 任务描述
            VStack(alignment: .leading, spacing: 10) {
                Text("任务描述")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ZStack(alignment: .topLeading) {
                    if notes.isEmpty {
                        Text("添加详细说明...")
                            .foregroundColor(Color.gray.opacity(0.7))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .padding(4)
                }
                .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            }
            
            Divider()
                .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
            
            // 分类选择
            VStack(alignment: .leading, spacing: 10) {
                Text("选择分类")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.categories) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategoryId == category.id,
                                colorScheme: colorScheme
                            )
                            .onTapGesture {
                                selectedCategoryId = category.id
                            }
                        }
                        
                        // 添加新分类按钮
                        Button(action: {
                            isShowingCategoryCreation = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("新建分类")
                                    .font(.system(size: 14))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(colorScheme == .dark ? 0.2 : 0.1))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.blue.opacity(colorScheme == .dark ? 0.5 : 0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    // 创建新分类的视图
    private var createNewCategoryView: some View {
        NavigationView {
            Form {
                Section(header: Text("分类信息")) {
                    TextField("分类名称", text: $newCategoryName)
                        .autocapitalization(.none)
                    
                    // 颜色选择器
                    ColorSelector(selectedColor: $newCategoryColor)
                }
                
                Section {
                    Button(action: createNewCategory) {
                        Text("添加分类")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.blue)
                    }
                    .disabled(newCategoryName.isEmpty)
                }
            }
            .navigationTitle("创建新分类")
            .navigationBarItems(
                trailing: Button("取消") {
                    isShowingCategoryCreation = false
                }
            )
        }
    }
    
    // 颜色选择器组件
    struct ColorSelector: View {
        @Binding var selectedColor: String
        
        // 预定义的颜色选项
        let colorOptions = [
            "#007AFF", // 蓝色
            "#FF3B30", // 红色
            "#34C759", // 绿色
            "#FF9500", // 橙色
            "#AF52DE", // 紫色
            "#5856D6", // 靛蓝色
            "#FF2D55", // 粉色
            "#FFCC00"  // 黄色
        ]
        
        var body: some View {
            VStack(alignment: .leading) {
                Text("选择颜色")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                    ForEach(colorOptions, id: \.self) { color in
                        Circle()
                            .fill(Color(hex: color))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .opacity(selectedColor == color ? 1 : 0)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 1)
                                    .opacity(selectedColor == color ? 1 : 0)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            .onTapGesture {
                                selectedColor = color
                            }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private var timeSettingsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 日期选择 - 使用更紧凑的样式
            VStack(alignment: .leading, spacing: 10) {
                Text("日期")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // 使用更紧凑的日期选择器
                DatePicker(
                    "选择日期",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(CompactDatePickerStyle())
                .padding()
                .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            }
            
            Divider()
                .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
            
            // 时间选择
            VStack(alignment: .leading, spacing: 10) {
                Text("时间")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                DatePicker(
                    "选择时间",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(CompactDatePickerStyle())
                .padding()
                .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            }
            
            Divider()
                .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
            
            // 提醒开关
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $enableReminder) {
                    Text("开启提醒")
                        .font(.body)
                }
                .padding()
                .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                )
                
                if enableReminder {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("提醒时间")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        DatePicker(
                            "提醒时间",
                            selection: $reminderTime,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(CompactDatePickerStyle())
                        .padding()
                        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private var prioritySettingsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 24))
                    
                    Text("高优先级")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        selectedPriority = .high
                    }) {
                        Image(systemName: selectedPriority == .high ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedPriority == .high ? .green : .gray)
                            .font(.system(size: 24))
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                Divider()
                    .padding(.horizontal, 8)
                
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 24))
                    
                    Text("中等优先级")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        selectedPriority = .medium
                    }) {
                        Image(systemName: selectedPriority == .medium ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedPriority == .medium ? .green : .gray)
                            .font(.system(size: 24))
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                Divider()
                    .padding(.horizontal, 8)
                
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.green)
                        .font(.system(size: 24))
                    
                    Text("低优先级")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        selectedPriority = .low
                    }) {
                        Image(systemName: selectedPriority == .low ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedPriority == .low ? .green : .gray)
                            .font(.system(size: 24))
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                Divider()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                
                Text("高优先级：紧急且重要的任务，需要立即处理\n中等优先级：重要但不紧急的任务，需要按计划处理\n低优先级：可以推迟的任务，有时间再处理")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var subtasksView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 添加子任务
            VStack(alignment: .leading, spacing: 10) {
                Text("添加子任务")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("输入子任务...", text: $newSubtaskTitle)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .focused($isSubtaskFocused)
                        .onSubmit {
                            // 当按下回车键时添加子任务
                            addSubtask()
                        }
                    
                    Button(action: {
                        addSubtask()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 30))
                    }
                    .disabled(newSubtaskTitle.isEmpty)
                }
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            
            Divider()
            
            // 子任务列表
            VStack(alignment: .leading, spacing: 0) {
                Text("子任务列表")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !subtasks.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(subtasks) { subtask in
                            HStack {
                                Button(action: {
                                    toggleSubtaskCompletion(id: subtask.id)
                                }) {
                                    Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(subtask.isCompleted ? .green : .gray)
                                        .font(.system(size: 20))
                                }
                                
                                Text(subtask.title)
                                    .strikethrough(subtask.isCompleted)
                                    .foregroundColor(subtask.isCompleted ? .gray : .primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    removeSubtask(id: subtask.id)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            
                            Divider()
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                } else {
                    Text("尚无子任务")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var createButton: some View {
        Button(action: {
            createTaskWithValidation()
        }) {
            Text("创建任务")
                .font(.headline)
                .foregroundColor(.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(title.isEmpty ? grayGradient : accentGradient)
                .cornerRadius(15)
                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 5)
        }
        .disabled(title.isEmpty)
    }
    
    // MARK: - 逻辑函数
    
    // 创建新分类
    private func createNewCategory() {
        guard !newCategoryName.isEmpty else { return }
        
        // 创建新分类
        let newCategory = Category(
            id: UUID(),
            name: newCategoryName,
            color: newCategoryColor,
            order: viewModel.categories.count + 1
        )
        
        // 保存到模型
        viewModel.createCategory(newCategory)
        
        // 选中新创建的分类
        selectedCategoryId = newCategory.id
        
        // 重置状态
        newCategoryName = ""
        newCategoryColor = "#007AFF"
        
        // 关闭创建分类视图
        isShowingCategoryCreation = false
    }
    
    private func setupInitialValues() {
        // 如果有初始分类，则使用它
        if let initialCategoryId = initialCategoryId {
            selectedCategoryId = initialCategoryId
        } else if !viewModel.categories.isEmpty {
            selectedCategoryId = viewModel.categories.first?.id
        }
        
        // 如果有初始日期，则使用它
        if let initialDate = initialDate {
            selectedDate = initialDate
            // 保持时间不变，只更新日期部分
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: initialDate)
            var combinedComponents = DateComponents()
            combinedComponents.year = dateComponents.year
            combinedComponents.month = dateComponents.month
            combinedComponents.day = dateComponents.day
            combinedComponents.hour = timeComponents.hour
            combinedComponents.minute = timeComponents.minute
            if let combinedDate = calendar.date(from: combinedComponents) {
                selectedTime = combinedDate
            }
        }
    }
    
    // 添加子任务
    private func addSubtask() {
        guard !newSubtaskTitle.isEmpty else { return }
        
        subtasks.append(SubTask(title: newSubtaskTitle))
        newSubtaskTitle = ""
        
        // 继续保持子任务输入框焦点，方便连续添加
        isSubtaskFocused = true
    }
    
    // 切换子任务完成状态
    private func toggleSubtaskCompletion(id: UUID) {
        if let index = subtasks.firstIndex(where: { $0.id == id }) {
            subtasks[index].isCompleted.toggle()
        }
    }
    
    // 移除子任务
    private func removeSubtask(id: UUID) {
        subtasks.removeAll { $0.id == id }
    }
    
    // 创建任务验证
    private func createTaskWithValidation() {
        // 任务标题不能为空
        if title.isEmpty {
            showError = true
            errorMessage = "请输入任务标题"
            return
        }
        
        // 清除错误状态
        showError = false
        errorMessage = ""
        
        // 创建任务
        createTask()
        isPresented = false
    }
    
    // 创建任务
    private func createTask() {
        // 获取分类ID
        let categoryId: UUID
        if let selectedId = selectedCategoryId {
            categoryId = selectedId
        } else if let todoCategory = viewModel.categories.first(where: { $0.name == "待办" }) {
            categoryId = todoCategory.id
        } else if let firstCategory = viewModel.categories.first {
            categoryId = firstCategory.id
        } else {
            // 如果没有任何分类，使用默认分类
            return
        }
        
        // 结合日期和时间
        let dueDate = combineDateAndTime(date: selectedDate, time: selectedTime)
        
        // 提醒时间
        let reminderDate = enableReminder ? reminderTime : nil
        
        // 创建任务对象
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
        newTask.subtasks = subtasks
        
        // 保存任务
        viewModel.createTask(newTask)
    }
    
    // 合并日期和时间
    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        return calendar.date(from: combinedComponents) ?? Date()
    }
}

// MARK: - 辅助视图和模型

// 分类按钮
struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    var colorScheme: ColorScheme? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: category.color))
                .frame(width: 12, height: 12)
            
            Text(category.name)
                .font(.system(size: 14))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color(hex: category.color).opacity(colorScheme == .dark ? 0.25 : 0.15) : (colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: category.color).opacity(colorScheme == .dark ? 0.6 : 0.3), lineWidth: isSelected ? 1.5 : 1)
        )
    }
}

// 标签页枚举 - 保留但不再使用
enum TaskCreateTab: String, CaseIterable {
    case basic = "基本信息"
    case time = "时间设置"
    case details = "重要级别"
    case subtasks = "子任务"
    
    var title: String {
        return self.rawValue
    }
    
    var iconName: String {
        switch self {
        case .basic:
            return "info.circle"
        case .time:
            return "clock"
        case .details:
            return "exclamationmark.circle"
        case .subtasks:
            return "checklist"
        }
    }
}

// 优先级选择按钮 - 保留但不再使用
struct PriorityButton: View {
    let priority: TaskPriority
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? priority.color : Color(.systemGray5))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: priority.icon)
                        .foregroundColor(isSelected ? .white : .gray)
                        .font(.system(size: 16))
                }
                
                Text(priority.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? priority.color : .gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
} 