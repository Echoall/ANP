import Foundation
import Combine
import SwiftUI
import PlanToDo

class QwenMessageProcessor: ChatMessageProcessorProtocol {
    // 通义千问API配置
    let apiKey: String = "sk-cda43bbf67a2488884c46b9c2161c56b" // 与QwenApiTest中的apiKey保持一致
    let baseURL: String = "https://dashscope.aliyuncs.com/v1/services/aigc/text-generation/generation" // 与QwenApiTest中的baseURL保持一致
    let model: String = "qwen-max" // 与QwenApiTest中的model保持一致
    
    public func processMessage(_ message: String) -> AnyPublisher<ChatResponse, Error> {
        // 构建请求体，包括历史消息和当前消息
        let requestBody: [String: Any] = [
            "model": model,
            "input": [
                "messages": [
                    ["role": "user", "content": message]
                ]
            ],
            "parameters": [
                "result_format": "message"
            ]
        ]
        
        // 序列化JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Error: 无法序列化请求体")
            return Just(ChatResponse.simple("抱歉，我无法处理您的请求。"))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // 创建URL
        guard let url = URL(string: baseURL) else {
            print("Error: 无效的URL")
            return Just(ChatResponse.simple("抱歉，服务暂时不可用。"))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // 创建并配置请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: QwenResponse.self, decoder: JSONDecoder())
            .map { qwenResponse -> ChatResponse in
                let responseText = qwenResponse.output.text
                let (operationType, details) = self.analyzeResponse(responseText)
                
                if let type = operationType {
                    return ChatResponse.withConfirmation(responseText, type: type, details: details)
                } else {
                    return ChatResponse.simple(responseText)
                }
            }
            .catch { error -> AnyPublisher<ChatResponse, Error> in
                print("Error: 请求失败 - \(error.localizedDescription)")
                return Just(ChatResponse.simple("抱歉，我暂时无法回应。请稍后再试。"))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    public func executeOperation(_ details: [String: Any]) -> AnyPublisher<String, Error> {
        // 获取操作类型
        guard let typeString = details["type"] as? String,
              let type = OperationType(rawValue: typeString) else {
            return Fail(error: ChatMessageProcessorError.invalidMessage).eraseToAnyPublisher()
        }
        
        // 根据不同类型执行不同操作
        switch type {
        case .createTask:
            let title = details["title"] as? String ?? "无标题任务"
            return Just("已成功创建任务：\(title)")
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            
        case .completeTask:
            return Just("已将任务标记为完成")
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            
        case .updateTask:
            return Just("任务已更新")
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            
        case .deleteTask:
            return Just("任务已删除")
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            
        case .createCategory:
            return Just("已创建新分类")
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            
        case .deleteCategory:
            return Just("已删除分类")
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            
        case .updateCategory:
            return Just("已更新分类")
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            
        case .generatePlan:
            return Just("已生成计划")
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            
        case .analytics:
            return Just("已完成数据分析")
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
    
    // 分析响应文本，识别操作类型和详情
    private func analyzeResponse(_ response: String) -> (operationType: OperationType?, details: [String: Any]) {
        // 默认无操作
        var operationType: OperationType? = nil
        var operationDetails: [String: Any] = [:]
        
        // 解析响应
        if response.contains("创建任务") || response.contains("添加任务") || response.contains("新增任务") {
            operationType = .createTask
            operationDetails = [
                "type": OperationType.createTask.rawValue,
                "title": extractTaskName(from: response) ?? "新任务",
                "description": "从AI助手创建的任务"
            ]
        } else if response.contains("删除任务") {
            operationType = .deleteTask
            operationDetails = [
                "type": OperationType.deleteTask.rawValue,
                "taskName": extractTaskName(from: response) ?? "指定任务"
            ]
        } else if response.contains("完成任务") || (response.contains("任务") && response.contains("标记为完成")) {
            operationType = .completeTask
            operationDetails = [
                "type": OperationType.completeTask.rawValue,
                "taskName": extractTaskName(from: response) ?? "指定任务"
            ]
        } else if response.contains("修改任务") || response.contains("更新任务") {
            operationType = .updateTask
            operationDetails = [
                "type": OperationType.updateTask.rawValue,
                "taskName": extractTaskName(from: response) ?? "指定任务"
            ]
        }
        
        return (operationType, operationDetails)
    }
    
    // 从响应文本中提取任务名称
    private func extractTaskName(from text: String) -> String? {
        // 尝试从【】中提取任务名称
        if let range = text.range(of: "【.*?】", options: .regularExpression) {
            let taskName = text[range]
            return String(taskName.dropFirst().dropLast())
        }
        
        // 尝试从"任务名称："后面提取
        if let range = text.range(of: "任务名称：.*?[，。]", options: .regularExpression) {
            let taskName = text[range]
            return String(taskName.dropFirst(5).dropLast())
        }
        
        return nil
    }
} 