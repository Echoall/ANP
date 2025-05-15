import Foundation

struct ChatMessage: Identifiable, Codable {
    var id: UUID
    var content: String
    var timestamp: Date
    var isFromUser: Bool
    var requiresConfirmation: Bool
    
    init(id: UUID = UUID(),
         content: String,
         timestamp: Date = Date(),
         isFromUser: Bool,
         requiresConfirmation: Bool = false) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isFromUser = isFromUser
        self.requiresConfirmation = requiresConfirmation
    }
} 