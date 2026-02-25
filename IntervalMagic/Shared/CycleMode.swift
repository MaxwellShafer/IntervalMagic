//
//  CycleMode.swift
//  IntervalMagic
//

import Foundation

enum CycleMode: Codable, Equatable {
    case fixed(Int)
    case infinite
}

// MARK: - Cycle count mapping (blank/0 = loop)

extension CycleMode {
    /// Numeric cycle count representation for UI. `nil` means "loop".
    var cycleCountValue: Int? {
        switch self {
        case .fixed(let n):
            return max(1, n)
        case .infinite:
            return nil
        }
    }

    /// Converts a numeric UI value into a `CycleMode`. `nil` or `<= 0` becomes `.infinite`.
    static func fromCycleCountValue(_ value: Int?) -> CycleMode {
        guard let value, value > 0 else { return .infinite }
        return .fixed(value)
    }
}
