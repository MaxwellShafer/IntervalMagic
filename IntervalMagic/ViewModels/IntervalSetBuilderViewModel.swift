//
//  IntervalSetBuilderViewModel.swift
//  IntervalMagic
//

import Foundation
import SwiftData

@Observable
final class IntervalSetBuilderViewModel {
    var setId: UUID?
    var setName: String
    var intervals: [Interval]
    var cycleMode: CycleMode
    var validationError: String?

    init(setId: UUID? = nil, setName: String = "", intervals: [Interval] = [], cycleMode: CycleMode = .infinite) {
        self.setId = setId
        self.setName = setName
        self.intervals = intervals
        self.cycleMode = cycleMode
    }

    var set: IntervalSet {
        IntervalSet(id: setId ?? UUID(), name: setName, intervals: intervals, cycleMode: cycleMode)
    }

    var totalDurationSeconds: Int {
        return set.totalDurationSeconds
    }

    var isValid: Bool {
        let nameOk = !setName.trimmingCharacters(in: .whitespaces).isEmpty
        let setValid = IntervalSet(id: UUID(), name: setName, intervals: intervals, cycleMode: cycleMode).isValid
        return nameOk && setValid
    }

    func addInterval(_ interval: Interval) {
        intervals.append(interval)
    }

    func updateInterval(at index: Int, with interval: Interval) {
        guard index >= 0, index < intervals.count else { return }
        intervals[index] = interval
    }

    func duplicateInterval(at index: Int) {
        guard index >= 0, index < intervals.count else { return }
        var copy = intervals[index]
        copy = Interval(id: UUID(), name: copy.name, durationSeconds: copy.durationSeconds, cueType: copy.cueType)
        intervals.insert(copy, at: index + 1)
    }

    func deleteInterval(at index: Int) {
        guard index >= 0, index < intervals.count else { return }
        intervals.remove(at: index)
    }

    func validate() -> Bool {
        if setName.trimmingCharacters(in: .whitespaces).isEmpty {
            validationError = "Set name is required"
            return false
        }
        if intervals.isEmpty {
            validationError = "Add at least one interval"
            return false
        }
        if intervals.contains(where: { $0.durationSeconds <= 0 }) {
            validationError = "Each interval must have duration > 0"
            return false
        }
        validationError = nil
        return true
    }
}
