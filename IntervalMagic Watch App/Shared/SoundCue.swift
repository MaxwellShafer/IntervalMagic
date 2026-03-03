//
//  SoundCue.swift
//  IntervalMagic
//

import Foundation

enum SoundCue: Equatable, Hashable, Sendable {
    case predefined(SoundStyle)

    var displayName: String {
        switch self {
        case .predefined(let s): return s.displayName
        }
    }
}

// MARK: - Codable (nonisolated for Swift 6)

extension SoundCue: Encodable {
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .predefined(let s):
            try container.encode(s, forKey: .predefined)
        }
    }
}

extension SoundCue: Decodable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.predefined) {
            self = .predefined(try container.decode(SoundStyle.self, forKey: .predefined))
        } else if container.contains(.custom) {
            // Backward compatibility for previously persisted custom sounds.
            self = .predefined(.softTick1)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No known SoundCue case key found"))
        }
    }
}

private enum CodingKeys: String, CodingKey {
    case predefined, custom
}
