//
//  IntervalSetEntity.swift
//  IntervalMagic
//

import Foundation
import SwiftData

@Model
final class IntervalSetEntity {
    var id: UUID
    var name: String
    var fixedCycleCount: Int? // nil = infinite
    @Relationship(deleteRule: .cascade, inverse: \IntervalEntity.intervalSet)
    var intervals: [IntervalEntity] = []

    init(id: UUID = UUID(), name: String, cycleMode: CycleMode, intervals: [IntervalEntity] = []) {
        self.id = id
        self.name = name
        switch cycleMode {
        case .fixed(let n):
            self.fixedCycleCount = n
        case .infinite:
            self.fixedCycleCount = nil
        }
        self.intervals = intervals
    }

    var cycleMode: CycleMode {
        get {
            if let n = fixedCycleCount {
                return .fixed(n)
            }
            return .infinite
        }
        set {
            switch newValue {
            case .fixed(let n):
                fixedCycleCount = n
        case .infinite:
            fixedCycleCount = nil
            }
        }
    }
}

extension IntervalSetEntity {
    func toIntervalSet() -> IntervalSet {
        IntervalSet(
            id: id,
            name: name,
            intervals: intervals.map { $0.toInterval() },
            cycleMode: cycleMode
        )
    }

    static func from(_ set: IntervalSet, modelContext: ModelContext) -> IntervalSetEntity {
        let entities = set.intervals.map { interval in
            let e = IntervalEntity.from(interval)
            modelContext.insert(e)
            return e
        }
        let entity = IntervalSetEntity(id: set.id, name: set.name, cycleMode: set.cycleMode, intervals: entities)
        modelContext.insert(entity)
        for e in entities {
            e.intervalSet = entity
        }
        return entity
    }
}
