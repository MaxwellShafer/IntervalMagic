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

    func play(cueType: CueType, onFinished: (() -> Void)? = nil) {
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
            onFinished?()
        case .custom(let id, let waitUntilFinished):
            playCustom(id: id, waitUntilFinished: waitUntilFinished, onFinished: onFinished)
        }
    }

    func play(style: SoundStyle) {
        players[style]?.currentTime = 0
        players[style]?.play()
    }

    /// Custom sound playback from CustomCuesStore. No-op if definition or file not found.
    func playCustom(id: UUID, waitUntilFinished: Bool, onFinished: (() -> Void)? = nil) {
        guard let url = CustomCuesStore.shared.fileURL(forCustomSound: id) else {
            onFinished?()
            return
        }
        guard let player = try? AVAudioPlayer(contentsOf: url) else {
            onFinished?()
            return
        }
        player.prepareToPlay()
        if waitUntilFinished, let onFinished = onFinished {
            let observer = CustomSoundPlaybackObserver(player: player, onFinished: onFinished)
            objc_setAssociatedObject(player, &customSoundObserverKey, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } else {
            onFinished?()
        }
        player.play()
    }
}

// MARK: - Custom sound playback completion

private final class CustomSoundPlaybackObserver: NSObject, AVAudioPlayerDelegate {
    let onFinished: () -> Void
    init(player: AVAudioPlayer, onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
        super.init()
        player.delegate = self
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinished()
    }
}

private var customSoundObserverKey: UInt8 = 0
