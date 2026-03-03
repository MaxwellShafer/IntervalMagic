//
//  SyncPayload.swift
//  IntervalMagic
//

import Foundation

struct SyncPayload: Codable {
    var intervalSets: [IntervalSet]
    var command: SyncCommand?
    var appSettings: AppSettings?
}

enum SyncCommand: Codable {
    case startSet(intervalSetId: UUID)
}

enum PhoneToWatchMessage: Codable {
    case syncSets(SyncPayload)
    case sessionControl(SessionControl)
    case muteUpdate(MuteUpdate)
    case settingsUpdate(AppSettings)
    case requestSessionState
}

enum WatchToPhoneMessage: Codable {
    case sessionStarted(SessionSnapshot)
    case sessionUpdate(SessionSnapshot)
    case sessionStopped
    case sessionCompleted
    case noActiveSession
}

struct SessionSnapshot: Codable, Equatable {
    let setId: UUID
    let intervalIndex: Int
    let cycle: Int
    let timeRemaining: Int
    let isPaused: Bool
    let isCompleted: Bool
}

struct SessionControl: Codable, Equatable {
    enum Action: Codable {
        case pause
        case resume
        case stop
    }

    let action: Action
}

struct MuteUpdate: Codable, Equatable {
    let soundsMuted: Bool
    let hapticsMuted: Bool
}

struct AppSettings: Codable, Equatable {
    let useLightMode: Bool
}
