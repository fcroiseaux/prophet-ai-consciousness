import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var selectedProphet: Prophet?
    @Published var isProcessing = false
    @Published var prophets: [Prophet] = []
    
    private let prophetStore = ProphetStore.shared
    private let openAIService = OpenAIService.shared
    private let elevenLabsService = ElevenLabsService.shared
    private let audioManager = AudioManager.shared
    
    init() {
        prophets = prophetStore.prophets
    }
    
    func selectProphet(_ prophet: Prophet) {
        selectedProphet = prophet
        messages = []
    }
    
    func sendMessage(_ content: String) async {
        guard let prophet = selectedProphet else { return }
        
        let userMessage = Message(content: content, isUser: true)
        messages.append(userMessage)
        
        isProcessing = true
        
        do {
            let response = try await openAIService.sendMessage(content, prophet: prophet, history: messages)
            
            let prophetMessage = Message(content: response, prophetId: prophet.id, isUser: false)
            messages.append(prophetMessage)
            
            let audioData = try await elevenLabsService.textToSpeech(text: response, voiceId: prophet.elevenLabsVoiceId)
            
            await MainActor.run {
                audioManager.playAudio(data: audioData, speed: prophet.voiceSpeed)
            }
        } catch {
            print("Error: \(error)")
            let errorMessage = Message(content: "Error: \(error.localizedDescription)", isUser: false)
            messages.append(errorMessage)
        }
        
        isProcessing = false
    }
}