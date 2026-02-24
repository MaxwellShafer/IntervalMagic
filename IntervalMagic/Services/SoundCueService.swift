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
        for style in SoundStyle.allCases {
            if let url = Bundle.main.url(forResource: style.rawValue, withExtension: "wav", subdirectory: "Sounds"),
               let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[style] = player
            }
        }
    }

    func play(cueType: CueType) {
        let style: SoundStyle?
        switch cueType {
        case .none, .haptic: style = nil
        case .sound(let s): style = s
        case .both(_, let s): style = s
        }
        guard let style else { return }
        play(style: style)
    }

    func play(style: SoundStyle) {
        players[style]?.currentTime = 0
        players[style]?.play()
    }
}
