import SwiftUI

struct FunctionSwitchBar: View {
    @AppStorage("isAutoReminderOn") var isAutoReminderOn = false
    @AppStorage("isDeepPlanModeOn") var isDeepPlanModeOn = false
    
    var body: some View {
        HStack(spacing: 8) {
            // 自动提醒按钮 - 独立按钮
            Button {
                isAutoReminderOn.toggle()
                // 添加触觉反馈
                #if os(iOS)
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                #endif
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(isAutoReminderOn ? .white : .secondary)
                    
                    Text("自动提醒")
                        .font(.system(size: 13))
                        .foregroundColor(isAutoReminderOn ? .white : .secondary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(isAutoReminderOn ? Color.blue : Color(.systemGray6))
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
            
            // 深度计划按钮 - 独立按钮
            Button {
                isDeepPlanModeOn.toggle()
                // 添加触觉反馈
                #if os(iOS)
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                #endif
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet.below.rectangle")
                        .font(.system(size: 14))
                        .foregroundStyle(isDeepPlanModeOn ? .white : .secondary)
                    
                    Text("深度计划")
                        .font(.system(size: 13))
                        .foregroundColor(isDeepPlanModeOn ? .white : .secondary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(isDeepPlanModeOn ? Color.blue : Color(.systemGray6))
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// 保留原有的FlatToggleButton组件以便在其他地方使用
struct FlatToggleButton: View {
    @Binding var isOn: Bool
    let icon: String
    let label: String
    
    var body: some View {
        Button {
            isOn.toggle()
            // 添加触觉反馈
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            #endif
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isOn ? .blue : .secondary)
                
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(isOn ? .blue : .secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
        .background(isOn ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

// 保留原有的ToggleButton组件以便在其他地方使用
struct ToggleButton: View {
    @Binding var isOn: Bool
    let icon: String
    let label: String
    let description: String
    
    var body: some View {
        Button {
            isOn.toggle()
            // 添加触觉反馈
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            #endif
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .symbolEffect(.bounce.up, value: isOn)
                    .foregroundStyle(isOn ? .blue : .secondary)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(isOn ? .blue : .secondary)
            }
            .frame(height: 50)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isOn ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isOn ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label)模式")
        .accessibilityValue(isOn ? "已启用" : "已禁用")
        .accessibilityHint(description)
    }
}

struct ConfirmationButtonGroup: View {
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @Environment(\.sizeCategory) var sizeCategory
    
    // 根据字体大小动态调整按钮间距
    private var buttonSpacing: CGFloat {
        switch sizeCategory {
        case .accessibilityExtraExtraExtraLarge:
            return 20
        case .accessibilityExtraExtraLarge:
            return 16
        case .accessibilityExtraLarge:
            return 14
        case .accessibilityLarge:
            return 12
        default:
            return 10
        }
    }
    
    var body: some View {
        HStack(spacing: buttonSpacing) {
            Button(action: onConfirm) {
                Label("确认", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(BubbleButtonStyle(color: .green))
            
            Button(action: onCancel) {
                Label("取消", systemImage: "xmark.circle.fill")
            }
            .buttonStyle(BubbleButtonStyle(color: .red))
        }
        .padding(.top, 8)
    }
}

struct BubbleButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(color)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 20) {
        FunctionSwitchBar()
        ConfirmationButtonGroup(onConfirm: {}, onCancel: {})
    }
    .padding()
} 