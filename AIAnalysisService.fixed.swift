import Foundation
import Combine

enum AIModelType {
    case baiduWenxin     // 百度文心一言
    case aliTongyi       // 阿里通义千问
    case xunfeiSpark     // 讯飞星火认知
    case zhipuChatGLM    // 智谱ChatGLM
    
    var displayName: String {
        switch self {
        case .baiduWenxin: return "百度文心一言"
        case .aliTongyi: return "阿里通义千问"
        case .xunfeiSpark: return "讯飞星火认知"
        case .zhipuChatGLM: return "智谱ChatGLM"
        }
    }
}

// API密钥存储结构
struct AIApiKeys {
    static var tongyiApiKey: String = "" // 存储通义千问API密钥
}

class AIAnalysisService {
    static let shared = AIAnalysisService()
    
    // 当前使用的模型
    var currentModel: AIModelType = .aliTongyi
    
    // 模拟API请求的延迟
    private let simulationDelay: TimeInterval = 1.5
    
    private init() {
        print("AIAnalysisService初始化，当前模型：\(currentModel.displayName)")
        print("通义千问API密钥是否设置：\(!AIApiKeys.tongyiApiKey.isEmpty)")
    }
    
    // 分析目标并生成步骤
    func analyzeGoal(title: String, description: String) -> AnyPublisher<[GoalStep], Error> {
        print("分析目标：\(title)")
        print("当前模型：\(currentModel.displayName)")
        print("API密钥是否设置：\(!AIApiKeys.tongyiApiKey.isEmpty)")
        
        // 如果使用通义千问模型，则调用实际API
        if currentModel == .aliTongyi && !AIApiKeys.tongyiApiKey.isEmpty && AIApiKeys.tongyiApiKey != "YOUR_TONGYI_API_KEY" {
            print("使用通义千问API进行分析")
            return callTongyiAPI(title: title, description: description)
        } else {
            print("使用模拟数据，原因：\(currentModel != .aliTongyi ? "非通义千问模型" : "API密钥未设置")")
            // 对于其他模型或没有API密钥的情况，使用模拟数据
            return simulateStepGeneration(title: title, description: description)
        }
    }
    
