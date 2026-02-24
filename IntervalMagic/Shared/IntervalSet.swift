//
//  IntervalSet.swift
//  IntervalMagic
//

import Foundation

struct IntervalSet: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var intervals: [Interval]
    var cycleMode: CycleMode
    var totalDurationSeconds: Int {
        let oneCycle = intervals.reduce(0) { $0 + $1.durationSeconds }
        switch cycleMode {
        case .fixed(let n):
            return oneCycle * n
        case .infinite:
            return oneCycle
        }
    }

    init(id: UUID = UUID(), name: String, intervals: [Interval], cycleMode: CycleMode) {
        self.id = id
        self.name = name
        self.intervals = intervals
        self.cycleMode = cycleMode
    }

    /// Total duration for one cycle (all intervals once).
    var singleCycleDurationSeconds: Int {
        intervals.reduce(0) { $0 + $1.durationSeconds }
    }
}

// MARK: - Validation

extension IntervalSet {
    var isValid: Bool {
        !intervals.isEmpty && intervals.allSatisfy { $0.durationSeconds > 0 }
    }
}

extension Interval {
    var isValid: Bool {
        durationSeconds > 0 && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
