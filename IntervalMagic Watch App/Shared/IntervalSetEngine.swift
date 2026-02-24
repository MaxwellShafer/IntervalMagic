//
//  IntervalSetEngine.swift
//  IntervalMagic
//

import Foundation
import Combine

final class IntervalSetEngine: ObservableObject {
    @Published private(set) var currentIntervalIndex: Int = 0
    @Published private(set) var currentCycle: Int = 1
    @Published private(set) var timeRemaining: Int = 0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var isCompleted: Bool = false

    var onCue: (CueType) -> Void = { _ in }

    private let set: IntervalSet
    private var timer: Timer?
    private var totalSecondsRemainingInCurrentInterval: Int = 0
    private var cancellables = Set<AnyCancellable>()

    var currentInterval: Interval? {
        guard currentIntervalIndex >= 0, currentIntervalIndex < set.intervals.count else { return nil }
        return set.intervals[currentIntervalIndex]
    }

    var totalCycles: Int? {
        if case .fixed(let n) = set.cycleMode { return n }
        return nil
    }

    var nextCueStyle: String? {
        guard let interval = currentInterval else { return nil }
        switch interval.cueType {
        case .none: return "None"
        case .haptic(let h): return "Haptic \(h.rawValue)"
        case .sound(let s): return "Sound \(s.rawValue)"
        case .both(let h, let s): return "\(h.rawValue) + \(s.rawValue)"
        }
    }

    init(set: IntervalSet) {
        self.set = set
        guard let first = set.intervals.first else { return }
        timeRemaining = first.durationSeconds
        totalSecondsRemainingInCurrentInterval = first.durationSeconds
    }

    func start() {
        guard !set.intervals.isEmpty else { return }
        isCompleted = false
        isPaused = false
        isRunning = true
        currentIntervalIndex = 0
        currentCycle = 1
        let first = set.intervals[0]
        timeRemaining = first.durationSeconds
        totalSecondsRemainingInCurrentInterval = first.durationSeconds
        scheduleTick()
    }

    func pause() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        guard isRunning, !isCompleted else { return }
        isPaused = false
        scheduleTick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        isCompleted = true
    }

    func restore(intervalIndex: Int, cycle: Int, timeRemaining: Int, isPaused: Bool) {
        currentIntervalIndex = min(intervalIndex, set.intervals.count - 1)
        currentCycle = max(1, cycle)
        self.timeRemaining = timeRemaining
        totalSecondsRemainingInCurrentInterval = timeRemaining
        isRunning = true
        self.isPaused = isPaused
        isCompleted = false
    }

    var stateSnapshot: (intervalIndex: Int, cycle: Int, timeRemaining: Int, isPaused: Bool) {
        (currentIntervalIndex, currentCycle, timeRemaining, isPaused)
    }

    private func scheduleTick() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func tick() {
        guard isRunning, !isPaused, !isCompleted else { return }
        totalSecondsRemainingInCurrentInterval -= 1
        timeRemaining = totalSecondsRemainingInCurrentInterval

        if totalSecondsRemainingInCurrentInterval <= 0 {
            if let interval = currentInterval {
                onCue(interval.cueType)
            }
            advanceToNext()
        }
    }

    private func advanceToNext() {
        if currentIntervalIndex + 1 < set.intervals.count {
            currentIntervalIndex += 1
            let next = set.intervals[currentIntervalIndex]
            timeRemaining = next.durationSeconds
            totalSecondsRemainingInCurrentInterval = next.durationSeconds
        } else {
            switch set.cycleMode {
            case .fixed(let n):
                if currentCycle >= n {
                    stop()
                    return
                }
                currentCycle += 1
                currentIntervalIndex = 0
                let next = set.intervals[0]
                timeRemaining = next.durationSeconds
                totalSecondsRemainingInCurrentInterval = next.durationSeconds
            case .infinite:
                currentCycle += 1
                currentIntervalIndex = 0
                let next = set.intervals[0]
                timeRemaining = next.durationSeconds
                totalSecondsRemainingInCurrentInterval = next.durationSeconds
            }
        }
    }
}
