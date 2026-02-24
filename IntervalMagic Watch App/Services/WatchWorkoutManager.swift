//
//  WatchWorkoutManager.swift
//  IntervalMagic Watch App
//

import Foundation
import HealthKit

final class WatchWorkoutManager {
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKWorkoutBuilder?

    func startWorkout() {
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .unknown

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = session?.associatedWorkoutBuilder()
            session?.startActivity(with: Date())
        } catch {
            // Workout session optional; app still runs without it
        }
    }

    func endWorkout() {
        session?.end()
        session = nil
        builder = nil
    }
}
