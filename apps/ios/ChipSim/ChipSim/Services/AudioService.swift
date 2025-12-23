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
    
    private var audioContext: AVAudioEngine?
    private var placeYourBetsPlayer: AVAudioPlayer?
    private var cardDropPlayer: AVAudioPlayer?
    
    private init() {
        self.soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled") != false
        setupAudio()
    }
    
    private func setupAudio() {
        // Setup audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
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
        // Create multiple short chip sounds
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.03) {
                self.playSingleChipSound()
            }
        }
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
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 2205)!
        buffer.frameLength = 2205
        
        let samples = buffer.floatChannelData![0]
        let frequency = 800.0 + Double.random(in: 0...400)
        for i in 0..<Int(buffer.frameLength) {
            samples[i] = Float(sin(2.0 * Double.pi * frequency * Double(i) / 44100.0)) * 0.08
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
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

