//
//  SessionPersistence.swift
//  IntervalMagic
//

import Foundation

struct SessionState: Codable {
    var setId: UUID
    var intervalIndex: Int
    var cycle: Int
    var timeRemaining: Int
    var isPaused: Bool
}

enum SessionPersistence {
    private static let key = "intervalMagic.sessionState"

    static func save(_ state: SessionState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> SessionState? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let state = try? JSONDecoder().decode(SessionState.self, from: data) else { return nil }
        return state
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
