//
//  IntervalEntity.swift
//  IntervalMagic
//

import Foundation
import SwiftData

@Model
final class IntervalEntity {
    var id: UUID
    var name: String
    var durationSeconds: Int
    var cueTypeData: Data
    var intervalSet: IntervalSetEntity?

    init(id: UUID = UUID(), name: String, durationSeconds: Int, cueType: CueType) {
        self.id = id
        self.name = name
        self.durationSeconds = durationSeconds
        self.cueTypeData = (try? JSONEncoder().encode(cueType)) ?? Data()
    }

    var cueType: CueType {
        get {
            (try? JSONDecoder().decode(CueType.self, from: cueTypeData)) ?? .haptic(.predefined(.single))
        }
        set {
            cueTypeData = (try? JSONEncoder().encode(newValue)) ?? cueTypeData
        }
    }
}

extension IntervalEntity {
    func toInterval() -> Interval {
        Interval(id: id, name: name, durationSeconds: durationSeconds, cueType: cueType)
    }

    static func from(_ interval: Interval) -> IntervalEntity {
        IntervalEntity(id: interval.id, name: interval.name, durationSeconds: interval.durationSeconds, cueType: interval.cueType)
    }
}