    // 调用通义千问API
    private func callTongyiAPI(title: String, description: String) -> AnyPublisher<[GoalStep], Error> {
        return Future<[GoalStep], Error> { promise in
            // 构建API请求
            let apiKey = AIApiKeys.tongyiApiKey
            let baseURL = "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation"
            
            print("🔍 准备调用通义千问API...")
            print("🔑 API密钥长度: \(apiKey.count) 字符")
            print("🌐 URL: \(baseURL)")
            
            guard let url = URL(string: baseURL) else {
                let error = NSError(domain: "AIAnalysisService", code: 400, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])
                print("❌ URL创建失败: \(error.localizedDescription)")
                promise(.failure(error))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
            // 构建请求体
            let prompt = """
            你是一个AI助手，专门帮助用户分析目标并生成实现步骤。用户需要你分析以下目标，并提供有序的步骤来实现它。将回答格式化为JSON，每个步骤包含标题和描述：
            目标标题：\(title)
            目标描述：\(description)
            
            返回格式要求：
            {
              "steps": [
                {"title": "步骤1标题", "description": "步骤1详细描述"},
                {"title": "步骤2标题", "description": "步骤2详细描述"},
                ...
              ]
            }
            
            请仅返回JSON格式的回答，不要有任何前置或后置的解释文字。确保你的回答是有效的JSON。请根据目标内容生成具体、可操作的步骤，而不是通用步骤。
            """
            
            print("📝 提示词已准备")
            
            let requestBody: [String: Any] = [
                "model": "qwen-turbo",
                "input": [
                    "messages": [
                        [
                            "role": "user",
                            "content": prompt
                        ]
                    ]
                ],
                "parameters": [
                    "temperature": 0.4,
                    "top_p": 0.8,
                    "max_tokens": 2000
                ]
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                print("📦 请求体已序列化")
            } catch {
                print("❌ 请求体序列化失败: \(error.localizedDescription)")
                promise(.failure(error))
                return
            }
            
            // 执行请求
            print("🚀 开始发送API请求...")
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ 网络请求失败: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 HTTP状态码: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode != 200 {
                        if let data = data, let errorBody = String(data: data, encoding: .utf8) {
                            print("❌ API返回错误: \(errorBody)")
                        }
                        
                        let error = NSError(domain: "AIAnalysisService", code: httpResponse.statusCode, 
                                           userInfo: [NSLocalizedDescriptionKey: "API请求失败，状态码: \(httpResponse.statusCode)"])
                        promise(.failure(error))
                        return
                    }
                }
                
                guard let data = data else {
                    let error = NSError(domain: "AIAnalysisService", code: 500, userInfo: [NSLocalizedDescriptionKey: "没有返回数据"])
                    print("❌ 没有返回数据")
                    promise(.failure(error))
                    return
                }
                
                print("📥 收到API响应数据: \(data.count) 字节")
                
                do {
                    // 尝试解析完整响应用于调试
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                       let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        print("📄 完整响应: \(jsonString)")
                    }
                    
                    // 解析返回的JSON
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let output = json["output"] as? [String: Any],
                       let choices = output["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        
                        print("📄 通义千问返回文本: \(content)")
                        
                        // 尝试提取JSON
                        if // 使用多种方法解析JSON
                        // 方法1: 直接尝试整个内容
                        if let jsonData = content.data(using: .utf8),
                           let contentJson = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                           let stepsArray = contentJson["steps"] as? [[String: String]] {
                            var goalSteps: [GoalStep] = []
                            for (index, step) in stepsArray.enumerated() {
                                if let title = step["title"], let description = step["description"] {
                                    let goalStep = GoalStep(title: title, description: description, order: index)
                                    goalSteps.append(goalStep)
                                }
                            }
                            if !goalSteps.isEmpty {
                                print("✅ 直接从内容中解析JSON成功")
                                promise(.success(goalSteps))
                                return
                            }
                        }
                        
                        // 方法2: 查找花括号提取JSON
                        let jsonStartIndex = content.range(of: "{")?.lowerBound,
                           let jsonEndIndex = content.range(of: "}", options: .backwards)?.upperBound {
                            
                            let jsonString = String(content[jsonStartIndex..<jsonEndIndex])
                            print("📋 提取的JSON字符串: \(jsonString)")
                            
                            guard let jsonData = jsonString.data(using: .utf8) else {
                                print("❌ 无法将JSON字符串转换为数据")
                                let steps = self.generateSimulatedSteps(for: title, description: description)
                                promise(.success(steps))
                                return
                            }
                            
                            do {
                                if let stepsJson = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                   let stepsArray = stepsJson["steps"] as? [[String: String]] {
                                    
                                    print("✅ 成功解析步骤JSON，找到 \(stepsArray.count) 个步骤")
                                    
                                    // 转换为GoalStep对象
                                    var goalSteps: [GoalStep] = []
                                    for (index, step) in stepsArray.enumerated() {
                                        if let title = step["title"], let description = step["description"] {
                                            let goalStep = GoalStep(title: title, description: description, order: index)
                                            goalSteps.append(goalStep)
                                        }
                                    }
                                    
                                    if !goalSteps.isEmpty {
                                        print("✅ 成功创建 \(goalSteps.count) 个GoalStep对象")
                                        promise(.success(goalSteps))
                                        return
                                    } else {
                                        print("⚠️ 解析JSON成功但没有有效步骤，使用模拟数据")
                                    }
                                } else {
                                    print("⚠️ 未找到有效的steps数组，使用模拟数据")
                                }
                            } catch {
                                print("❌ JSON解析错误: \(error.localizedDescription)")
                            }
                        } else {
                            print("⚠️ 在响应中未找到JSON，使用模拟数据")
                        }
                    } else {
                        print("⚠️ 响应格式不符合预期，使用模拟数据")
                    }
                    
                    // 如果无法解析API返回结果，使用模拟数据
                    print("🤖 返回模拟生成的步骤")
                    let steps = self.generateSimulatedSteps(for: title, description: description)
                    promise(.success(steps))
                } catch {
                    print("❌ 数据处理错误: \(error.localizedDescription)")
                    promise(.failure(error))
                }
            }.resume()
        }.eraseToAnyPublisher()
    }
    
    // 模拟步骤生成（当API调用失败或未配置时使用）
    private func simulateStepGeneration(title: String, description: String) -> AnyPublisher<[GoalStep], Error> {
        return Future<[GoalStep], Error> { promise in
            // 模拟网络请求延迟
            DispatchQueue.global().asyncAfter(deadline: .now() + self.simulationDelay) {
                // 生成模拟步骤
                let steps = self.generateSimulatedSteps(for: title, description: description)
                promise(.success(steps))
            }
        }.eraseToAnyPublisher()
    }
    
    // 生成模拟步骤
    private func generateSimulatedSteps(for title: String, description: String) -> [GoalStep] {
        // 简单的分析逻辑，将标题分词
        let words = title.components(separatedBy: CharacterSet.alphanumerics.inverted)
                         .filter { !$0.isEmpty }
        
        // 生成3-5个步骤
        let stepCount = min(max(words.count, 3), 5)
        var steps: [GoalStep] = []
        
        // 针对不同类型的目标生成不同的步骤模板
        if title.contains("学习") || title.contains("研究") {
            steps = [
                GoalStep(title: "收集学习资料", description: "查找相关的书籍、课程和在线资源", order: 0),
                GoalStep(title: "制定学习计划", description: "规划每周学习时间和具体内容", order: 1),
                GoalStep(title: "深入学习核心概念", description: "专注于理解基础理论和关键知识点", order: 2),
                GoalStep(title: "实践与应用", description: "通过项目或练习巩固所学知识", order: 3),
                GoalStep(title: "复习与总结", description: "定期回顾所学内容，形成知识体系", order: 4)
            ]
        } else if title.contains("项目") || title.contains("开发") {
            steps = [
                GoalStep(title: "需求分析", description: "明确项目目标和具体需求", order: 0),
                GoalStep(title: "方案设计", description: "设计技术方案和实现路径", order: 1),
                GoalStep(title: "开发实现", description: "按计划进行编码和功能实现", order: 2),
                GoalStep(title: "测试与修复", description: "进行全面测试并修复发现的问题", order: 3),
                GoalStep(title: "部署上线", description: "将项目部署到生产环境并监控运行情况", order: 4)
            ]
        } else {
            // 通用步骤模板
            steps = [
                GoalStep(title: "分析目标需求", description: "明确目标的具体内容和预期结果", order: 0),
                GoalStep(title: "制定行动计划", description: "规划实现目标的具体步骤和时间节点", order: 1),
                GoalStep(title: "获取必要资源", description: "准备实现目标所需的工具、材料或信息", order: 2),
                GoalStep(title: "执行计划", description: "按照计划开展具体工作", order: 3),
                GoalStep(title: "评估与调整", description: "定期检查进度，根据情况调整计划", order: 4)
            ]
        }
        
        // 只返回需要的步骤数量
        return Array(steps.prefix(stepCount))
    }
    
    // 测试API密钥是否有效
    func testApiKey(completion: @escaping (Bool, String?) -> Void) {
        // 如果API密钥为空，直接返回失败
        if AIApiKeys.tongyiApiKey.isEmpty || AIApiKeys.tongyiApiKey == "YOUR_TONGYI_API_KEY" {
            completion(false, "API密钥未设置")
            return
        }
        
        let baseURL = "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation"
        
        guard let url = URL(string: baseURL) else {
            completion(false, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(AIApiKeys.tongyiApiKey)", forHTTPHeaderField: "Authorization")
        
        // 使用简单的提示词测试API
        let requestBody: [String: Any] = [
            "model": "qwen-turbo",
            "input": [
                "messages": [
                    [
                        "role": "user",
                        "content": "你好"
                    ]
                ]
            ],
            "parameters": [
                "temperature": 0.4,
                "max_tokens": 10
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(false, "请求准备失败: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, "网络错误: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    var errorMessage = "HTTP错误 \(httpResponse.statusCode)"
                    
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        errorMessage += ": \(responseString)"
                    }
                    
                    completion(false, errorMessage)
                    return
                }
            }
            
            completion(true, nil)
        }.resume()
    }
    
    // 设置API配置的方法
    func configureAPI(for modelType: AIModelType, apiKey: String) {
        self.currentModel = modelType
        
        // 根据模型类型保存API密钥
        switch modelType {
        case .aliTongyi:
            AIApiKeys.tongyiApiKey = apiKey
        default:
            // 其他模型的API密钥保存逻辑
            break
        }
    }
    
    // 切换模型的方法
    func switchModel(to modelType: AIModelType) {
        self.currentModel = modelType
    }
}

// 如需接入实际API，以下是各大模型接入指南：

/* 
百度文心一言接入指南：
1. 访问 https://cloud.baidu.com/product/wenxinworkshop 申请API权限
2. 获取API Key和Secret Key
3. 使用API文档中的示例代码进行接入

阿里通义千问接入指南：
1. 访问 https://tongyi.aliyun.com/ 申请API权限
2. 获取API Key
3. 按照开发文档进行API调用

讯飞星火认知接入指南：
1. 访问 https://xinghuo.xfyun.cn/ 申请账号
2. 获取AppID和API Key
3. 参考官方SDK进行接入

智谱ChatGLM接入指南：
1. 访问 https://open.bigmodel.cn/ 注册账号
2. 申请API权限并获取API Key
3. 按照开发文档接入API

Google Gemini接入指南：
1. 访问 https://aistudio.google.com/ 注册并创建API密钥
2. 使用gemini-2.0-flash模型进行内容生成
3. 按照API文档进行调用
*/ 