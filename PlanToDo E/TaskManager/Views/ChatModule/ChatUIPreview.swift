import SwiftUI

struct ChatUIPreview: View {
    var body: some View {
        NavigationView {
            ChatView()
        }
    }
}

struct ChatBubblePreview: View {
    var body: some View {
        VStack(spacing: 20) {
            ChatBubbleView(message: ChatMessage.userMessage("您好，我想创建一个新的任务"))
            
            ChatBubbleView(message: ChatMessage.aiMessage("您想创建一个新任务吗？我可以帮您安排。", requiresConfirmation: true, operationType: .createTask))
            
            ChatBubbleView(message: ChatMessage.aiMessage("任务「从AI创建的任务」已成功创建!"))
        }
        .padding()
    }
}

#Preview("聊天界面") {
    ChatUIPreview()
}

#Preview("聊天气泡") {
    ChatBubblePreview()
} 