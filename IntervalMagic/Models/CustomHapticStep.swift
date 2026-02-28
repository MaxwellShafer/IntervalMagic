//
//  CustomHapticStep.swift
//  IntervalMagic
//

import Foundation

/// Style for impact haptic. Mirrors UIImpactFeedbackGenerator.FeedbackStyle for Codable storage.
enum ImpactHapticStyle: String, Codable, CaseIterable, Equatable, Sendable {
    case light
    case medium
    case heavy
    case soft
    case rigid

    var displayName: String {
        rawValue.capitalized
    }
}

enum CustomHapticStep: Codable, Equatable, Identifiable, Sendable {
    case haptic(style: ImpactHapticStyle, intensity: Double)
    case delay(seconds: Double)

    var id: String {
        switch self {
        case .haptic(let style, let intensity):
            return "haptic-\(style.rawValue)-\(intensity)"
        case .delay(let seconds):
            return "delay-\(seconds)"
        }
    }

    // Codable: use enum key to discriminate
    private enum CodingKeys: String, CodingKey {
        case type
        case style
        case intensity
        case seconds
    }

    enum StepType: String, Codable {
        case haptic
        case delay
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(StepType.self, forKey: .type)
        switch type {
        case .haptic:
            let style = try c.decode(ImpactHapticStyle.self, forKey: .style)
            let intensity = try c.decode(Double.self, forKey: .intensity)
            self = .haptic(style: style, intensity: intensity)
        case .delay:
            let seconds = try c.decode(Double.self, forKey: .seconds)
            self = .delay(seconds: seconds)
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .haptic(let style, let intensity):
            try c.encode(StepType.haptic, forKey: .type)
            try c.encode(style, forKey: .style)
            try c.encode(intensity, forKey: .intensity)
        case .delay(let seconds):
            try c.encode(StepType.delay, forKey: .type)
            try c.encode(seconds, forKey: .seconds)
        }
    }
}
