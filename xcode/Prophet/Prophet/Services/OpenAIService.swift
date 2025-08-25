import Foundation

class OpenAIService {
    static let shared = OpenAIService()
    
    private init() {}
    
    struct ChatCompletionRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let temperature: Double
        let max_tokens: Int?
        let presence_penalty: Double?
        let frequency_penalty: Double?
    }
    
    struct ChatMessage: Codable {
        let role: String
        let content: String
    }
    
    struct ChatCompletionResponse: Codable {
        let choices: [Choice]
        
        struct Choice: Codable {
            let message: ChatMessage
            let finish_reason: String?
        }
    }
    
    func sendMessage(_ content: String, prophet: Prophet, history: [Message], isInitialPrompt: Bool = false) async throws -> String {
        guard !APIConfiguration.openAIAPIKey.isEmpty else {
            throw APIError.missingAPIKey
        }
        
        var messages: [ChatMessage] = []
        
        // Get the selected language
        let selectedLanguage = APIConfiguration.selectedLanguage
        let languageInstruction = selectedLanguage != "English" ? " Always respond in \(selectedLanguage)." : ""
        
        if isInitialPrompt {
            // For initial prompt, send it as a user message with language instruction
            messages.append(ChatMessage(role: "user", content: content + languageInstruction))
        } else {
            // For regular messages, use a minimal system prompt with language instruction
            messages.append(ChatMessage(role: "system", content: "You are \(prophet.name). Respond in character based on your previous responses.\(languageInstruction)"))
            
            // Include conversation history
            for message in history {
                let role = message.isUser ? "user" : "assistant"
                messages.append(ChatMessage(role: role, content: message.content))
            }
            
            messages.append(ChatMessage(role: "user", content: content))
        }
        
        let request = ChatCompletionRequest(
            model: "gpt-4o", 
            messages: messages,
            temperature: 1.0, // Changed from 0.7 to match ChatGPT default
            max_tokens: nil, // Remove limit to allow full responses
            presence_penalty: 0.0,
            frequency_penalty: 0.0
        )
        
        guard let url = URL(string: "\(APIConfiguration.openAIBaseURL)/chat/completions") else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(APIConfiguration.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        // Log the API request
        print("=== OpenAI API Request ===")
        print("URL: \(url)")
        print("Model: \(request.model)")
        print("Temperature: \(request.temperature)")
        print("Max Tokens: \(request.max_tokens ?? -1)")
        print("Messages:")
        for (index, message) in messages.enumerated() {
            print("  [\(index)] Role: \(message.role)")
            print("       Content: \(String(message.content.prefix(200)))\(message.content.count > 200 ? "..." : "")")
        }
        if let requestBody = urlRequest.httpBody,
           let jsonString = String(data: requestBody, encoding: .utf8) {
            print("Full Request Body:")
            print(jsonString)
        }
        print("=========================")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("=== OpenAI API Error ===")
            print("Status Code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            if let errorData = String(data: data, encoding: .utf8) {
                print("Error Response: \(errorData)")
            }
            print("========================")
            throw APIError.requestFailed
        }
        
        // Log the response
        print("=== OpenAI API Response ===")
        print("Status Code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response (first 500 chars): \(String(responseString.prefix(500)))\(responseString.count > 500 ? "..." : "")")
        }
        
        let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let firstChoice = chatResponse.choices.first else {
            throw APIError.noResponse
        }
        
        print("Finish Reason: \(firstChoice.finish_reason ?? "none")")
        print("Response Content: \(String(firstChoice.message.content.prefix(200)))\(firstChoice.message.content.count > 200 ? "..." : "")")
        print("===========================")
        
        return firstChoice.message.content
    }
}

enum APIError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case requestFailed
    case noResponse
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key is missing. Please set it in Settings."
        case .invalidURL:
            return "Invalid API URL"
        case .requestFailed:
            return "API request failed"
        case .noResponse:
            return "No response from API"
        }
    }
}
