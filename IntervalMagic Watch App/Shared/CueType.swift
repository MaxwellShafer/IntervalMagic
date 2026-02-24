//
//  CueType.swift
//  IntervalMagic
//

import Foundation

enum CueType: Codable, Equatable, Sendable {
    case none
    case haptic(HapticCue)
    case sound(SoundCue)
    case both(HapticCue, SoundCue)
}
