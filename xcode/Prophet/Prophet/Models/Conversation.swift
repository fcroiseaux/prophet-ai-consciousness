import Foundation

struct Conversation: Identifiable {
    let id: UUID
    var messages: [Message]
    var participantIds: [UUID]
    var createdAt: Date
    var subject: String?
    
    init(participantIds: [UUID], subject: String? = nil) {
        self.id = UUID()
        self.messages = []
        self.participantIds = participantIds
        self.createdAt = Date()
        self.subject = subject
    }
}