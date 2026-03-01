//
//  WatchSoundCueService.swift
//  IntervalMagic Watch App
//

import Foundation
import AVFoundation
import AudioToolbox

final class WatchSoundCueService {
    static let shared = WatchSoundCueService()
    private var players: [SoundStyle: AVAudioPlayer] = [:]

    private init() {
        for style in SoundStyle.allCases {
            if let url = Bundle.main.url(forResource: style.rawValue, withExtension: "wav", subdirectory: "Sounds"),
               let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[style] = player
            }
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
        case .custom:
            // Custom sounds not synced to Watch; no-op
            break
        }
    }

    func play(style: SoundStyle) {
        if let player = players[style] {
            player.currentTime = 0
            player.play()
        } else {
            playSystemSoundFallback(style: style)
        }
    }

    private func playSystemSoundFallback(style: SoundStyle) {
        let id: SystemSoundID
        switch style {
        case .beep, .chime, .tick: return
        case .pop, .click: id = 1057
        case .alert: id = 1005
        case .ding: id = 1016
        }
        AudioServicesPlaySystemSound(id)
    }
}
