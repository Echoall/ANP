import SwiftUI

struct TaskRow: View {
    let task: Task
    let viewModel: MainViewModel
    var onSelect: ((Task) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // 任务优先级指示条
            Rectangle()
                .fill(priorityColor)
                .frame(width: 4)
                .cornerRadius(2)
            
            // 任务内容
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // 显示任务截止时间
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                    
                    Text(formattedDueDate)
                        .font(.caption)
                }
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 分类标签（如果有）
            if let category = getCategory() {
                Text(category.name)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(categoryColor(category).opacity(0.2))
                    .foregroundColor(categoryColor(category))
                    .cornerRadius(4)
            }
            
            // 添加视觉提示箭头
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
                .font(.caption)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(.systemBackground))
        .contentShape(Rectangle()) // 确保整行都可点击
        .onTapGesture {
            print("直接点击TaskRow: \(task.title)")
            onSelect?(task)
        }
        .buttonStyle(PlainButtonStyle()) // 避免iOS默认的按钮样式干扰
        .background(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
    
    // 根据任务优先级获取颜色
    private var priorityColor: Color {
        switch task.priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .green
        }
    }
    
    // 根据分类获取颜色
    private func categoryColor(_ category: Category) -> Color {
        // 使用简单的颜色逻辑而不是hex转换
        let colors: [Color] = [.blue, .green, .orange, .red, .purple, .teal]
        let hash = abs(category.id.hashValue)
        let index = hash % colors.count
        return colors[index]
    }
    
    // 格式化任务截止日期
    private var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: task.dueDate)
    }
    
    // 获取任务所属分类
    private func getCategory() -> Category? {
        return viewModel.categories.first(where: { $0.id == task.categoryId })
    }
}

// 预览
struct TaskRow_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = MainViewModel()
        let task = Task(
            id: UUID(),
            categoryId: viewModel.categories.first?.id ?? UUID(),
            title: "完成项目报告",
            description: "准备周五演示用的项目进度报告",
            dueDate: Date(),
            priority: .high,
            isCompleted: false
        )
        
        return TaskRow(task: task, viewModel: viewModel)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}