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
    private let sentenceAudioManager = SentenceAudioManager.shared
    
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
                
                // Add to prophet1's history as their own message
                prophet1History.append(Message(content: subject, isUser: true))
                prophet1History.append(Message(content: prophet1InitialResponse, isUser: false))
                
                // Add to prophet2's history as a user message
                prophet2History.append(Message(content: prophet1InitialResponse, isUser: true))
                
                // Start parallel generation and audio system
                try await runParallelConversation(
                    initialP1Response: prophet1InitialResponse,
                    prophet1: p1,
                    prophet2: p2
                )
                
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
        }
    }
    
    private func runParallelConversation(
        initialP1Response: String,
        prophet1: Prophet,
        prophet2: Prophet
    ) async throws {
        var prophet1LastResponse = initialP1Response
        var prophet2LastResponse = ""
        var currentProphet = 1 // Start with prophet1 speaking first
        
        // Start with prophet1 playing audio and prophet2 generating response in parallel
        while isConversationActive && !Task.isCancelled {
            try Task.checkCancellation()
            
            if currentProphet == 1 {
                // Prophet 1 is speaking, Prophet 2 should generate next response
                let inputForP2 = prophet1LastResponse // Create immutable copy
                async let prophet2ResponseTask = generateProphetResponse(
                    input: inputForP2,
                    prophet: prophet2,
                    history: prophet2History
                )
                
                // Play Prophet 1's audio
                await playProphetAudio(text: prophet1LastResponse, prophet: prophet1)
                
                // Wait for Prophet 2's response to be ready
                guard let prophet2Response = try await prophet2ResponseTask else {
                    break // Error or cancellation in generation
                }
                
                prophet2LastResponse = prophet2Response
                
                // Add pause between speakers
                guard isConversationActive && !Task.isCancelled else { break }
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second pause
                
                currentProphet = 2 // Switch to prophet2 speaking
                
            } else {
                // Prophet 2 is speaking, Prophet 1 should generate next response
                let inputForP1 = prophet2LastResponse // Create immutable copy
                async let prophet1ResponseTask = generateProphetResponse(
                    input: inputForP1,
                    prophet: prophet1,
                    history: prophet1History
                )
                
                // Play Prophet 2's audio
                await playProphetAudio(text: prophet2LastResponse, prophet: prophet2)
                
                // Wait for Prophet 1's response to be ready
                guard let prophet1Response = try await prophet1ResponseTask else {
                    break // Error or cancellation in generation
                }
                
                prophet1LastResponse = prophet1Response
                
                // Add pause between speakers
                guard isConversationActive && !Task.isCancelled else { break }
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second pause
                
                currentProphet = 1 // Switch to prophet1 speaking
            }
        }
    }
    
    private func generateProphetResponse(
        input: String,
        prophet: Prophet,
        history: [Message]
    ) async throws -> String? {
        do {
            try Task.checkCancellation()
            
            let response = try await openAIService.sendMessage(
                input,
                prophet: prophet,
                history: history
            )
            
            guard isConversationActive && !Task.isCancelled else { return nil }
            
            let message = Message(
                content: response,
                prophetId: prophet.id,
                isUser: false
            )
            
            await MainActor.run {
                messages.append(message)
            }
            
            // Update histories based on which prophet responded
            if prophet.id == prophet1?.id {
                prophet1History.append(Message(content: response, isUser: false))
                prophet2History.append(Message(content: response, isUser: true))
            } else {
                prophet2History.append(Message(content: response, isUser: false))
                prophet1History.append(Message(content: response, isUser: true))
            }
            
            return response
            
        } catch is CancellationError {
            print("Response generation was cancelled for \(prophet.name)")
            return nil
        } catch {
            await MainActor.run {
                isConversationActive = false
                
                // Ignore network cancellation errors silently
                if !isNetworkCancellationError(error) {
                    print("Error generating response for \(prophet.name): \(error)")
                    if let apiError = error as? APIError {
                        errorMessage = apiError.localizedDescription
                    } else {
                        errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                    }
                }
            }
            return nil
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
        sentenceAudioManager.stopAllAudio()
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
    
    private func playProphetAudio(text: String, prophet: Prophet) async {
        // Check if streaming is enabled
        if APIConfiguration.useStreaming {
            // Use streaming audio with sentence splitting
            await playStreamingAudio(text: text, prophet: prophet)
        } else {
            // Use traditional single audio file
            do {
                let audioData = try await elevenLabsService.textToSpeech(text: text, voiceId: prophet.elevenLabsVoiceId)
                
                // Wait for audio to complete using withCheckedContinuation
                await withCheckedContinuation { continuation in
                    Task { @MainActor in
                        audioManager.playAudio(data: audioData, speed: prophet.voiceSpeed) {
                            continuation.resume()
                        }
                    }
                }
            } catch {
                print("DualChatViewModel: Error generating audio for \(prophet.name): \(error)")
            }
        }
    }
    
    private func playStreamingAudio(text: String, prophet: Prophet) async {
        // Split text into sentences
        let sentences = TextSplitter.splitIntoSentences(text)
        
        guard !sentences.isEmpty else { return }
        
        print("DualChatViewModel: Starting streaming audio for \(prophet.name) - \(sentences.count) sentences")
        
        // Wait for all streaming audio to complete using withCheckedContinuation
        await withCheckedContinuation { continuation in
            // Start the sentence audio manager with completion handler
            sentenceAudioManager.startSentencePlayback {
                print("DualChatViewModel: Finished playing all sentences for \(prophet.name)")
                continuation.resume()
            }
            
            // Process each sentence in a background task
            Task {
                // Process each sentence
                for (index, sentence) in sentences.enumerated() {
                    // Check if conversation is still active before processing each sentence
                    guard isConversationActive && !Task.isCancelled else {
                        print("DualChatViewModel: Conversation cancelled during streaming")
                        await MainActor.run {
                            sentenceAudioManager.stopAllAudio()
                        }
                        return
                    }
                    
                    do {
                        print("DualChatViewModel: Processing sentence \(index + 1) for \(prophet.name): \(sentence)")
                        
                        // Use streaming TTS for each sentence
                        try await elevenLabsService.textToSpeechStream(
                            text: sentence,
                            voiceId: prophet.elevenLabsVoiceId
                        ) { audioData in
                            // Queue each audio chunk as it arrives
                            Task { @MainActor in
                                self.sentenceAudioManager.queueAudioData(audioData)
                            }
                        }
                        
                        print("DualChatViewModel: Completed streaming for sentence \(index + 1) for \(prophet.name)")
                        
                    } catch {
                        print("DualChatViewModel: Error processing sentence \(index + 1) for \(prophet.name): \(error)")
                        // Continue with next sentence even if one fails
                    }
                }
                
                // Mark all sentences as queued
                await MainActor.run {
                    sentenceAudioManager.markAllSentencesQueued()
                }
            }
        }
    }
}