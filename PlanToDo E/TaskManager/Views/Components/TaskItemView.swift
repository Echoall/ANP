import SwiftUI

struct TaskItemView: View {
    let task: Task
    let onToggleComplete: (Bool) -> Void
    let onSubTaskToggleComplete: (UUID, Bool) -> Void
    let onTaskTap: () -> Void
    @State private var isExpanded: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            // 主任务项
            Button(action: {
                if task.hasSubTasks {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                } else {
                    onTaskTap()
                }
            }) {
                HStack(alignment: .center, spacing: 12) {
                    // 完成状态按钮
                    Button(action: {
                        withAnimation(.spring()) {
                            onToggleComplete(!task.isCompleted)
                        }
                    }) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundColor(task.isCompleted ? .green : Color.gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    // 任务内容
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(task.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .strikethrough(task.isCompleted)
                            
                            Spacer()
                            
                            // 优先级标识
                            Image(systemName: task.priority.icon)
                                .foregroundColor(task.priority.color)
                                .font(.system(size: 14))
                            
                            // 子任务指示器
                            if task.hasSubTasks {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                                    .animation(.spring(), value: isExpanded)
                            }
                        }
                        
                        // 任务截止日期
                        if !task.isCompleted {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                
                                Text(formatDueDate(task.dueDate))
                                    .font(.caption)
                                    .foregroundColor(task.isOverdue ? .red : .secondary)
                            }
                        }
                    }
                }
                .padding(10)
                #if os(iOS)
                .background(Color(colorScheme == .dark ? .secondarySystemBackground : .systemBackground))
                #else
                .background(colorScheme == .dark ? Color(.darkGray).opacity(0.3) : Color(.white))
                #endif
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 子任务列表 (如果展开)
            if isExpanded && task.hasSubTasks {
                VStack(spacing: 1) {
                    ForEach(task.subtasks) { subtask in
                        HStack(spacing: 12) {
                            // 子任务完成状态按钮
                            Button(action: {
                                onSubTaskToggleComplete(subtask.id, !subtask.isCompleted)
                            }) {
                                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(subtask.isCompleted ? .green : Color.gray)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            // 子任务标题
                            Text(subtask.title)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .strikethrough(subtask.isCompleted)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .padding(.leading, 22) // 缩进
                        #if os(iOS)
                        .background(Color(colorScheme == .dark ? .tertiarySystemBackground : .secondarySystemBackground))
                        #else
                        .background(colorScheme == .dark ? Color(.darkGray).opacity(0.2) : Color(.lightGray).opacity(0.2))
                        #endif
                    }
                }
                .cornerRadius(10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 5)
    }
    
    // 格式化截止日期
    private func formatDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "今天 " + formatter.string(from: date)
        } else if calendar.isDateInTomorrow(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "明天 " + formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd HH:mm"
            return formatter.string(from: date)
        }
    }
}