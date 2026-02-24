//
//  Interval.swift
//  IntervalMagic
//

import Foundation

struct Interval: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var durationSeconds: Int
    var cueType: CueType

    init(id: UUID = UUID(), name: String, durationSeconds: Int, cueType: CueType) {
        self.id = id
        self.name = name
        self.durationSeconds = durationSeconds
        self.cueType = cueType
    }
}
