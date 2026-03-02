//
//  HapticCue.swift
//  IntervalMagic
//

import Foundation

enum HapticCue: Equatable, Hashable, Sendable {
    case predefined(HapticStyle)
    case custom(id: UUID)

    var displayName: String {
        switch self {
        case .predefined(let h): return h.rawValue.capitalized
        case .custom: return "Custom"
        }
    }
}

// MARK: - Codable (nonisolated for Swift 6)

extension HapticCue: Encodable {
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .predefined(let h):
            try container.encode(h, forKey: .predefined)
        case .custom(let id):
            try container.encode(id, forKey: .custom)
        }
    }
}

extension HapticCue: Decodable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.predefined) {
            self = .predefined(try container.decode(HapticStyle.self, forKey: .predefined))
        } else if container.contains(.custom) {
            self = .custom(id: try container.decode(UUID.self, forKey: .custom))
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No known HapticCue case key found"))
        }
    }
}

private enum CodingKeys: String, CodingKey {
    case predefined, custom
}
