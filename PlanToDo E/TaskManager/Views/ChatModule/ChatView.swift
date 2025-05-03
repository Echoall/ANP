import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var scrollToBottom = false
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    @State private var showEmptyState = false
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航
            ChatNavigationBar(title: "Coral")
            
            // 消息列表
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // 初始提示信息（当消息为空时）
                        if viewModel.messages.isEmpty {
                            ChatEmptyStateView()
                        }
                        
                        // 加载更多按钮（当有更多历史消息可加载时）
                        if viewModel.messages.count > 20 {
                            Button("加载更多...") {
                                viewModel.loadMoreMessages()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        
                        // 消息气泡
                        ForEach(viewModel.messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                        }
                        
                        // AI正在输入指示器
                        if viewModel.isProcessing {
                            TypingIndicator()
                                .padding()
                                .id("typingIndicator")
                        }
                        
                        // 操作确认按钮组
                        if let confirmation = viewModel.pendingConfirmation, !confirmation.isExpired {
                            VStack {
                                if viewModel.showConfirmationTimer {
                                    Text("\(Int(viewModel.remainingTime))秒后自动取消")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                ConfirmationButtonGroup(
                                    onConfirm: {
                                        viewModel.confirmOperation()
                                    },
                                    onCancel: {
                                        viewModel.cancelConfirmation()
                                    }
                                )
                            }
                            .padding()
                            .id("confirmationButtons")
                            .transition(.opacity)
                        }
                        
                        // 底部填充，确保内容能够滚动到底部
                        Color.clear.frame(height: 1)
                            .id("bottomSpacer")
                    }
                    .padding(.vertical)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    // 点击背景隐藏键盘
                    hideKeyboard()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    // 当消息数量变化时，滚动到底部
                    scrollToBottom = true
                }
                .onChange(of: viewModel.isProcessing) { _, isProcessing in
                    if isProcessing {
                        // 当AI开始输入时，滚动到指示器
                        withAnimation {
                            scrollProxy.scrollTo("typingIndicator", anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.pendingConfirmation) { _, _ in
                    // 当确认状态变化时，滚动到确认按钮
                    if viewModel.pendingConfirmation != nil {
                        withAnimation {
                            scrollProxy.scrollTo("confirmationButtons", anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    // 初次显示时，滚动到底部
                    scrollToBottom = true
                    setupKeyboardNotifications()
                }
                .onDisappear {
                    removeKeyboardNotifications()
                }
                .onChange(of: scrollToBottom) { _, shouldScroll in
                    if shouldScroll {
                        withAnimation {
                            scrollProxy.scrollTo("bottomSpacer", anchor: .bottom)
                        }
                        // 重置状态
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            scrollToBottom = false
                        }
                    }
                }
            }
            
            // 功能切换栏和底部输入栏组合
            VStack(spacing: 0) {
                // 功能切换栏
                FunctionSwitchBar()
                
                // 底部输入栏
                InputToolbar(
                    text: $viewModel.inputText,
                    onSend: viewModel.sendMessage
                )
            }
        }
        .navigationBarHidden(true)
        .background(Color(.systemBackground))
        .gesture(DragGesture(minimumDistance: 20).onEnded { gesture in
            // 向下滑动隐藏键盘
            if gesture.translation.height > 0 {
                hideKeyboard()
            }
        })
    }
    
    private func hideKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
    
    private func setupKeyboardNotifications() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                keyboardHeight = keyboardSize.height
                // 键盘显示时滚动到底部
                scrollToBottom = true
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            keyboardHeight = 0
        }
        #endif
    }
    
    private func removeKeyboardNotifications() {
        #if os(iOS)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        #endif
    }
}

struct ChatNavigationBar: View {
    let title: String
    
    var body: some View {
        HStack {
            Spacer()
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            Color(.systemBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
        )
    }
}

struct TypingIndicator: View {
    @State private var phase = 0.0
    
    var body: some View {
        HStack {
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.gray.opacity(0.7))
                        .frame(width: 7, height: 7)
                        .offset(y: sin(phase + Double(index) * 0.5) * 2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Spacer()
        }
        .padding(.leading)
        .onAppear {
            withAnimation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// 使用现有的EmptyStateView组件，不再重复定义
private struct ChatEmptyStateView: View {
    var body: some View {
        EmptyStateView(
            title: "没有消息记录",
            message: "发送消息开始与Coral对话",
            systemImageName: "bubble.left.and.bubble.right"
        )
    }
}

#Preview {
    NavigationView {
        ChatView()
    }
} 