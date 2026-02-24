//
//  HapticCueService.swift
//  IntervalMagic
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

final class HapticCueService {
    static let shared = HapticCueService()
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
        case .custom(let id):
            playCustom(id: id)
        }
    }

    func play(style: HapticStyle) {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        switch style {
        case .single:
            generator.impactOccurred()
        case .double:
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                generator.impactOccurred()
            }
        case .triple:
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                generator.impactOccurred()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    generator.impactOccurred()
                }
            }
        }
        #endif
    }

    /// Custom haptic playback (pattern from CustomCuesStore). No-op if definition not found.
    func playCustom(id: UUID) {
        #if canImport(UIKit)
        guard let def = CustomCuesStore.shared.customHaptic(by: id) else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        for offset in def.pattern {
            DispatchQueue.main.asyncAfter(deadline: .now() + offset) {
                generator.impactOccurred()
            }
        }
        #endif
    }
}
