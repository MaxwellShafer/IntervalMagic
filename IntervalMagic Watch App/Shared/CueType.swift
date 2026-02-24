//
//  CueType.swift
//  IntervalMagic
//

import Foundation

enum CueType: Codable, Equatable, Sendable {
    case haptic(HapticStyle)
    case sound(SoundStyle)
    case both(HapticStyle, SoundStyle)
}
