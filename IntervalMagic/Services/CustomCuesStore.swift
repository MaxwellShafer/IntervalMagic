//
//  CustomCuesStore.swift
//  IntervalMagic
//

import Foundation

private let customHapticsKey = "customHaptics"
private let customSoundsKey = "customSounds"
private let customSoundsDirectoryName = "CustomSounds"

@Observable
final class CustomCuesStore {
    static let shared = CustomCuesStore()

    private let defaults = UserDefaults.standard
    private let fileManager = FileManager.default

    var customHaptics: [CustomHapticDefinition] {
        get { loadHaptics() }
        set { saveHaptics(newValue) }
    }

    var customSounds: [CustomSoundDefinition] {
        get { loadSounds() }
        set { saveSounds(newValue) }
    }

    private init() {}

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

    func deleteCustomHaptic(id: UUID) {
        customHaptics = customHaptics.filter { $0.id != id }
    }

    // MARK: - Custom sounds

    func customSound(by id: UUID) -> CustomSoundDefinition? {
        customSounds.first { $0.id == id }
    }

    /// File URL for a custom sound's audio file. Returns nil if definition or file missing.
    func fileURL(forCustomSound id: UUID) -> URL? {
        guard let def = customSound(by: id) else { return nil }
        let url = customSoundsDirectory().appendingPathComponent(def.fileName)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    /// Directory where custom sound files are stored. Caller can write files here.
    func customSoundsDirectory() -> URL {
        let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(customSoundsDirectoryName)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func add(_ def: CustomSoundDefinition, fileURL sourceURL: URL) throws {
        let dir = customSoundsDirectory()
        let destURL = dir.appendingPathComponent(def.fileName)
        if fileManager.fileExists(atPath: destURL.path) { try fileManager.removeItem(at: destURL) }
        try fileManager.copyItem(at: sourceURL, to: destURL)
        var list = customSounds
        list.removeAll { $0.id == def.id }
        list.append(def)
        customSounds = list
    }

    func deleteCustomSound(id: UUID) {
        if let def = customSound(by: id) {
            let url = customSoundsDirectory().appendingPathComponent(def.fileName)
            try? fileManager.removeItem(at: url)
        }
        customSounds = customSounds.filter { $0.id != id }
    }

    func clearAllCustomHaptics() {
        customHaptics = []
    }

    func clearAllCustomSounds() {
        let dir = customSoundsDirectory()
        try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil).forEach { try? fileManager.removeItem(at: $0) }
        customSounds = []
    }

    // MARK: - Persistence

    private func loadHaptics() -> [CustomHapticDefinition] {
        guard let data = defaults.data(forKey: customHapticsKey),
              let list = try? JSONDecoder().decode([CustomHapticDefinition].self, from: data) else {
            return []
        }
        return list
    }

    private func saveHaptics(_ list: [CustomHapticDefinition]) {
        guard let data = try? JSONEncoder().encode(list) else { return }
        defaults.set(data, forKey: customHapticsKey)
    }

    private func loadSounds() -> [CustomSoundDefinition] {
        guard let data = defaults.data(forKey: customSoundsKey),
              let list = try? JSONDecoder().decode([CustomSoundDefinition].self, from: data) else {
            return []
        }
        return list
    }

    private func saveSounds(_ list: [CustomSoundDefinition]) {
        guard let data = try? JSONEncoder().encode(list) else { return }
        defaults.set(data, forKey: customSoundsKey)
    }
}
