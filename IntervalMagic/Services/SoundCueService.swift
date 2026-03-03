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
            if let player = makePlayer(for: style) {
                players[style] = player
            }
        }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // Use playback so cue sounds are audible even when the iPhone is in silent mode.
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
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
        let player: AVAudioPlayer?
        if let existing = players[style] {
            player = existing
        } else if let loaded = makePlayer(for: style) {
            players[style] = loaded
            player = loaded
        } else {
            player = nil
        }

        if let player {
            player.currentTime = 0
            player.play()
        }
        // No system sound fallback; only bundle WAVs to avoid unintended haptics and ensure Watch parity.
    }

    private func makePlayer(for style: SoundStyle) -> AVAudioPlayer? {
        let url = Bundle.main.url(forResource: style.rawValue, withExtension: "wav", subdirectory: "Sounds")
            ?? Bundle.main.url(forResource: style.rawValue, withExtension: "wav")
        guard let url else { return nil }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.prepareToPlay()
        return player
    }
}
