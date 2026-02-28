//
//  CustomHapticDefinition.swift
//  IntervalMagic
//

import Foundation

struct CustomHapticDefinition: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String?
    /// Time offsets in seconds from start for each tap. Used when steps is empty (legacy).
    var pattern: [Double]
    /// Ordered sequence of haptic and delay steps. When non-empty, playback uses this instead of pattern.
    var steps: [CustomHapticStep]

    init(id: UUID = UUID(), name: String? = nil, pattern: [Double] = [], steps: [CustomHapticStep] = []) {
        self.id = id
        self.name = name
        self.pattern = pattern
        self.steps = steps
    }

    /// Display name for picker; defaults to "Custom Haptic" when name is nil or empty.
    var displayName: String {
        let n = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (n != nil && n != "") ? n! : "Custom Haptic"
    }

    // MARK: - Codable (backward compatibility: steps may be missing in stored data)

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case pattern
        case steps
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        pattern = try c.decodeIfPresent([Double].self, forKey: .pattern) ?? []
        steps = try c.decodeIfPresent([CustomHapticStep].self, forKey: .steps) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(pattern, forKey: .pattern)
        try c.encode(steps, forKey: .steps)
    }
}
