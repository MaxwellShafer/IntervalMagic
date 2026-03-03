//
//  CustomCuesStore.swift
//  IntervalMagic
//

import Foundation

private let customHapticsKey = "customHaptics"

@Observable
final class CustomCuesStore {
    static let shared = CustomCuesStore()

    private let defaults = UserDefaults.standard

    /// Stored so @Observable can track changes and list view updates when saving.
    private var _customHaptics: [CustomHapticDefinition] = []

    var customHaptics: [CustomHapticDefinition] {
        get { _customHaptics }
        set {
            _customHaptics = newValue
            saveHaptics(newValue)
        }
    }

    private init() {
        _customHaptics = loadHaptics()
    }

    // MARK: - Custom haptics

    func customHaptic(by id: UUID) -> CustomHapticDefinition? {
        customHaptics.first { $0.id == id }
    }

    func add(_ def: CustomHapticDefinition) {
        var list = customHaptics
        if list.contains(where: { $0.id == def.id }) { return }
        list.append(def)
        customHaptics = list
    }

    /// Add or replace a custom haptic (e.g. when saving from the editor).
    func addOrUpdate(_ def: CustomHapticDefinition) {
        var list = customHaptics
        list.removeAll { $0.id == def.id }
        list.append(def)
        customHaptics = list
    }

    func deleteCustomHaptic(id: UUID) {
        customHaptics = customHaptics.filter { $0.id != id }
    }

    func clearAllCustomHaptics() {
        customHaptics = []
    }

    // MARK: - Persistence

    private func loadHaptics() -> [CustomHapticDefinition] {
        guard let data = defaults.data(forKey: customHapticsKey),
              var list = try? JSONDecoder().decode([CustomHapticDefinition].self, from: data) else {
            return []
        }
        // Migrate legacy pattern-only definitions to steps
        var didMigrate = false
        for i in list.indices where list[i].steps.isEmpty && !list[i].pattern.isEmpty {
            list[i].steps = Self.steps(fromLegacyPattern: list[i].pattern)
            didMigrate = true
        }
        if didMigrate {
            _customHaptics = list
            saveHaptics(list)
        }
        return list
    }

    /// Converts legacy pattern (time offsets) to steps: haptic at 0, then delay + haptic for each subsequent offset.
    static func steps(fromLegacyPattern pattern: [Double]) -> [CustomHapticStep] {
        guard !pattern.isEmpty else { return [] }
        var result: [CustomHapticStep] = []
        let sortedOffsets = pattern.sorted()
        var lastTime: Double = 0
        for offset in sortedOffsets {
            let delay = offset - lastTime
            if delay > 0.01 {
                result.append(.delay(seconds: delay))
            }
            result.append(.haptic(style: .medium, intensity: 1.0))
            lastTime = offset
        }
        return result
    }

    private func saveHaptics(_ list: [CustomHapticDefinition]) {
        guard let data = try? JSONEncoder().encode(list) else { return }
        defaults.set(data, forKey: customHapticsKey)
    }

}
