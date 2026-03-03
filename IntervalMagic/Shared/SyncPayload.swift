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
    case settingsUpdate(AppSettings)
}

struct AppSettings: Codable, Equatable {
    let useLightMode: Bool
}
