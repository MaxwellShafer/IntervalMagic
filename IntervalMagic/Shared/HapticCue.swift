//
//  HapticCue.swift
//  IntervalMagic
//

import Foundation

enum HapticCue: Codable, Equatable, Sendable {
    case predefined(HapticStyle)
    case custom(id: UUID)

    var displayName: String {
        switch self {
        case .predefined(let h): return h.rawValue.capitalized
        case .custom: return "Custom"
        }
    }
}
