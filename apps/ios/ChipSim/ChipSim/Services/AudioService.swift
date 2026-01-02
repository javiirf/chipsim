//
//  AudioService.swift
//  ChipSim
//
//  Created by Cameron Entezarian on 12/22/25.
//

import Foundation
import AVFoundation
import Combine

class AudioService: ObservableObject {
    static let shared = AudioService()
    
    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        }
    }
    
    @Published var musicEnabled: Bool {
        didSet {
            UserDefaults.standard.set(musicEnabled, forKey: "musicEnabled")
            if musicEnabled {
                startBackgroundMusic()
            } else {
                stopBackgroundMusic()
            }
        }
    }
    
    @Published var musicVolume: Float {
        didSet {
            UserDefaults.standard.set(musicVolume, forKey: "musicVolume")
            backgroundMusicPlayer?.volume = musicVolume
        }
    }
    
    private var audioContext: AVAudioEngine?
    private var placeYourBetsPlayer: AVAudioPlayer?
    private var cardDropPlayer: AVAudioPlayer?
    private var backgroundMusicPlayer: AVAudioPlayer?
    
    private init() {
        self.soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled") != false
        self.musicEnabled = UserDefaults.standard.object(forKey: "musicEnabled") as? Bool ?? true
        self.musicVolume = UserDefaults.standard.object(forKey: "musicVolume") as? Float ?? 0.3
        setupAudio()
    }
    
    private func setupAudio() {
        // Setup audio session with mixWithOthers to allow music + sound effects
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        
        // Load audio files if they exist
        if let placeYourBetsURL = Bundle.main.url(forResource: "place-your-bets-please-female-voice-28110", withExtension: "mp3") {
            do {
                placeYourBetsPlayer = try AVAudioPlayer(contentsOf: placeYourBetsURL)
                placeYourBetsPlayer?.prepareToPlay()
            } catch {
                print("Failed to load place your bets audio: \(error)")
            }
        }
        
        if let cardDropURL = Bundle.main.url(forResource: "carddrop2-92718", withExtension: "mp3") {
            do {
                cardDropPlayer = try AVAudioPlayer(contentsOf: cardDropURL)
                cardDropPlayer?.prepareToPlay()
            } catch {
                print("Failed to load card drop audio: \(error)")
            }
        }
        
        // Load background music
        loadBackgroundMusic()
    }
    
    private func loadBackgroundMusic() {
        // Try multiple possible filenames
        let possibleNames = [
            "casino-ambiance-19130",
            "casino-ambiance",
            "casino-music",
            "background-music"
        ]
        
        for name in possibleNames {
            if let musicURL = Bundle.main.url(forResource: name, withExtension: "mp3") {
                do {
                    backgroundMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
                    backgroundMusicPlayer?.numberOfLoops = -1 // Loop indefinitely
                    backgroundMusicPlayer?.volume = musicVolume
                    backgroundMusicPlayer?.prepareToPlay()
                    print("Loaded background music: \(name)")
                    break
                } catch {
                    print("Failed to load background music \(name): \(error)")
                }
            }
        }
        
        if backgroundMusicPlayer == nil {
            print("Background music file not found. Please add casino-ambiance-19130.mp3 to the Xcode project.")
        }
    }
    
    func startBackgroundMusic() {
        guard musicEnabled, let player = backgroundMusicPlayer else { return }
        if !player.isPlaying {
            player.play()
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
    }
    
    func toggleMusic() {
        musicEnabled.toggle()
    }
    
    func toggleSound() {
        soundEnabled.toggle()
    }
    
    func playSound(_ type: SoundType) {
        guard soundEnabled else { return }
        
        switch type {
        case .chip:
            playChipSound()
        case .push:
            playChipSound() // Use chip sound for push
        case .win:
            playWinSound()
        case .lose:
            playLoseSound()
        case .deal:
            playCardDrop()
        case .placeYourBets:
            playPlaceYourBets()
        }
    }
    
    private func playChipSound() {
        // Play a single, clear chip clink sound
        playSingleChipSound()
    }
    
    private func playSingleChipSound() {
        let engine: AVAudioEngine
        if let existingEngine = audioContext {
            engine = existingEngine
        } else {
            engine = AVAudioEngine()
            audioContext = engine
        }
        
        let player = AVAudioPlayerNode()
        engine.attach(player)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let duration = 0.15 // Longer duration for clearer sound
        let frameCount = Int(duration * 44100)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        let samples = buffer.floatChannelData![0]
        // Use a lower, more pleasant frequency that sounds like a chip clink
        let baseFrequency = 400.0
        let sampleRate = 44100.0
        
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            // Create a more natural sound with slight frequency modulation
            let frequency = baseFrequency * (1.0 + 0.1 * sin(2.0 * Double.pi * 50.0 * t))
            // Add envelope: quick attack, exponential decay
            let envelope = exp(-t * 8.0) // Exponential decay
            // Mix in a harmonic for richer sound
            let fundamental = sin(2.0 * Double.pi * frequency * t)
            let harmonic = 0.3 * sin(2.0 * Double.pi * frequency * 2.0 * t)
            samples[i] = Float((fundamental + harmonic) * envelope * 0.12)
        }
        
        engine.connect(player, to: engine.mainMixerNode, format: format)
        
        // Start engine only if not already running
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Failed to start audio engine: \(error)")
                return
            }
        }
        
        player.scheduleBuffer(buffer, at: nil)
        player.play()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            player.stop()
        }
    }
    
    private func playWinSound() {
        // Ascending happy arpeggio
        let notes: [Double] = [523.25, 659.25, 783.99, 1047.0]
        for (index, freq) in notes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                self.playTone(frequency: freq, duration: 0.3, endFrequency: nil)
            }
        }
    }
    
    private func playLoseSound() {
        // Descending sad tone
        playTone(frequency: 400, duration: 0.4, endFrequency: 150)
    }
    
    private func playTone(frequency: Double, duration: Double, endFrequency: Double? = nil) {
        let engine: AVAudioEngine
        if let existingEngine = audioContext {
            engine = existingEngine
        } else {
            engine = AVAudioEngine()
            audioContext = engine
        }
        
        let player = AVAudioPlayerNode()
        engine.attach(player)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let frameCount = Int(duration * 44100)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        let samples = buffer.floatChannelData![0]
        for i in 0..<frameCount {
            let freq = endFrequency != nil ? 
                frequency * pow(endFrequency! / frequency, Double(i) / Double(frameCount)) :
                frequency
            samples[i] = Float(sin(2.0 * Double.pi * freq * Double(i) / 44100.0)) * 0.15
        }
        
        engine.connect(player, to: engine.mainMixerNode, format: format)
        
        // Start engine only if not already running
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Failed to start audio engine: \(error)")
                return
            }
        }
        
        player.scheduleBuffer(buffer, at: nil)
        player.play()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            player.stop()
        }
    }
    
    private func playCardDrop() {
        cardDropPlayer?.currentTime = 0
        cardDropPlayer?.play()
    }
    
    private func playPlaceYourBets() {
        placeYourBetsPlayer?.currentTime = 4.4
        placeYourBetsPlayer?.play()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            self.placeYourBetsPlayer?.pause()
        }
    }
}

enum SoundType {
    case chip
    case push
    case win
    case lose
    case deal
    case placeYourBets
}

