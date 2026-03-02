//
//  SoundStyle.swift
//  IntervalMagic
//

import Foundation

enum SoundStyle: String, Codable, CaseIterable, Equatable, Sendable {
    case ding
    case pop
    case doubleChime2
    case shortChime1
    case shortChime2
    case shortChime3
    case shortChimeDouble1
    case shortTick1
    case softTick1
    case softUI2

    var displayName: String {
        switch self {
        case .ding: return "Ding"
        case .pop: return "Pop"
        case .doubleChime2: return "Double Chime 2"
        case .shortChime1: return "Short Chime 1"
        case .shortChime2: return "Short Chime 2"
        case .shortChime3: return "Short Chime 3"
        case .shortChimeDouble1: return "Short Chime Double 1"
        case .shortTick1: return "Short Tick 1"
        case .softTick1: return "Soft Tick 1"
        case .softUI2: return "Soft UI 2"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        if let style = SoundStyle(rawValue: raw) {
            self = style
        } else {
            self = .softTick1
        }
    }
}
