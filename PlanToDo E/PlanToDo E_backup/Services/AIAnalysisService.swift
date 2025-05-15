import Foundation
import Combine

// 简化后的AI服务错误类型
enum AIServiceError: Error {
    case genericError
}

// 简化后的服务类
class AIAnalysisService {
    static let shared = AIAnalysisService()
    
    private init() {}
    
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
