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
        let style: HapticStyle?
        switch cueType {
        case .none, .sound: style = nil
        case .haptic(let h): style = h
        case .both(let h, _): style = h
        }
        guard let style else { return }
        play(style: style)
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
        }
    }
}
