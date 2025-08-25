import Foundation

struct JSONProphet: Codable {
    let name: String
    let prompt: String
    let voiceId: String?
    let iconName: String?
}

struct JSONProphetsFile: Codable {
    let prophets: [JSONProphet]
}

class JSONLoader {
    static func loadProphetsFromBundle() -> [JSONProphet]? {
        guard let url = Bundle.main.url(forResource: "prophets", withExtension: "json") else {
            print("Could not find prophets.json in bundle")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let prophetsFile = try JSONDecoder().decode(JSONProphetsFile.self, from: data)
            return prophetsFile.prophets
        } catch {
            print("Error loading prophets.json: \(error)")
            return nil
        }
    }
}