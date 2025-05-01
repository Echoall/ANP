import Foundation
import SwiftUI

struct Category: Identifiable, Codable {
    var id: UUID
    var name: String
    var color: String // 存储颜色的十六进制值
    var order: Int
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), name: String, color: String = "#007AFF", order: Int = 0, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.color = color
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
} 