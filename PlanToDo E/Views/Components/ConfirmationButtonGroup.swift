import SwiftUI

/// 确认操作按钮组视图
struct ConfirmationButtonGroup: View {
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 取消按钮
            Button(action: onCancel) {
                Text("取消")
                    .frame(minWidth: 80)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            }
            
            // 确认按钮
            Button(action: onConfirm) {
                Text("确认")
                    .frame(minWidth: 80)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
    }
}

/// 全屏确认对话框
struct FullscreenConfirmationDialog: View {
    let message: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    var operationType: OperationType? = nil
    var showTimer: Bool = true
    var remainingTime: TimeInterval = 30
    
    var body: some View {
        VStack(spacing: 20) {
            // 操作图标
            if let operationType = operationType {
                Image(systemName: iconForOperationType(operationType))
                    .font(.system(size: 48))
                    .foregroundColor(colorForOperationType(operationType))
                    .padding(.bottom, 10)
            }
            
            // 对话框消息
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
            
            // 倒计时显示（如果启用）
            if showTimer && remainingTime > 0 {
                Text("\(Int(remainingTime))秒后自动取消")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 5)
            }
            
            // 确认按钮组
            ConfirmationButtonGroup(
                onConfirm: onConfirm,
                onCancel: onCancel
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
        )
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // 点击背景也可以取消操作
                    onCancel()
                }
        )
    }
    
    // 根据操作类型返回对应的图标
    private func iconForOperationType(_ type: OperationType) -> String {
        switch type {
        case .createTask:
            return "plus.circle"
        case .deleteTask:
            return "trash.circle"
        case .completeTask:
            return "checkmark.circle"
        case .updateTask:
            return "pencil.circle"
        case .createCategory:
            return "folder.badge.plus"
        case .deleteCategory:
            return "folder.badge.minus"
        case .updateCategory:
            return "folder.badge.gear"
        case .generatePlan:
            return "calendar.badge.clock"
        case .analytics:
            return "chart.bar"
        }
    }
    
    // 根据操作类型返回对应的颜色
    private func colorForOperationType(_ type: OperationType) -> Color {
        switch type {
        case .createTask, .createCategory:
            return .blue
        case .deleteTask, .deleteCategory:
            return .red
        case .completeTask:
            return .green
        case .updateTask, .updateCategory:
            return .orange
        case .generatePlan, .analytics:
            return .purple
        }
    }
}

#Preview {
    VStack {
        // 预览确认按钮组
        ConfirmationButtonGroup(
            onConfirm: {},
            onCancel: {}
        )
        .padding()
        
        // 预览全屏确认对话框
        FullscreenConfirmationDialog(
            message: "您确认要删除任务【重要会议】吗？",
            onConfirm: {},
            onCancel: {},
            operationType: .deleteTask,
            showTimer: true,
            remainingTime: 25
        )
    }
} 