import Foundation

enum SortOption: String, CaseIterable {
    case dueDate = "截止日期"
    case priority = "优先级"
    case createdAt = "创建时间"
    case title = "标题"
    
    var displayName: String {
        return self.rawValue
    }
} 