//
//  CueType.swift
//  IntervalMagic
//

import Foundation

enum CueType: Codable, Equatable {
    case haptic(HapticStyle)
    case sound(SoundStyle)
    case both(HapticStyle, SoundStyle)
}
