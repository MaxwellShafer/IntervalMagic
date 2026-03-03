//
//  SoundCueService.swift
//  IntervalMagic
//

import Foundation
import AVFoundation

final class SoundCueService {
    static let shared = SoundCueService()
    private var players: [SoundStyle: AVAudioPlayer] = [:]

    private init() {
        configureAudioSession()
        for style in SoundStyle.allCases {
            if let url = Bundle.main.url(forResource: style.rawValue, withExtension: "wav", subdirectory: "Sounds"),
               let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[style] = player
            }
        }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // Cue sounds are non-critical; continue without audio session config
        }
    }

    /// Ensures the audio session is active before playback (fixes first-play on launch or after background).
    private func ensureSessionActive() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Non-critical; playback may still work
        }
    }

    func play(cueType: CueType) {
        let cue: SoundCue?
        switch cueType {
        case .none, .haptic: cue = nil
        case .sound(let s): cue = s
        case .both(_, let s): cue = s
        }
        guard let cue else { return }
        switch cue {
        case .predefined(let style):
            play(style: style)
        }
    }

    func play(style: SoundStyle) {
        ensureSessionActive()
        if let player = players[style] {
            player.currentTime = 0
            player.play()
        }
        // No system sound fallback; only bundle WAVs to avoid unintended haptics and ensure Watch parity.
    }
}
