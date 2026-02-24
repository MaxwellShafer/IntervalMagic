//
//  SoundCue.swift
//  IntervalMagic
//

import Foundation

enum SoundCue: Codable, Equatable, Hashable, Sendable {
    case predefined(SoundStyle)
    case custom(id: UUID, waitUntilFinished: Bool)

    var displayName: String {
        switch self {
        case .predefined(let s): return s.rawValue.capitalized
        case .custom: return "Custom"
        }
    }
}
