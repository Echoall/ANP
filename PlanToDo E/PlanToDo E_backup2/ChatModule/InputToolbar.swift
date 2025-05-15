import SwiftUI

struct InputToolbar: View {
    @Binding var text: String
    var onSend: (String) -> Void
    @State private var inputHistory: [String] = []
    @State private var historyIndex: Int = -1
    @FocusState private var isInputFocused: Bool
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(alignment: .center, spacing: 8) {
                // 输入框
                TextField("发送消息...", text: $text, axis: .vertical)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .focused($isInputFocused)
                    .lineLimit(1...5)
                    .submitLabel(.send)
                    .onSubmit {
                        sendMessage()
                    }
                
                // 发送按钮
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.leading, 4)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // 移除格式快捷工具栏
        }
        .background(Color(.systemBackground))
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive {
                // 当应用进入后台时，隐藏键盘
                hideKeyboard()
            }
        }
    }
    
    private func sendMessage() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            onSend(trimmedText)
            // 添加到历史记录
            inputHistory.append(trimmedText)
            historyIndex = inputHistory.count
            text = ""
        }
    }
    
    private func hideKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

#Preview {
    VStack {
        Spacer()
        InputToolbar(text: .constant(""), onSend: { _ in })
    }
} 