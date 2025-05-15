import SwiftUI
import Combine

/// 预览用扩展
extension PreviewProvider {
    /// 创建带有模拟数据的预览
    static var mockTasks: [Task] {
        // 先创建几个分类ID，以便在任务中引用
        let workCategoryId = UUID()
        let personalCategoryId = UUID()
        let healthCategoryId = UUID()
        let studyCategoryId = UUID()
        let homeCategoryId = UUID()
        
        return [
            Task(
                id: UUID(),
                categoryId: workCategoryId,
                title: "完成项目报告", 
                description: "准备季度项目进度报告，包括所有相关数据和分析", 
                dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
                priority: .high,
                isCompleted: false
            ),
            
            Task(
                id: UUID(),
                categoryId: personalCategoryId,
                title: "购买生日礼物", 
                description: "为朋友的生日派对购买礼物", 
                dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
                priority: .medium,
                isCompleted: false
            ),
            
            Task(
                id: UUID(),
                categoryId: healthCategoryId,
                title: "健身锻炼", 
                description: "每周三次的健身计划，包括30分钟有氧运动和力量训练", 
                dueDate: Calendar.current.date(byAdding: .hour, value: 8, to: Date())!,
                priority: .medium,
                isCompleted: false
            ),
            
            Task(
                id: UUID(),
                categoryId: studyCategoryId,
                title: "阅读技术书籍", 
                description: "阅读《高效编程技巧》第5-8章", 
                dueDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!,
                priority: .low,
                isCompleted: false
            ),
            
            Task(
                id: UUID(),
                categoryId: homeCategoryId,
                title: "整理工作区域", 
                description: "清理和整理办公桌和电脑文件", 
                dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                priority: .medium,
                isCompleted: true
            ),
        ]
    }
    
    /// 创建模拟分类数据
    static var mockCategories: [Category] {
        [
            Category(id: UUID(), name: "工作", color: "#0000FF", order: 0),
            Category(id: UUID(), name: "个人", color: "#00FF00", order: 1),
            Category(id: UUID(), name: "健康", color: "#FF0000", order: 2),
            Category(id: UUID(), name: "学习", color: "#800080", order: 3),
            Category(id: UUID(), name: "家庭", color: "#FFA500", order: 4)
        ]
    }
    
    /// 创建模拟AI响应处理器
    static var mockAIProcessor: AIProcessor {
        // 使用测试API密钥创建QwenClient实例
        let testClient = QwenClient(apiKey: "sk-test-mock-api-key")
        // 创建AIProcessor实例并注入模拟客户端
        return AIProcessor(client: testClient)
    }
    
    /// 创建模拟聊天消息处理器
    static var mockChatMessageProcessor: DefaultChatMessageProcessor {
        let processor = DefaultChatMessageProcessor(aiProcessor: mockAIProcessor)
        return processor
    }
    
    /// 创建模拟聊天消息
    static var mockChatMessages: [ChatMessage] {
        let now = Date()
        return [
            ChatMessage(id: "1", content: "你好，我有什么可以帮助你的吗？", role: .assistant, timestamp: now.addingTimeInterval(-600), requiresConfirmation: false, operationType: nil),
            ChatMessage(id: "2", content: "我需要管理我的任务", role: .user, timestamp: now.addingTimeInterval(-540), requiresConfirmation: false, operationType: nil),
            ChatMessage(id: "3", content: "当然可以！我可以帮你创建、编辑和管理任务。你想做什么呢？", role: .assistant, timestamp: now.addingTimeInterval(-480), requiresConfirmation: false, operationType: nil),
            ChatMessage(id: "4", content: "创建一个新任务", role: .user, timestamp: now.addingTimeInterval(-420), requiresConfirmation: false, operationType: nil),
            ChatMessage(id: "5", content: "好的，我可以帮你创建新任务。请提供任务的标题、描述、优先级和截止日期等信息。", role: .assistant, timestamp: now.addingTimeInterval(-360), requiresConfirmation: true, operationType: .createTask),
        ]
    }
} 