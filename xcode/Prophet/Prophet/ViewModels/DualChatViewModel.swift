import Foundation
import SwiftUI

@MainActor
class DualChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var prophet1: Prophet?
    @Published var prophet2: Prophet?
    @Published var isConversationActive = false
    @Published var prophets: [Prophet] = []
    @Published var errorMessage: String?
    
    private let prophetStore = ProphetStore.shared
    private let openAIService = OpenAIService.shared
    private let elevenLabsService = ElevenLabsService.shared
    private let audioManager = AudioManager.shared
    
    private var conversationTask: Task<Void, Never>?
    private var currentSpeaker = 0
    
    // Separate conversation histories for each prophet
    private var prophet1History: [Message] = []
    private var prophet2History: [Message] = []
    
    init() {
        prophets = prophetStore.prophets
        
        // Automatically preselect the first two prophets if available
        if prophets.count >= 2 {
            prophet1 = prophets[0]
            prophet2 = prophets[1]
        }
    }
    
    func getProphet(for message: Message) -> Prophet? {
        guard let prophetId = message.prophetId else { return nil }
        return [prophet1, prophet2].compactMap { $0 }.first { $0.id == prophetId }
    }
    
    func startConversation(subject: String) async {
        guard let p1 = prophet1, let p2 = prophet2 else { return }
        
        // Clear any previous error
        errorMessage = nil
        isConversationActive = true
        
        // Clear histories
        prophet1History = []
        prophet2History = []
        
        let initialMessage = Message(
            content: "Let's discuss: \(subject)",
            isUser: true
        )
        messages.append(initialMessage)
        
        conversationTask = Task {
            // Start both prophets with the initial subject
            var prophet1LastResponse = ""
            var prophet2LastResponse = ""
            
            // Get initial responses from both prophets
            do {
                // Check for cancellation
                try Task.checkCancellation()
                
                // Prophet 1's initial response to the subject
                let prophet1InitialResponse = try await openAIService.sendMessage(
                    subject,
                    prophet: p1,
                    history: prophet1History
                )
                
                // Check if conversation is still active
                guard isConversationActive && !Task.isCancelled else { return }
                
                let prophet1Message = Message(
                    content: prophet1InitialResponse,
                    prophetId: p1.id,
                    isUser: false
                )
                messages.append(prophet1Message)
                prophet1LastResponse = prophet1InitialResponse
                
                // Add to prophet1's history as their own message
                prophet1History.append(Message(content: subject, isUser: true))
                prophet1History.append(Message(content: prophet1InitialResponse, isUser: false))
                
                // Add to prophet2's history as a user message
                prophet2History.append(Message(content: prophet1InitialResponse, isUser: true))
                
                // Play prophet1's audio
                let audioData1 = try await elevenLabsService.textToSpeech(
                    text: prophet1InitialResponse,
                    voiceId: p1.elevenLabsVoiceId
                )
                
                guard isConversationActive && !Task.isCancelled else { return }
                
                await MainActor.run {
                    audioManager.playAudio(data: audioData1, speed: p1.voiceSpeed)
                }
                
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second pause
                
                guard isConversationActive && !Task.isCancelled else { return }
                
                // Prophet 2's response to prophet 1
                let prophet2InitialResponse = try await openAIService.sendMessage(
                    prophet1InitialResponse,
                    prophet: p2,
                    history: prophet2History
                )
                
                guard isConversationActive && !Task.isCancelled else { return }
                
                let prophet2Message = Message(
                    content: prophet2InitialResponse,
                    prophetId: p2.id,
                    isUser: false
                )
                messages.append(prophet2Message)
                prophet2LastResponse = prophet2InitialResponse
                
                // Add to prophet2's history as their own message
                prophet2History.append(Message(content: prophet2InitialResponse, isUser: false))
                
                // Add to prophet1's history as a user message
                prophet1History.append(Message(content: prophet2InitialResponse, isUser: true))
                
                // Play prophet2's audio
                let audioData2 = try await elevenLabsService.textToSpeech(
                    text: prophet2InitialResponse,
                    voiceId: p2.elevenLabsVoiceId
                )
                
                guard isConversationActive && !Task.isCancelled else { return }
                
                await MainActor.run {
                    audioManager.playAudio(data: audioData2, speed: p2.voiceSpeed)
                }
                
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second pause
                
            } catch is CancellationError {
                print("Initial conversation was cancelled")
                isConversationActive = false
                return
            } catch {
                isConversationActive = false
                
                // Ignore network cancellation errors (NSURLErrorDomain -999) silently
                if isNetworkCancellationError(error) {
                    return
                }
                
                print("Error in initial conversation: \(error)")
                if let apiError = error as? APIError {
                    errorMessage = apiError.localizedDescription
                } else {
                    errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                }
                return
            }
            
            // Continue the conversation
            currentSpeaker = 0 // Start with prophet1 again
            
            while isConversationActive && !Task.isCancelled {
                do {
                    // Check for cancellation before each major operation
                    try Task.checkCancellation()
                    
                    if currentSpeaker == 0 {
                        // Prophet 1's turn
                        let response = try await openAIService.sendMessage(
                            prophet2LastResponse,
                            prophet: p1,
                            history: prophet1History
                        )
                        
                        // Check if we're still active after the network call
                        guard isConversationActive && !Task.isCancelled else { break }
                        
                        let message = Message(
                            content: response,
                            prophetId: p1.id,
                            isUser: false
                        )
                        messages.append(message)
                        
                        // Update histories
                        prophet1History.append(Message(content: response, isUser: false))
                        prophet2History.append(Message(content: response, isUser: true))
                        
                        prophet1LastResponse = response
                        
                        let audioData = try await elevenLabsService.textToSpeech(
                            text: response,
                            voiceId: p1.elevenLabsVoiceId
                        )
                        
                        // Check again before playing audio
                        guard isConversationActive && !Task.isCancelled else { break }
                        
                        await MainActor.run {
                            audioManager.playAudio(data: audioData, speed: p1.voiceSpeed)
                        }
                    } else {
                        // Prophet 2's turn
                        let response = try await openAIService.sendMessage(
                            prophet1LastResponse,
                            prophet: p2,
                            history: prophet2History
                        )
                        
                        // Check if we're still active after the network call
                        guard isConversationActive && !Task.isCancelled else { break }
                        
                        let message = Message(
                            content: response,
                            prophetId: p2.id,
                            isUser: false
                        )
                        messages.append(message)
                        
                        // Update histories
                        prophet2History.append(Message(content: response, isUser: false))
                        prophet1History.append(Message(content: response, isUser: true))
                        
                        prophet2LastResponse = response
                        
                        let audioData = try await elevenLabsService.textToSpeech(
                            text: response,
                            voiceId: p2.elevenLabsVoiceId
                        )
                        
                        // Check again before playing audio
                        guard isConversationActive && !Task.isCancelled else { break }
                        
                        await MainActor.run {
                            audioManager.playAudio(data: audioData, speed: p2.voiceSpeed)
                        }
                    }
                    
                    // Switch speaker
                    currentSpeaker = 1 - currentSpeaker
                    
                    // Check before sleeping
                    guard isConversationActive && !Task.isCancelled else { break }
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second pause
                    
                } catch is CancellationError {
                    // Handle cancellation gracefully
                    print("Conversation was cancelled")
                    break
                } catch {
                    isConversationActive = false
                    
                    // Ignore network cancellation errors (NSURLErrorDomain -999) silently
                    if isNetworkCancellationError(error) {
                        break
                    }
                    
                    print("Error in conversation: \(error)")
                    if let apiError = error as? APIError {
                        errorMessage = apiError.localizedDescription
                    } else {
                        errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                    }
                    break
                }
            }
        }
    }
    
    func toggleConversation() {
        if isConversationActive {
            stopConversation()
        } else {
            guard prophet1 != nil, prophet2 != nil, !messages.isEmpty else { return }
            // Clear any previous error before restarting
            errorMessage = nil
            Task {
                await startConversation(subject: messages.first?.content ?? "Continue our discussion")
            }
        }
    }
    
    func stopConversation() {
        isConversationActive = false
        conversationTask?.cancel()
        conversationTask = nil
        audioManager.stopAllAudio()
    }
    
    func clearMessages() {
        messages = []
        prophet1History = []
        prophet2History = []
        currentSpeaker = 0
        errorMessage = nil
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // Helper function to check if an error is a cancelled network request
    private func isNetworkCancellationError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }
    
    // This function is no longer needed as we use the messages directly
}