import Foundation

struct Message: Identifiable, Hashable {
    let id: UUID
    let content: String
    let prophetId: UUID?
    let timestamp: Date
    let isUser: Bool
    
    init(content: String, prophetId: UUID? = nil, isUser: Bool = false) {
        self.id = UUID()
        self.content = content
        self.prophetId = prophetId
        self.timestamp = Date()
        self.isUser = isUser
    }
}