import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing = false
    @Published var inputText = ""
    
    private var aiService: AIAnalysisService
    private var cancellables = Set<AnyCancellable>()
    
    init(aiService: AIAnalysisService = AIAnalysisService()) {
        self.aiService = aiService
        loadInitialMessages()
    }
    
    private func loadInitialMessages() {
        // 加载欢迎消息
        let welcomeMessage = ChatMessage(
            content: "你好！我是你的AI助手。我可以帮你：\n1. 分析和优化你的任务安排\n2. 提供时间管理建议\n3. 回答关于任务和目标的问题",
            isFromUser: false
        )
        messages.append(welcomeMessage)
    }
    
    func sendMessage(_ text: String) {
        guard !text.isEmpty else { return }
        
        // 添加用户消息
        let userMessage = ChatMessage(content: text, isFromUser: true)
        messages.append(userMessage)
        inputText = ""
        
        // 设置处理状态
        isProcessing = true
        
        // 调用AI服务
        aiService.analyzeMessage(text)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isProcessing = false
                if case .failure(let error) = completion {
                    // 处理错误
                    let errorMessage = ChatMessage(
                        content: "抱歉，处理消息时出现错误：\(error.localizedDescription)",
                        isFromUser: false
                    )
                    self?.messages.append(errorMessage)
                }
            }, receiveValue: { [weak self] response in
                // 添加AI响应
                let aiMessage = ChatMessage(
                    content: response,
                    isFromUser: false
                )
                self?.messages.append(aiMessage)
            })
            .store(in: &cancellables)
    }
    
    func clearChat() {
        messages.removeAll()
        loadInitialMessages()
    }
} 