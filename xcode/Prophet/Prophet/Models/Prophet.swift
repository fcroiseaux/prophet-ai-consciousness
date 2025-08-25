import Foundation

struct Prophet: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var systemPrompt: String
    var elevenLabsVoiceId: String
    var iconName: String?
    var voiceSpeed: Double
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, systemPrompt: String, elevenLabsVoiceId: String, iconName: String? = nil, voiceSpeed: Double = 1.0) {
        self.id = UUID()
        self.name = name
        self.systemPrompt = systemPrompt
        self.elevenLabsVoiceId = elevenLabsVoiceId
        self.iconName = iconName
        self.voiceSpeed = voiceSpeed
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, systemPrompt, elevenLabsVoiceId, iconName, voiceSpeed, createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        systemPrompt = try container.decode(String.self, forKey: .systemPrompt)
        elevenLabsVoiceId = try container.decode(String.self, forKey: .elevenLabsVoiceId)
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName)
        voiceSpeed = try container.decodeIfPresent(Double.self, forKey: .voiceSpeed) ?? 1.0
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}