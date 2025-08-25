import Foundation
import AVFoundation

class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    
    @Published var isPlaying = false
    private var audioPlayer: AVAudioPlayer?
    private var audioQueue: [(data: Data, completion: () -> Void)] = []
    private var currentCompletion: (() -> Void)?
    private var currentSpeed: Double = 1.0
    
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
    
    func playAudio(data: Data, speed: Double = 1.0, completion: @escaping () -> Void = {}) {
        audioQueue.append((data, completion))
        
        if !isPlaying {
            playNext(speed: speed)
        }
    }
    
    private func playNext(speed: Double = 1.0) {
        guard !audioQueue.isEmpty else {
            isPlaying = false
            return
        }
        
        let (data, completion) = audioQueue.removeFirst()
        currentCompletion = completion
        currentSpeed = speed
        
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.enableRate = true
            audioPlayer?.rate = Float(speed)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Failed to play audio: \(error)")
            currentCompletion?()
            playNext(speed: speed)
        }
    }
    
    func stopAllAudio() {
        audioQueue.removeAll()
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentCompletion?()
        currentCompletion = nil
    }
}

extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        currentCompletion?()
        playNext(speed: currentSpeed)
    }
}