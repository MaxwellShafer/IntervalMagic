//
//  SoundCue.swift
//  IntervalMagic
//

import Foundation

enum SoundCue: Equatable, Hashable, Sendable {
    case predefined(SoundStyle)
    case custom(id: UUID, waitUntilFinished: Bool)

    var displayName: String {
        switch self {
        case .predefined(let s): return s.displayName
        case .custom: return "Custom"
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
        case .custom(let id, let waitUntilFinished):
            var customContainer = container.nestedContainer(keyedBy: CustomKeys.self, forKey: .custom)
            try customContainer.encode(id, forKey: .id)
            try customContainer.encode(waitUntilFinished, forKey: .waitUntilFinished)
        }
    }
}

extension SoundCue: Decodable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.predefined) {
            self = .predefined(try container.decode(SoundStyle.self, forKey: .predefined))
        } else if container.contains(.custom) {
            let customContainer = try container.nestedContainer(keyedBy: CustomKeys.self, forKey: .custom)
            let id = try customContainer.decode(UUID.self, forKey: .id)
            let waitUntilFinished = try customContainer.decode(Bool.self, forKey: .waitUntilFinished)
            self = .custom(id: id, waitUntilFinished: waitUntilFinished)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No known SoundCue case key found"))
        }
    }
}

private enum CodingKeys: String, CodingKey {
    case predefined, custom
}

private enum CustomKeys: String, CodingKey {
    case id, waitUntilFinished
}
