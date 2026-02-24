//
//  SyncPayload.swift
//  IntervalMagic
//

import Foundation

struct SyncPayload: Codable {
    var intervalSets: [IntervalSet]
    var command: SyncCommand?
}

enum SyncCommand: Codable {
    case startSet(intervalSetId: UUID)
}
