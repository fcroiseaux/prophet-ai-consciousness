import Foundation

struct ElevenLabsVoice: Identifiable, Codable, Hashable {
    let voice_id: String
    let name: String
    let category: String?
    let labels: [String: String]?
    
    var id: String { voice_id }
}

struct ElevenLabsVoicesResponse: Codable {
    let voices: [ElevenLabsVoice]
}