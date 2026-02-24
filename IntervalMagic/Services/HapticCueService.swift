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
        let style: HapticStyle?
        switch cueType {
        case .haptic(let h): style = h
        case .both(let h, _): style = h
        case .sound: style = nil
        }
        guard let style else { return }
        play(style: style)
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
}
