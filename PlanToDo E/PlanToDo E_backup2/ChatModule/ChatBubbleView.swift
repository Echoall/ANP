import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                content
            } else {
                content
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.isFromUser ? 
            "您说：\(message.content)" : 
            "AI回复：\(message.content)")
        .accessibilityHint(message.requiresConfirmation ? 
            "需要操作确认" : "")
    }
    
    private var content: some View {
        VStack(alignment: .trailing) {
            Text(message.content)
                .font(.system(size: 16))
                .foregroundStyle(message.isFromUser ? .white : .primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
                .padding(12)
                .background(
                    message.isFromUser 
                        ? Color.blue
                        : (message.requiresConfirmation 
                            ? Color.blue.opacity(0.08) 
                            : Color(.systemGray6))
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
            
            Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
                .padding(.trailing, 4)
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, 
               alignment: message.isFromUser ? .trailing : .leading)
    }
}

#Preview {
    VStack(spacing: 20) {
        ChatBubbleView(message: ChatMessage(id: UUID(), content: "这是用户发送的消息", timestamp: Date(), isFromUser: true, requiresConfirmation: false))
        ChatBubbleView(message: ChatMessage(id: UUID(), content: "这是AI回复的消息，可能会比较长一些，需要测试自动换行的功能是否正常工作。", timestamp: Date(), isFromUser: false, requiresConfirmation: true))
        ChatBubbleView(message: ChatMessage(id: UUID(), content: "这是普通的AI回复。", timestamp: Date(), isFromUser: false, requiresConfirmation: false))
    }
    .padding()
} 