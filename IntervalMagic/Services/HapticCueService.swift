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

    /// Custom haptic playback (steps from CustomCuesStore). No-op if definition not found.
    func playCustom(id: UUID) {
        #if canImport(UIKit)
        guard let def = CustomCuesStore.shared.customHaptic(by: id) else { return }
        let steps = def.steps.isEmpty ? Self.stepsFromLegacyPattern(def.pattern) : def.steps
        guard !steps.isEmpty else { return }
        playSteps(steps, index: 0, delayAccumulator: 0)
        #endif
    }

    #if canImport(UIKit)
    private func playSteps(_ steps: [CustomHapticStep], index: Int, delayAccumulator: TimeInterval) {
        guard index < steps.count else { return }
        let step = steps[index]
        switch step {
        case .delay(let seconds):
            let nextDelay = delayAccumulator + seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + nextDelay) { [weak self] in
                self?.playSteps(steps, index: index + 1, delayAccumulator: 0)
            }
        case .haptic(let style, let intensity):
            let styleUIKit = uiImpactStyle(style)
            let generator = UIImpactFeedbackGenerator(style: styleUIKit)
            generator.prepare()
            DispatchQueue.main.asyncAfter(deadline: .now() + delayAccumulator) {
                generator.impactOccurred(intensity: CGFloat(max(0, min(1, intensity))))
                DispatchQueue.main.async {
                    self.playSteps(steps, index: index + 1, delayAccumulator: 0)
                }
            }
        }
    }

    private func uiImpactStyle(_ style: ImpactHapticStyle) -> UIImpactFeedbackGenerator.FeedbackStyle {
        switch style {
        case .light: return .light
        case .medium: return .medium
        case .heavy: return .heavy
        case .soft: return .soft
        case .rigid: return .rigid
        }
    }

    private static func stepsFromLegacyPattern(_ pattern: [Double]) -> [CustomHapticStep] {
        CustomCuesStore.steps(fromLegacyPattern: pattern)
    }
    #endif
}
