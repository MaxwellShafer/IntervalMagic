//
//  CueType.swift
//  IntervalMagic
//

import Foundation

enum CueType: Equatable, Sendable {
    case none
    case haptic(HapticCue)
    case sound(SoundCue)
    case both(HapticCue, SoundCue)
}

// MARK: - Codable (nonisolated for Swift 6 / SwiftData nonisolated access)

extension CueType: Encodable {
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try container.encode([String](), forKey: .none)
        case .haptic(let h):
            try container.encode(h, forKey: .haptic)
        case .sound(let s):
            try container.encode(s, forKey: .sound)
        case .both(let h, let s):
            try container.encode([h, s], forKey: .both)
        }
    }
}

extension CueType: Decodable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.none) {
            _ = try container.decode([String].self, forKey: .none)
            self = .none
        } else if container.contains(.haptic) {
            self = .haptic(try container.decode(HapticCue.self, forKey: .haptic))
        } else if container.contains(.sound) {
            self = .sound(try container.decode(SoundCue.self, forKey: .sound))
        } else if container.contains(.both) {
            var bothContainer = try container.nestedUnkeyedContainer(forKey: .both)
            let h = try bothContainer.decode(HapticCue.self)
            let s = try bothContainer.decode(SoundCue.self)
            self = .both(h, s)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No known CueType case key found"))
        }
    }
}

private enum CodingKeys: String, CodingKey {
    case none, haptic, sound, both
}
