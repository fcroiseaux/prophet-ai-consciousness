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
    private let sentenceAudioManager = SentenceAudioManager.shared
    
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
            
            // Check if streaming is enabled
            if APIConfiguration.useStreaming {
                // Use streaming audio with sentence splitting
                await playStreamingAudio(text: response, prophet: prophet)
            } else {
                // Use traditional single audio file
                let audioData = try await elevenLabsService.textToSpeech(text: response, voiceId: prophet.elevenLabsVoiceId)
                
                await MainActor.run {
                    audioManager.playAudio(data: audioData, speed: prophet.voiceSpeed)
                }
            }
        } catch {
            print("Error: \(error)")
            let errorMessage = Message(content: "Error: \(error.localizedDescription)", isUser: false)
            messages.append(errorMessage)
        }
        
        isProcessing = false
    }
    
    private func playStreamingAudio(text: String, prophet: Prophet) async {
        // Split text into sentences
        let sentences = TextSplitter.splitIntoSentences(text)
        
        guard !sentences.isEmpty else { return }
        
        print("ChatViewModel: Starting streaming audio for \(sentences.count) sentences")
        
        // Start the sentence audio manager
        sentenceAudioManager.startSentencePlayback {
            print("ChatViewModel: Finished playing all sentences")
        }
        
        // Process each sentence
        for (index, sentence) in sentences.enumerated() {
            do {
                print("ChatViewModel: Processing sentence \(index + 1): \(sentence)")
                
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
                
                print("ChatViewModel: Completed streaming for sentence \(index + 1)")
                
            } catch {
                print("ChatViewModel: Error processing sentence \(index + 1): \(error)")
                // Continue with next sentence even if one fails
            }
        }
        
        // Mark all sentences as queued
        sentenceAudioManager.markAllSentencesQueued()
    }
}