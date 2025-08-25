import Foundation
import SwiftUI

@MainActor
class ProphetStore: ObservableObject {
    static let shared = ProphetStore()
    
    @Published var prophets: [Prophet] = []
    
    private let userDefaults = UserDefaults.standard
    private let prophetsKey = "saved_prophets"
    
    private init() {
        loadProphets()
    }
    
    func loadProphets() {
        guard let data = userDefaults.data(forKey: prophetsKey),
              let decodedProphets = try? JSONDecoder().decode([Prophet].self, from: data) else {
            // If no prophets in storage, initialize from JSON
            reinitializeFromJSON()
            return
        }
        prophets = decodedProphets
    }
    
    func saveProphets() {
        guard let data = try? JSONEncoder().encode(prophets) else { return }
        userDefaults.set(data, forKey: prophetsKey)
    }
    
    func addProphet(_ prophet: Prophet) {
        prophets.append(prophet)
        saveProphets()
    }
    
    func updateProphet(_ prophet: Prophet) {
        if let index = prophets.firstIndex(where: { $0.id == prophet.id }) {
            prophets[index] = prophet
            saveProphets()
        }
    }
    
    func deleteProphets(at offsets: IndexSet) {
        prophets.remove(atOffsets: offsets)
        saveProphets()
    }
    
    func reinitializeFromJSON() {
        guard let jsonProphets = JSONLoader.loadProphetsFromBundle() else {
            print("Failed to load prophets from JSON")
            return
        }
        
        print("Loading \(jsonProphets.count) prophets from JSON")
        
        // Create new prophets from JSON data
        // Use voiceId from JSON if available, otherwise use default
        let defaultVoiceId = "qz2CR9kDYsCbfTZ1lwy5" // Default voice for prophets without voiceId
        
        var newProphets: [Prophet] = []
        for jsonProphet in jsonProphets {
            // Select appropriate icon based on prophet name/tradition
            let iconName = jsonProphet.iconName ?? selectIconForProphet(jsonProphet.name)
            
            let prophet = Prophet(
                name: jsonProphet.name,
                systemPrompt: jsonProphet.prompt,
                elevenLabsVoiceId: jsonProphet.voiceId ?? defaultVoiceId,
                iconName: iconName,
                voiceSpeed: 1.0
            )
            newProphets.append(prophet)
        }
        
        // Update prophets array in one operation to trigger proper UI update
        prophets = newProphets
        saveProphets()
        
        print("Successfully loaded \(prophets.count) prophets")
    }
    
    private func selectIconForProphet(_ name: String) -> String {
        switch name {
        case "J", "Jesus":
            return "flame.fill" // Represents divine light, Gospel of John's light theme
        case "Ged Anen":
            return "eye.fill" // Represents seeing, awareness, mystical vision
        case "Maitre Eckhart", "Meister Eckhart":
            return "sparkles" // Christian mysticism, divine spark
        case "Krishnamurti":
            return "brain.head.profile" // Philosophy, mind, consciousness
        case "Nisagardatta Maharaj", "Nisargadatta Maharaj":
            return "sun.max.fill" // Hindu/Advaita tradition, consciousness as light
        case "Marc Aurèle", "Marcus Aurelius":
            return "bolt.fill" // Stoicism, strength, Roman power
        case "Epicure", "Epicurus":
            return "leaf.fill" // Garden philosophy, natural pleasure
        case "Bouddha", "Buddha":
            return "moon.stars.fill" // Enlightenment, meditation, peace
        default:
            return "person.circle.fill"
        }
    }
}