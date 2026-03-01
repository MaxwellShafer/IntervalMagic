//
//  SoundStyle.swift
//  IntervalMagic
//

import Foundation

enum SoundStyle: String, Codable, CaseIterable, Equatable, Sendable {
    case beep
    case chime
    case tick
    case pop
    case click
    case alert
    case ding
}
