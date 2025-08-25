import Foundation
import AVFoundation

class ElevenLabsService: NSObject {
    static let shared = ElevenLabsService()
    
    private override init() {
        super.init()
    }
    
    struct TextToSpeechRequest: Codable {
        let text: String
        let voice_settings: VoiceSettings
        let optimize_streaming_latency: Int?
        
        struct VoiceSettings: Codable {
            let stability: Double
            let similarity_boost: Double
            
            init(stability: Double = 0.5, similarity_boost: Double = 0.5) {
                self.stability = stability
                self.similarity_boost = similarity_boost
            }
        }
    }
    
    func getVoices() async throws -> [ElevenLabsVoice] {
        guard !APIConfiguration.elevenLabsAPIKey.isEmpty else {
            throw APIError.missingAPIKey
        }
        
        guard let url = URL(string: "\(APIConfiguration.elevenLabsBaseURL)/voices") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(APIConfiguration.elevenLabsAPIKey, forHTTPHeaderField: "xi-api-key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed
        }
        
        let voicesResponse = try JSONDecoder().decode(ElevenLabsVoicesResponse.self, from: data)
        return voicesResponse.voices
    }
    
    func textToSpeech(text: String, voiceId: String) async throws -> Data {
        guard !APIConfiguration.elevenLabsAPIKey.isEmpty else {
            throw APIError.missingAPIKey
        }
        
        guard let url = URL(string: "\(APIConfiguration.elevenLabsBaseURL)/text-to-speech/\(voiceId)") else {
            throw APIError.invalidURL
        }
        
        let requestBody = TextToSpeechRequest(
            text: text,
            voice_settings: TextToSpeechRequest.VoiceSettings(),
            optimize_streaming_latency: nil
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(APIConfiguration.elevenLabsAPIKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed
        }
        
        return data
    }
    
    func textToSpeechStream(text: String, voiceId: String, onDataReceived: @escaping (Data) -> Void) async throws {
        guard !APIConfiguration.elevenLabsAPIKey.isEmpty else {
            throw APIError.missingAPIKey
        }
        
        guard let url = URL(string: "\(APIConfiguration.elevenLabsBaseURL)/text-to-speech/\(voiceId)/stream") else {
            throw APIError.invalidURL
        }
        
        print("=== ElevenLabs Stream Request ===")
        print("URL: \(url)")
        print("Voice ID: \(voiceId)")
        print("Text length: \(text.count)")
        
        let requestBody = TextToSpeechRequest(
            text: text,
            voice_settings: TextToSpeechRequest.VoiceSettings(),
            optimize_streaming_latency: 4 // Optimize for low latency
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(APIConfiguration.elevenLabsAPIKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // Store the callback for the delegate
        self.streamDataHandler = onDataReceived
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request)
            self.currentStreamTask = task
            self.streamContinuation = continuation
            task.resume()
        }
    }
    
    private var streamContinuation: CheckedContinuation<Void, Error>?
    
    private var streamDataHandler: ((Data) -> Void)?
    private var currentStreamTask: URLSessionDataTask?
}

extension ElevenLabsService: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // This is called as chunks arrive
        print("Received audio chunk: \(data.count) bytes")
        streamDataHandler?(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("Stream completed. Error: \(error?.localizedDescription ?? "none")")
        
        if let error = error {
            streamContinuation?.resume(throwing: error)
        } else {
            streamContinuation?.resume()
        }
        
        streamDataHandler = nil
        currentStreamTask = nil
        streamContinuation = nil
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let httpResponse = response as? HTTPURLResponse {
            print("Stream response received. Status: \(httpResponse.statusCode)")
            if (200...299).contains(httpResponse.statusCode) {
                completionHandler(.allow)
            } else {
                completionHandler(.cancel)
                streamContinuation?.resume(throwing: APIError.requestFailed)
            }
        } else {
            completionHandler(.allow)
        }
    }
}