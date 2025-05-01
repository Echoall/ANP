import Foundation
import Combine

// 简化后的AI服务错误类型
enum AIServiceError: Error {
    case genericError
}

// 增加步骤建议模型（保留）
struct StepSuggestion {
    let id = UUID()
    let title: String
    let description: String
    let order: Int
}

// 简化后的服务类
class AIAnalysisService {
    static let shared = AIAnalysisService()
    
    private init() {}
    
    // 分析任务并提供步骤建议（只返回模拟数据）
    func analyzeTask(title: String, description: String) -> AnyPublisher<[StepSuggestion], Error> {
        print("🤖 正在处理任务: \(title)")
        return simulateStepGeneration()
    }
    
    // 模拟步骤生成
    private func simulateStepGeneration() -> AnyPublisher<[StepSuggestion], Error> {
        return Future<[StepSuggestion], Error> { promise in
            // 模拟处理延迟
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // 生成默认步骤
                let steps = [
                    StepSuggestion(title: "分析任务需求", description: "仔细阅读任务描述，明确目标和期望结果。确定任务的优先级和截止日期。", order: 0),
                    StepSuggestion(title: "收集必要资源", description: "确定完成任务所需的人力、物力和信息资源。收集相关参考资料和工具。", order: 1),
                    StepSuggestion(title: "制定详细计划", description: "将任务分解为更小的子任务，设定每个子任务的时间节点。考虑可能的风险和应对策略。", order: 2),
                    StepSuggestion(title: "执行核心步骤", description: "按照计划有条不紊地执行各项子任务。及时记录进展情况，遇到问题及时调整方案。", order: 3),
                    StepSuggestion(title: "评估完成情况", description: "回顾整个任务过程，检查是否达到了预期目标。总结经验教训，为今后类似任务做准备。", order: 4)
                ]
                
                promise(.success(steps))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // 简单分析任务名称（不使用AI，只做文字处理）
    func analyzeTaskName(_ taskName: String) -> [String] {
        let keywords = taskName.components(separatedBy: " ")
            .filter { $0.count > 1 } // 过滤掉单个字符
        
        guard !keywords.isEmpty else {
            return ["任务", "计划", "目标"]
        }
        
        return Array(keywords.prefix(3)) // 最多返回3个关键词
    }
}
