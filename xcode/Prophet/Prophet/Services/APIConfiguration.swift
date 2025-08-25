import Foundation

struct APIConfiguration {
    static let openAIBaseURL = "https://api.openai.com/v1"
    static let elevenLabsBaseURL = "https://api.elevenlabs.io/v1"
    
    // API Keys loaded from generated config file (xcconfig values) with fallback to UserDefaults
    static var openAIAPIKey: String {
        // First try to get from generated config file (build-time substituted from xcconfig)
        let configKey = GeneratedAPIConfig.openAIAPIKey
        if !configKey.isEmpty && configKey != "$(OPENAI_API_KEY)" {
            return configKey
        }
        // Fallback to UserDefaults
        return UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    }
    
    static var elevenLabsAPIKey: String {
        // First try to get from generated config file (build-time substituted from xcconfig)
        let configKey = GeneratedAPIConfig.elevenLabsAPIKey
        if !configKey.isEmpty && configKey != "$(ELEVENLABS_API_KEY)" {
            return configKey
        }
        // Fallback to UserDefaults
        return UserDefaults.standard.string(forKey: "elevenlabs_api_key") ?? ""
    }
    
    static func setOpenAIAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "openai_api_key")
    }
    
    static func setElevenLabsAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "elevenlabs_api_key")
    }
    
    static var useStreaming: Bool {
        UserDefaults.standard.bool(forKey: "use_streaming")
    }
    
    static func setUseStreaming(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "use_streaming")
    }
    
    static var selectedLanguage: String {
        UserDefaults.standard.string(forKey: "selected_language") ?? "English"
    }
    
    static func setSelectedLanguage(_ language: String) {
        UserDefaults.standard.set(language, forKey: "selected_language")
    }
    
    // Debug function to verify configuration is working
    static func debugAPIConfiguration() {
        print("=== API Configuration Debug ===")
        print("OpenAI API Key: \(openAIAPIKey.isEmpty ? "NOT SET" : "SET (\(openAIAPIKey.count) chars)")")
        print("ElevenLabs API Key: \(elevenLabsAPIKey.isEmpty ? "NOT SET" : "SET (\(elevenLabsAPIKey.count) chars)")")
        print("OpenAI Base URL: \(openAIBaseURL)")
        print("ElevenLabs Base URL: \(elevenLabsBaseURL)")
        print("Generated Config - OpenAI: \(GeneratedAPIConfig.openAIAPIKey.isEmpty ? "NOT SET" : "SET")")
        print("Generated Config - ElevenLabs: \(GeneratedAPIConfig.elevenLabsAPIKey.isEmpty ? "NOT SET" : "SET")")
        print("==============================")
    }
}