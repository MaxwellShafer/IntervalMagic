//
//  WatchHapticCueService.swift
//  IntervalMagic Watch App
//

import Foundation
import WatchKit

final class WatchHapticCueService {
    static let shared = WatchHapticCueService()
    private init() {}

    func play(cueType: CueType) {
        let cue: HapticCue?
        switch cueType {
        case .none, .sound: cue = nil
        case .haptic(let h): cue = h
        case .both(let h, _): cue = h
        }
        guard let cue else { return }
        switch cue {
        case .predefined(let style):
            play(style: style)
        case .custom:
            // Custom haptics not synced to Watch; no-op
            break
        }
    }

    func play(style: HapticStyle) {
        let device = WKInterfaceDevice.current()
        switch style {
        case .single:
            device.play(.notification)
        case .double:
            device.play(.notification)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                device.play(.notification)
            }
        case .triple:
            device.play(.notification)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                device.play(.notification)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    device.play(.notification)
                }
            }
        case .buzz:
            device.play(.notification)
        }
    }
}
