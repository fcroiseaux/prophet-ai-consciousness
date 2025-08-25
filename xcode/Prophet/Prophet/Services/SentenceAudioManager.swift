import Foundation
import AVFoundation

class SentenceAudioManager: NSObject, ObservableObject {
    static let shared = SentenceAudioManager()
    
    @Published var isPlaying = false
    
    private var audioPlayers: [AVAudioPlayer] = []
    private var currentPlayerIndex = 0
    private var audioQueue: [(data: Data, completion: () -> Void)] = []
    private var isProcessing = false
    private var overallCompletion: (() -> Void)?
    private var allSentencesQueued = false
    
    override init() {
        super.init()
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    func startSentencePlayback(completion: @escaping () -> Void = {}) {
        overallCompletion = completion
        audioPlayers.removeAll()
        audioQueue.removeAll()
        currentPlayerIndex = 0
        isPlaying = true
        isProcessing = false
        allSentencesQueued = false
    }
    
    func queueAudioData(_ data: Data, completion: @escaping () -> Void = {}) {
        audioQueue.append((data: data, completion: completion))
        
        // Start processing if not already doing so
        if !isProcessing {
            processNextInQueue()
        }
    }
    
    private func processNextInQueue() {
        guard !audioQueue.isEmpty else {
            isProcessing = false
            
            // Check if all audio has finished playing AND all sentences have been queued
            if allSentencesQueued && currentPlayerIndex >= audioPlayers.count {
                isPlaying = false
                overallCompletion?()
                overallCompletion = nil
            }
            return
        }
        
        isProcessing = true
        let (audioData, completion) = audioQueue.removeFirst()
        
        // Create audio player
        do {
            let player = try AVAudioPlayer(data: audioData)
            player.delegate = self
            player.prepareToPlay()
            audioPlayers.append(player)
            
            // If this is the first player or previous one finished, start playing immediately
            if audioPlayers.count == 1 || currentPlayerIndex == audioPlayers.count - 2 {
                playNext()
            }
            
            completion()
        } catch {
            print("Failed to create audio player: \(error)")
            completion()
        }
        
        // Process next item
        processNextInQueue()
    }
    
    private func playNext() {
        guard currentPlayerIndex < audioPlayers.count else {
            // All done
            isPlaying = false
            overallCompletion?()
            return
        }
        
        let player = audioPlayers[currentPlayerIndex]
        player.play()
        print("SentenceAudioManager: Playing sentence \(currentPlayerIndex + 1) of \(audioPlayers.count)")
    }
    
    func stopAllAudio() {
        audioQueue.removeAll()
        
        for player in audioPlayers {
            player.stop()
        }
        
        audioPlayers.removeAll()
        currentPlayerIndex = 0
        isPlaying = false
        isProcessing = false
        allSentencesQueued = false
        overallCompletion?()
        overallCompletion = nil
    }
    
    func markAllSentencesQueued() {
        allSentencesQueued = true
        
        // Check if we're already done
        if audioQueue.isEmpty && currentPlayerIndex >= audioPlayers.count {
            isPlaying = false
            overallCompletion?()
            overallCompletion = nil
        }
    }
}

extension SentenceAudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        currentPlayerIndex += 1
        
        // Play next audio if available
        if currentPlayerIndex < audioPlayers.count {
            playNext()
        } else if audioQueue.isEmpty && allSentencesQueued {
            // All done
            isPlaying = false
            overallCompletion?()
            overallCompletion = nil
        }
        // If queue is not empty, we'll play the next one when it's ready
    }
}