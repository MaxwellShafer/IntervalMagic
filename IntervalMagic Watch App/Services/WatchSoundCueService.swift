//
//  WatchSoundCueService.swift
//  IntervalMagic Watch App
//

import Foundation
import AVFoundation

enum WatchSoundCueService {
    static let shared = WatchSoundCueService()
    private var players: [SoundStyle: AVAudioPlayer] = [:]

    init() {
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
        case .sound(let s): style = s
        case .both(_, let s): style = s
        case .haptic: style = nil
        }
        guard let style else { return }
        play(style: style)
    }

    func play(style: SoundStyle) {
        players[style]?.currentTime = 0
        players[style]?.play()
    }
}
